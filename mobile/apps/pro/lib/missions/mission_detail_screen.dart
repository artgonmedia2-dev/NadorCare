import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';
import 'journey_tracker.dart';

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

  Future<void> _decline() async {
    // La fenêtre renvoie le motif choisi, ou `null` si l'utilisateur renonce.
    final answer = await showDialog<({String reason, String note})>(
      context: context,
      builder: (dialogContext) => const _DeclineDialog(),
    );

    if (answer == null || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(proApiProvider).declineMission(widget.missionId, reason: answer.reason, note: answer.note);
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

  Future<void> _confirm() async {
    final confirmed = await _step(() => ref.read(proApiProvider).confirmMission(widget.missionId));

    if (confirmed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.missionConfirmed)));
    }
  }

  /// Exécute une étape de la mission, puis relit la fiche et la liste.
  Future<bool> _step(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await action();
      ref
        ..invalidate(missionDetailProvider(widget.missionId))
        ..invalidate(missionsProvider);
      return true;
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Téléconsultation : le professionnel ouvre l'appel, la mission passe « en cours » sans trajet.
  Future<void> _startTeleconsultation(String title) async {
    final started = await _step(() => ref.read(proApiProvider).startTeleconsultation(widget.missionId));

    if (started && mounted) {
      await _openCall(title);
    }
  }

  Future<void> _openCall(String title) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => TeleconsultationScreen(
          title: title,
          loadAccess: () => ref.read(proApiProvider).teleconsultation(widget.missionId),
        ),
      ),
    );
  }

  /// Le partage de position démarre de lui-même : l'accueil l'aligne sur la liste des
  /// missions, que le départ vient de faire relire.
  Future<void> _depart() => _step(() => ref.read(proApiProvider).depart(widget.missionId));

  Future<void> _arrive() async {
    final arrived = await _step(() async {
      // La position du pointage est jointe quand elle est disponible ; sinon on pointe sans.
      GeoPoint? position;
      try {
        position = await ref.read(locationServiceProvider).currentPosition();
      } on LocationFailure {
        position = null;
      }
      await ref
          .read(proApiProvider)
          .arrive(widget.missionId, latitude: position?.latitude, longitude: position?.longitude);
    });

    if (arrived) {
      ref.read(journeyTrackerProvider.notifier).stop();
      if (mounted) {
        await context.push(routeReport(widget.missionId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final detail = ref.watch(missionDetailProvider(widget.missionId));
    final journey = ref.watch(journeyTrackerProvider);

    return switch (detail) {
      AsyncValue<Mission>(value: final mission?) => NcPage(
          appBar: AppBar(),
          title: mission.serviceName,
          header: _header(l10n, language, mission),
          actions: <Widget>[
            // Une mission tout juste affectée se confirme d'abord ; le départ vient ensuite.
            if (mission.needsConfirmation)
              NcPrimaryButton(
                key: const ValueKey<String>('mission-confirm'),
                label: l10n.missionConfirm,
                icon: Icons.check,
                isLoading: _busy,
                onPressed: _busy ? null : _confirm,
              ),
            if (mission.isRemote && mission.status == 'assigned' && !mission.needsConfirmation)
              NcPrimaryButton(
                key: const ValueKey<String>('mission-start-call'),
                label: l10n.teleconsultationStart,
                icon: Icons.videocam_outlined,
                isLoading: _busy,
                onPressed: _busy ? null : () => _startTeleconsultation(mission.serviceName),
              ),
            if (mission.isRemote && mission.status == 'in_progress')
              NcSecondaryButton(
                key: const ValueKey<String>('mission-join-call'),
                label: l10n.teleconsultationJoin,
                icon: Icons.videocam_outlined,
                onPressed: () => _openCall(mission.serviceName),
              ),
            if (!mission.isRemote && mission.status == 'assigned' && !mission.needsConfirmation)
              NcPrimaryButton(
                key: const ValueKey<String>('mission-depart'),
                label: l10n.missionDepart,
                icon: Icons.directions_car_outlined,
                isLoading: _busy,
                onPressed: _busy ? null : _depart,
              ),
            if (mission.status == 'en_route')
              NcPrimaryButton(
                key: const ValueKey<String>('mission-arrive'),
                label: l10n.missionArrive,
                icon: Icons.place_outlined,
                isLoading: _busy,
                onPressed: _busy ? null : _arrive,
              ),
            if (mission.status == 'in_progress')
              NcPrimaryButton(
                key: const ValueKey<String>('mission-report'),
                label: l10n.missionOpenReport,
                icon: Icons.description_outlined,
                onPressed: () => context.push(routeReport(widget.missionId)),
              ),
            if (mission.canDecline)
              NcSecondaryButton(
                key: const ValueKey<String>('mission-decline'),
                label: l10n.missionDecline,
                onPressed: _busy ? null : _decline,
              ),
          ],
          children: <Widget>[
            if (_error != null) ...<Widget>[
              NcNotice(message: _error!, kind: NcNoticeKind.error),
              const SizedBox(height: NcSpacing.md),
            ],
            if (mission.needsConfirmation) ...<Widget>[
              NcNotice(key: const ValueKey<String>('mission-to-confirm'), message: l10n.missionConfirmHelp),
              const SizedBox(height: NcSpacing.md),
            ],
            if (mission.isRemote) ...<Widget>[
              NcNotice(
                key: const ValueKey<String>('mission-remote'),
                message: '${l10n.teleconsultationNoJourney} ${l10n.teleconsultationRoomHelp}',
              ),
            ],
            if (mission.status == 'en_route') ...<Widget>[
              if (journey.locationUnavailable)
                NcNotice(
                  key: const ValueKey<String>('journey-location-off'),
                  message: l10n.journeyLocationOff,
                  kind: NcNoticeKind.warning,
                )
              else
                NcNotice(
                  key: const ValueKey<String>('journey-sharing'),
                  message: journey.etaSeconds == null
                      ? l10n.journeySharing
                      : '${l10n.journeySharing}\n${l10n.journeyEta((journey.etaSeconds! / 60).ceil())}',
                ),
              const SizedBox(height: NcSpacing.md),
            ],
            // Où aller et chez qui : une section, une icône par information.
            NcSection(
              title: l10n.missionWhereTitle,
              icon: Icons.place_outlined,
              children: <Widget>[
                  NcInfoRow(icon: Icons.person_outline, label: l10n.summaryPatient, value: mission.patientName),
                  NcInfoRow(
                    icon: Icons.place_outlined,
                    label: l10n.summaryAddress,
                    value: <String?>[mission.addressLine, mission.city].whereType<String>().join('\n'),
                  ),
                  if ((mission.accessNotes ?? '').isNotEmpty)
                    NcInfoRow(
                      icon: Icons.key_outlined,
                      label: l10n.missionAccessNotes,
                      value: mission.accessNotes!,
                    ),
              ],
            ),
            if ((mission.careNotes ?? '').isNotEmpty ||
                (mission.patientNote ?? '').isNotEmpty ||
                mission.amountToCollect > 0)
              NcSection(
                title: l10n.missionNotesTitle,
                icon: Icons.info_outline,
                children: <Widget>[
                    if ((mission.careNotes ?? '').isNotEmpty)
                      NcInfoRow(
                        icon: Icons.medical_information_outlined,
                        label: l10n.missionCareNotes,
                        value: mission.careNotes!,
                      ),
                    if ((mission.patientNote ?? '').isNotEmpty)
                      NcInfoRow(
                        icon: Icons.chat_bubble_outline,
                        label: l10n.missionPatientNote,
                        value: mission.patientNote!,
                      ),
                    if (mission.amountToCollect > 0)
                      NcInfoRow(
                        icon: Icons.payments_outlined,
                        label: l10n.missionAmount,
                        value: l10n.priceDirhams(formatDirhams(mission.amountToCollect, language)),
                      ),
                ],
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

/// En-tête de la fiche : le soin, la date et l'état, dans le ton de l'état.
Widget _header(NcLocalizations l10n, String language, Mission mission) {
  final badge = mission.needsConfirmation ? missionToConfirmBadge(l10n, mission) : missionStatusBadge(l10n, mission.status);

  return NcDetailHeader(
    icon: mission.isRemote ? Icons.videocam_outlined : badge.icon,
    tone: badge.tone,
    title: mission.serviceName,
    subtitle: l10n.dateAtTime(longDate(mission.scheduledDate, language), mission.scheduledTime),
    badge: badge,
  );
}

/// Fenêtre d'indisponibilité : un motif parmi quelques-uns, et une précision, obligatoire
/// quand le motif est « Autre ». La coordination en a besoin pour réaffecter la mission.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final TextEditingController _note = TextEditingController();
  String? _reason;
  String? _reasonError;
  String? _noteError;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _send() {
    final l10n = context.l10n;
    final reason = _reason;
    final note = _note.text.trim();

    setState(() {
      _reasonError = reason == null ? l10n.declineReasonRequired : null;
      _noteError = reason == 'other' && note.isEmpty ? l10n.declineNoteRequired : null;
    });

    if (reason == null || _noteError != null) {
      return;
    }

    Navigator.of(context).pop((reason: reason, note: note));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.missionDeclineTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.missionDeclineBody),
            const SizedBox(height: NcSpacing.md),
            NcChoiceList<String>(
              keyPrefix: 'decline-reason',
              choices: <NcChoice<String>>[
                for (final reason in declineReasons)
                  NcChoice<String>(value: reason, label: declineReasonLabel(l10n, reason)),
              ],
              selected: _reason,
              onSelected: (reason) => setState(() {
                _reason = reason;
                _reasonError = null;
                _noteError = null;
              }),
            ),
            if (_reasonError != null)
              Text(
                _reasonError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: NcSpacing.sm),
            NcLabeledField(
              label: l10n.declineNoteLabel,
              child: TextField(
                key: const ValueKey<String>('decline-note'),
                controller: _note,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(errorText: _noteError),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(
          key: const ValueKey<String>('decline-send'),
          onPressed: _send,
          child: Text(l10n.missionDeclineSend),
        ),
      ],
    );
  }
}
