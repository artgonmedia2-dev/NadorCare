import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';

import '../pro_providers.dart';

/// Trajet en cours : mission suivie, durée restante, et si la position a pu être lue.
class JourneyState {
  const JourneyState({this.missionId, this.etaSeconds, this.locationUnavailable = false});

  /// Mission pour laquelle la position est partagée ; `null` hors trajet.
  final String? missionId;
  final int? etaSeconds;

  /// Localisation refusée, coupée ou introuvable : le patient ne voit pas l'arrivée.
  final bool locationUnavailable;
}

/// Partage la position du professionnel avec le patient, uniquement pendant le trajet :
/// du départ au pointage d'arrivée, application ouverte. Rien n'est envoyé en dehors.
class JourneyTracker extends Notifier<JourneyState> {
  static const Duration interval = Duration(seconds: 20);

  Timer? _timer;
  bool _sending = false;

  @override
  JourneyState build() {
    ref.onDispose(() => _timer?.cancel());
    return const JourneyState();
  }

  /// Aligne le suivi sur les missions : il tourne si l'une d'elles est « en route ».
  void sync(List<Mission> missions) {
    for (final mission in missions) {
      if (mission.status == 'en_route') {
        start(mission.id);
        return;
      }
    }
    stop();
  }

  void start(String missionId) {
    if (state.missionId == missionId) {
      return;
    }

    _timer?.cancel();
    state = JourneyState(missionId: missionId);
    _timer = Timer.periodic(interval, (_) => unawaited(_send()));
    unawaited(_send());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (state.missionId != null) {
      state = const JourneyState();
    }
  }

  Future<void> _send() async {
    final missionId = state.missionId;
    if (missionId == null || _sending) {
      return;
    }

    _sending = true;
    try {
      final position = await ref.read(locationServiceProvider).currentPosition();
      if (!ref.mounted || state.missionId != missionId) {
        return;
      }

      final eta = await ref
          .read(proApiProvider)
          .sendLocation(missionId, latitude: position.latitude, longitude: position.longitude);
      if (ref.mounted && state.missionId == missionId) {
        state = JourneyState(missionId: missionId, etaSeconds: eta);
      }
    } on ApiFailure catch (failure) {
      // Le serveur n'attend plus de position (arrivée pointée, mission retirée) : on arrête.
      // Hors ligne, on réessaiera au prochain passage.
      if (ref.mounted && (failure.code == 'location_not_expected' || failure.status == 404)) {
        stop();
      }
    } on Exception {
      // Localisation refusée, coupée ou en panne : le trajet continue, sans suivi.
      if (ref.mounted && state.missionId == missionId) {
        state = JourneyState(missionId: missionId, locationUnavailable: true);
      }
    } finally {
      _sending = false;
    }
  }
}

final journeyTrackerProvider = NotifierProvider<JourneyTracker, JourneyState>(JourneyTracker.new);
