import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../failure_message.dart';

/// Écran d'appel d'une téléconsultation, commun aux deux applications.
///
/// Il demande au serveur l'accès à la salle, puis affiche l'appel. Le prestataire vidéo n'est
/// pas encore choisi : avec le pilote factice du serveur, l'appel est simulé et l'écran le dit.
/// Quand un vrai prestataire sera branché, son module prendra la place de [_SimulatedCall].
class TeleconsultationScreen extends StatefulWidget {
  const TeleconsultationScreen({required this.title, required this.loadAccess, super.key});

  /// Nom du soin, affiché en haut de l'appel.
  final String title;

  /// Demande l'accès à la salle. Échoue si la salle n'est pas ouverte.
  final Future<VideoAccess> Function() loadAccess;

  @override
  State<TeleconsultationScreen> createState() => _TeleconsultationScreenState();
}

class _TeleconsultationScreenState extends State<TeleconsultationScreen> {
  VideoAccess? _access;
  Object? _failure;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() => _failure = null);

    try {
      final access = await widget.loadAccess();
      if (mounted) {
        setState(() => _access = access);
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _failure = failure);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final access = _access;

    if (access != null) {
      return _SimulatedCall(title: widget.title, access: access);
    }

    return NcPage(
      appBar: AppBar(),
      title: l10n.teleconsultationLabel,
      subtitle: widget.title,
      actions: <Widget>[
        if (_failure != null) NcPrimaryButton(label: l10n.retry, icon: Icons.refresh, onPressed: _connect),
      ],
      children: <Widget>[
        if (_failure != null) ...<Widget>[
          NcNotice(
            key: const ValueKey<String>('call-error'),
            message: failureMessage(context, _failure!),
            kind: NcNoticeKind.error,
          ),
          const SizedBox(height: NcSpacing.md),
          NcNotice(message: l10n.teleconsultationRoomHelp),
        ] else ...<Widget>[
          const SizedBox(height: NcSpacing.xl),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: NcSpacing.md),
          Center(child: Text(l10n.callConnecting)),
        ],
      ],
    );
  }
}

/// Appel simulé : les mêmes commandes qu'un vrai appel, sans image ni son.
class _SimulatedCall extends StatefulWidget {
  const _SimulatedCall({required this.title, required this.access});

  final String title;
  final VideoAccess access;

  @override
  State<_SimulatedCall> createState() => _SimulatedCallState();
}

class _SimulatedCallState extends State<_SimulatedCall> {
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _ticker;
  bool _muted = false;
  bool _cameraOff = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final seconds = _clock.elapsed.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teleconsultationLabel)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NcSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(widget.title, style: textTheme.headlineSmall),
              const SizedBox(height: NcSpacing.sm),
              Row(
                children: <Widget>[
                  NcStatusBadge(label: l10n.callInProgress, icon: Icons.videocam_outlined, tone: NcBadgeTone.success),
                  const SizedBox(width: NcSpacing.md),
                  // Une durée se lit de gauche à droite, même en arabe.
                  Text(_elapsed, key: const ValueKey<String>('call-elapsed'), textDirection: TextDirection.ltr),
                ],
              ),
              const SizedBox(height: NcSpacing.md),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(ncRadius),
                  ),
                  child: Center(
                    child: Icon(
                      _cameraOff ? Icons.videocam_off_outlined : Icons.person_outline,
                      size: 96,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: NcSpacing.md),
              if (widget.access.isSimulated)
                NcNotice(
                  key: const ValueKey<String>('call-simulated'),
                  message: l10n.callSimulated,
                  kind: NcNoticeKind.warning,
                ),
              const SizedBox(height: NcSpacing.md),
              NcSecondaryButton(
                key: const ValueKey<String>('call-mute'),
                label: _muted ? l10n.callUnmute : l10n.callMute,
                icon: _muted ? Icons.mic_off_outlined : Icons.mic_none,
                onPressed: () => setState(() => _muted = !_muted),
              ),
              const SizedBox(height: NcSpacing.sm),
              NcSecondaryButton(
                key: const ValueKey<String>('call-camera'),
                label: _cameraOff ? l10n.callCameraOn : l10n.callCameraOff,
                icon: _cameraOff ? Icons.videocam_off_outlined : Icons.videocam_outlined,
                onPressed: () => setState(() => _cameraOff = !_cameraOff),
              ),
              const SizedBox(height: NcSpacing.sm),
              NcPrimaryButton(
                key: const ValueKey<String>('call-hang-up'),
                label: l10n.callHangUp,
                icon: Icons.call_end,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
