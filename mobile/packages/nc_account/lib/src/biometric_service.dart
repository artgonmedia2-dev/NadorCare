import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Empreinte ou reconnaissance du visage. L'interface permet de simuler l'appareil dans les tests.
abstract interface class BiometricService {
  /// L'appareil a un capteur et au moins une empreinte ou un visage enregistré.
  Future<bool> isAvailable();

  /// Demande à l'utilisateur de prouver son identité. [reason] est déjà traduit.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return false;
      }
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } on Exception {
      // Capteur indisponible, trop d'essais ou annulation : l'accès reste verrouillé.
      return false;
    }
  }
}
