import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Fiche d'une mission : ce qu'il faut pour se rendre chez le patient et réaliser le soin.
/// Son ouverture est inscrite au journal des accès par le serveur.
class MissionDetailScreen extends ConsumerStatefulWidget {
  const MissionDetailScreen({required this.missionId, super.key});

  final String missionId;

  @override
  ConsumerState<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends ConsumerState<MissionDetailScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _withdraw() async {
    // La fenêtre renvoie le motif saisi, ou `null` si l'utilisateur renonce.
    final text = await showDialog<String>(context: context, builder: (dialogContext) => const _WithdrawDialog());

    if (text == null || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(proApiProvider).withdraw(widget.missionId, reason: text);
      ref.invalidate(missionsProvider);
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
    final detail = ref.watch(missionDetailProvider(widget.missionId));

    return switch (detail) {
      AsyncData<Mission>(value: final mission) => NcPage(
          appBar: AppBar(),
          title: mission.serviceName,
          subtitle: l10n.dateAtTime(longDate(mission.scheduledDate, language), mission.scheduledTime),
          actions: <Widget>[
            if (mission.canWithdraw)
              NcSecondaryButton(
                key: const ValueKey<String>('mission-withdraw'),
                label: l10n.missionWithdraw,
                onPressed: _busy ? null : _withdraw,
              ),
          ],
          children: <Widget>[
            if (_error != null) ...<Widget>[
              NcNotice(message: _error!, kind: NcNoticeKind.error),
              const SizedBox(height: NcSpacing.md),
            ],
            NcNotice(message: missionStatusLabel(l10n, mission.status)),
            const SizedBox(height: NcSpacing.lg),
            _Info(label: l10n.summaryPatient, value: mission.patientName),
            _Info(
              label: l10n.summaryAddress,
              value: <String?>[mission.addressLine, mission.city].whereType<String>().join('\n'),
            ),
            if ((mission.accessNotes ?? '').isNotEmpty)
              _Info(label: l10n.missionAccessNotes, value: mission.accessNotes!),
            if ((mission.careNotes ?? '').isNotEmpty) _Info(label: l10n.missionCareNotes, value: mission.careNotes!),
            if ((mission.patientNote ?? '').isNotEmpty)
              _Info(label: l10n.missionPatientNote, value: mission.patientNote!),
            if (mission.amountToCollect > 0)
              _Info(
                label: l10n.missionAmount,
                value: l10n.priceDirhams(formatDirhams(mission.amountToCollect, language)),
              ),
            if (mission.hasPrescription) NcNotice(message: l10n.missionPrescription),
          ],
        ),
      AsyncError<Mission>(:final error) => NcPage(
          appBar: AppBar(),
          title: l10n.proMissionsTitle,
          actions: <Widget>[
            NcPrimaryButton(
              label: l10n.retry,
              onPressed: () => ref.invalidate(missionDetailProvider(widget.missionId)),
            ),
          ],
          children: <Widget>[NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error)],
        ),
      _ => NcPage(
          appBar: AppBar(),
          title: l10n.proMissionsTitle,
          children: const <Widget>[Center(child: CircularProgressIndicator())],
        ),
    };
  }
}

/// Fenêtre de désistement. Le motif est obligatoire : la coordination en a besoin pour
/// réaffecter la mission.
class _WithdrawDialog extends StatefulWidget {
  const _WithdrawDialog();

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _reason.text.trim();

    if (text.length < 3) {
      setState(() => _error = context.l10n.fieldRequired);
      return;
    }

    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.missionWithdrawTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l10n.missionWithdrawBody),
          const SizedBox(height: NcSpacing.md),
          TextField(
            key: const ValueKey<String>('withdraw-reason'),
            controller: _reason,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.missionWithdrawReason, errorText: _error),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(onPressed: _confirm, child: Text(l10n.missionWithdraw)),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: NcSpacing.xs),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
