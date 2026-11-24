import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Signalement d'une indisponibilité (congé, empêchement) : des journées entières, à faire
/// accepter par la coordination.
class UnavailabilityScreen extends ConsumerStatefulWidget {
  const UnavailabilityScreen({super.key});

  @override
  ConsumerState<UnavailabilityScreen> createState() => _UnavailabilityScreenState();
}

class _UnavailabilityScreenState extends ConsumerState<UnavailabilityScreen> {
  /// Durée la plus longue acceptée par le serveur, en jours.
  static const int _maxDays = 60;

  final TextEditingController _note = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = isStart ? today : (_start ?? today);

    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? first,
      firstDate: first,
      lastDate: isStart ? today.add(const Duration(days: 365)) : first.add(const Duration(days: _maxDays - 1)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _error = null;
      if (isStart) {
        _start = picked;
        // Une seule journée est le cas courant : le dernier jour suit le premier.
        if (_end == null || _end!.isBefore(picked) || _end!.difference(picked).inDays >= _maxDays) {
          _end = picked;
        }
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _send() async {
    final start = _start;
    final end = _end;
    if (start == null || end == null) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(proApiProvider).reportUnavailability(startsOn: start, endsOn: end, note: _note.text.trim());
      ref.invalidate(scheduleRequestsProvider);
      if (mounted) {
        setState(() => _sent = true);
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

    return UnsavedChangesGuard(
      dirty: (_start != null || _note.text.trim().isNotEmpty) && !_busy && !_sent,
      child: NcPage(
        appBar: AppBar(),
        title: l10n.planningUnavailabilityTitle,
        subtitle: l10n.planningUnavailabilityHelp,
        actions: <Widget>[
          NcPrimaryButton(
            key: const ValueKey<String>('send-unavailability'),
            label: l10n.planningSend,
            isLoading: _busy,
            onPressed: _start == null || _end == null ? null : _send,
          ),
        ],
        children: <Widget>[
          if (_error != null) ...<Widget>[
            NcNotice(message: _error!, kind: NcNoticeKind.error),
            const SizedBox(height: NcSpacing.md),
          ],
          // Du premier au dernier jour : deux cartes côte à côte, la seconde après la première.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _DayTile(
                    key: const ValueKey<String>('first-day'),
                    label: l10n.planningFirstDay,
                    value: _start == null ? l10n.planningChooseDate : longDate(_start!, language),
                    isSet: _start != null,
                    onTap: () => _pick(isStart: true),
                  ),
                ),
                const SizedBox(width: NcSpacing.sm + 4),
                Expanded(
                  child: _DayTile(
                    key: const ValueKey<String>('last-day'),
                    label: l10n.planningLastDay,
                    value: _end == null ? l10n.planningChooseDate : longDate(_end!, language),
                    isSet: _end != null,
                    onTap: _start == null ? null : () => _pick(isStart: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NcSpacing.lg),
          NcLabeledField(
            label: l10n.planningNoteLabel,
            child: TextField(
              key: const ValueKey<String>('unavailability-note'),
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.planningNoteHint),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une date de la période : libellé, date choisie (ou invitation à choisir), appui pour la changer.
class _DayTile extends StatelessWidget {
  const _DayTile({required this.label, required this.value, required this.isSet, required this.onTap, super.key});

  final String label;
  final String value;
  final bool isSet;

  /// `null` tant que la date ne peut pas être choisie (le dernier jour vient après le premier).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: NcSurface(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        color: enabled ? null : scheme.surfaceContainer,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(NcSpacing.md - 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                NcIconBubble(
                  icon: isSet ? Icons.event_available_outlined : Icons.event_outlined,
                  size: 36,
                  background: isSet ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainer,
                  foreground: isSet ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: NcSpacing.sm),
                Text(label, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSet ? scheme.onSurface : (enabled ? scheme.primary : scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
