import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Agenda hebdomadaire : pour chaque jour, travaillé ou non, avec une heure de début et de fin.
///
/// L'écran gère une plage par jour, ce qui couvre le cas courant. L'API en accepte plusieurs :
/// un jour qui en a déjà plusieurs garde ici la première à la dernière heure.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  /// Ordre d'affichage : la semaine commence le lundi. 0 = dimanche … 6 = samedi.
  static const List<int> _weekdays = <int>[1, 2, 3, 4, 5, 6, 0];
  static const String _defaultStart = '08:00';
  static const String _defaultEnd = '18:00';

  final Map<int, ({String start, String end})> _days = <int, ({String start, String end})>{};
  bool _busy = false;
  String? _error;

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
  }

  /// Nom du jour dans la langue de l'écran. Le 1er janvier 2023 est un dimanche.
  String _dayName(int weekday, String languageCode) {
    final name = DateFormat.EEEE(languageCode).format(DateTime(2023, 1, 1 + weekday));
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
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
      await ref.read(professionalFileProvider.notifier).setAvailabilities(<AvailabilitySlot>[
        for (final weekday in _weekdays)
          if (_days[weekday] case final day?)
            AvailabilitySlot(weekday: weekday, startTime: day.start, endTime: day.end),
      ]);
      if (mounted) {
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

    return NcPage(
      appBar: AppBar(),
      title: l10n.proScheduleTitle,
      subtitle: l10n.proScheduleHelp,
      actions: <Widget>[NcPrimaryButton(label: l10n.save, isLoading: _busy, onPressed: _save)],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        for (final weekday in _weekdays) ...<Widget>[
          SwitchListTile(
            key: ValueKey<String>('day-$weekday'),
            contentPadding: EdgeInsets.zero,
            value: _days.containsKey(weekday),
            title: Text(_dayName(weekday, language), style: textTheme.titleMedium),
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
              padding: const EdgeInsets.only(bottom: NcSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      key: ValueKey<String>('start-$weekday'),
                      onPressed: () => _pickTime(weekday, isStart: true),
                      child: Text('${l10n.scheduleStart}  ${day.start}'),
                    ),
                  ),
                  const SizedBox(width: NcSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      key: ValueKey<String>('end-$weekday'),
                      onPressed: () => _pickTime(weekday, isStart: false),
                      child: Text('${l10n.scheduleEnd}  ${day.end}'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
