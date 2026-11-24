import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Proposition d'une semaine type : pour chaque jour, travaillé ou non, avec une heure de début
/// et de fin. Le planning est tenu par l'agence : la semaine ne s'applique que si la coordination
/// l'accepte.
///
/// L'écran gère une plage par jour, ce qui couvre le cas courant. L'API en accepte plusieurs :
/// un jour qui en a déjà plusieurs garde ici la première à la dernière heure.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  static const List<int> _weekdays = orderedWeekdays;
  static const String _defaultStart = '08:00';
  static const String _defaultEnd = '18:00';

  final Map<int, ({String start, String end})> _days = <int, ({String start, String end})>{};
  bool _busy = false;
  String? _error;

  /// Agenda enregistré, sous une forme comparable, pour savoir si l'écran a été modifié.
  String _savedSignature = '';

  String get _signature => <String>[
        for (final weekday in _weekdays)
          if (_days[weekday] case final day?) '$weekday:${day.start}-${day.end}',
      ].join('|');

  @override
  void initState() {
    super.initState();
    final slots = ref.read(professionalFileProvider).value?.availabilities ?? const <AvailabilitySlot>[];
    for (final slot in slots) {
      final current = _days[slot.weekday];
      _days[slot.weekday] = (
        start: current == null || slot.startTime.compareTo(current.start) < 0 ? slot.startTime : current.start,
        end: current == null || slot.endTime.compareTo(current.end) > 0 ? slot.endTime : current.end,
      );
    }
    _savedSignature = _signature;
  }

  Future<void> _pickTime(int weekday, {required bool isStart}) async {
    final day = _days[weekday]!;
    final current = (isStart ? day.start : day.end).split(':');

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(current[0]), minute: int.parse(current[1])),
      builder: (context, child) => MediaQuery(
        // Format 24 heures, comme les créneaux affichés aux patients.
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _days[weekday] = isStart ? (start: value, end: day.end) : (start: day.start, end: value);
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_days.values.any((day) => day.start.compareTo(day.end) >= 0)) {
      setState(() => _error = context.l10n.scheduleInvalid);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(proApiProvider).proposeWeek(<AvailabilitySlot>[
        for (final weekday in _weekdays)
          if (_days[weekday] case final day?)
            AvailabilitySlot(weekday: weekday, startTime: day.start, endTime: day.end),
      ]);
      ref.invalidate(scheduleRequestsProvider);
      if (mounted) {
        // Plus rien à perdre : le retour ne doit pas demander de confirmation.
        setState(() => _savedSignature = _signature);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.planningSent)));
        context.pop();
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final textTheme = Theme.of(context).textTheme;

    return UnsavedChangesGuard(
      dirty: _signature != _savedSignature && !_busy,
      child: NcPage(
      appBar: AppBar(),
      title: l10n.planningProposeTitle,
      subtitle: l10n.planningProposeHelp,
      actions: <Widget>[
        // Sans changement, il n'y a rien à proposer.
        NcPrimaryButton(
          key: const ValueKey<String>('send-week'),
          label: l10n.planningSend,
          isLoading: _busy,
          onPressed: _signature == _savedSignature ? null : _save,
        ),
      ],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        for (final weekday in _weekdays)
          // Jour travaillé : carte blanche ; jour de repos : carte grise, à plat.
          NcSurface(
            color: _days.containsKey(weekday) ? null : Theme.of(context).colorScheme.surfaceContainer,
            padding: const EdgeInsetsDirectional.fromSTEB(NcSpacing.md, NcSpacing.xs, NcSpacing.sm, NcSpacing.xs),
            child: Column(
              children: <Widget>[
          SwitchListTile(
            key: ValueKey<String>('day-$weekday'),
            contentPadding: EdgeInsets.zero,
            secondary: NcIconBubble(
              icon: _days.containsKey(weekday) ? Icons.work_outline : Icons.weekend_outlined,
              size: 40,
              background: _days.containsKey(weekday) ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerLowest,
              foreground: _days.containsKey(weekday) ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            value: _days.containsKey(weekday),
            title: Text(weekdayName(weekday, language), style: textTheme.titleMedium),
            subtitle: _days[weekday] == null
                ? null
                : Text(l10n.scheduleRange(_days[weekday]!.start, _days[weekday]!.end)),
            onChanged: (enabled) => setState(() {
              if (enabled) {
                _days[weekday] = (start: _defaultStart, end: _defaultEnd);
              } else {
                _days.remove(weekday);
              }
              _error = null;
            }),
          ),
          if (_days[weekday] case final day?)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: NcSpacing.sm, bottom: NcSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonal(
                      key: ValueKey<String>('start-$weekday'),
                      // Teal clair : le teal plein du thème est réservé à l'action principale.
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () => _pickTime(weekday, isStart: true),
                      child: _TimeLabel(label: l10n.scheduleStart, time: day.start),
                    ),
                  ),
                  const SizedBox(width: NcSpacing.sm),
                  Expanded(
                    child: FilledButton.tonal(
                      key: ValueKey<String>('end-$weekday'),
                      // Teal clair : le teal plein du thème est réservé à l'action principale.
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      onPressed: () => _pickTime(weekday, isStart: false),
                      child: _TimeLabel(label: l10n.scheduleEnd, time: day.end),
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
      ],
      ),
    );
  }
}

/// Contenu d'un bouton d'heure : le libellé, puis l'heure en plus grand.
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.label, required this.time});

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NcSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 14)),
          // Une heure se lit de gauche à droite, même en arabe.
          Text(time, textDirection: TextDirection.ltr, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}
