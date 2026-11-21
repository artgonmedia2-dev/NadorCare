import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';

import '../providers.dart';
import '../settings/settings_controller.dart';
import 'auth_state.dart';

/// Session de l'utilisateur : démarrage, connexion par OTP, déverrouillage, déconnexion.
///
/// Les méthodes lèvent [ApiFailure] ; les écrans affichent le message, déjà traduit par le serveur.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitializing();

  AuthApi get _api => ref.read(authApiProvider);

  /// À appeler une fois au lancement : restaure la session enregistrée.
  Future<void> bootstrap() async {
    final storage = ref.read(sessionStorageProvider);

    if (await storage.readToken() == null) {
      state = const AuthSignedOut();
      return;
    }

    final lockEnabled = ref.read(settingsControllerProvider).biometricEnabled;
    if (lockEnabled && await ref.read(biometricServiceProvider).isAvailable()) {
      state = const AuthLocked();
      return;
    }

    await _restore();
  }

  /// Déverrouille par empreinte ou visage. [reason] est le texte affiché par le système.
  Future<bool> unlock(String reason) async {
    if (!await ref.read(biometricServiceProvider).authenticate(reason)) {
      return false;
    }
    await _restore();
    return true;
  }

  Future<OtpChallenge> requestOtp(String phone) => _api.requestOtp(phone);

  /// Vérifie le code. Si le numéro est nouveau et que [acceptTerms] est faux, le serveur
  /// répond `consent_required` sans consommer le code : l'écran de consentement le renvoie.
  Future<void> verifyOtp({required String phone, required String code, required bool acceptTerms}) async {
    final config = ref.read(appConfigProvider);

    final session = await _api.verifyOtp(
      phone: phone,
      code: code,
      app: config.clientApp,
      deviceName: defaultTargetPlatform.name,
      acceptTerms: acceptTerms,
      locale: ref.read(settingsControllerProvider).languageCode,
    );

    await ref.read(sessionStorageProvider).save(token: session.token, user: session.user);
    state = AuthSignedIn(session.user);
  }

  Future<void> updateProfile({String? name, String? locale}) async {
    final user = await _api.updateMe(name: name, locale: locale);
    await ref.read(sessionStorageProvider).saveUser(user);
    state = AuthSignedIn(user);
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } on ApiFailure {
      // Hors ligne ou jeton déjà révoqué : la session locale est effacée dans tous les cas.
    }
    await _clear();
  }

  Future<void> _restore() async {
    final storage = ref.read(sessionStorageProvider);

    try {
      final user = await _api.me();
      await storage.saveUser(user);
      state = AuthSignedIn(user);
    } on ApiFailure catch (failure) {
      if (failure.status == 401 || failure.status == 403) {
        // Jeton expiré ou révoqué, compte suspendu.
        await _clear();
        return;
      }

      // Pas de réseau : on ouvre l'application avec le dernier compte connu.
      final cached = await storage.readUser();
      if (cached == null) {
        await _clear();
      } else {
        state = AuthSignedIn(cached);
      }
    }
  }

  Future<void> _clear() async {
    await ref.read(sessionStorageProvider).clear();
    state = const AuthSignedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
