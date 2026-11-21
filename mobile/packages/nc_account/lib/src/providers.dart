import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';

import 'biometric_service.dart';
import 'settings/settings_controller.dart';
import 'storage/preferences_store.dart';
import 'storage/session_storage.dart';

/// Configuration de l'application. Fournie au démarrage par `ProviderScope(overrides: ...)`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider doit être fourni au démarrage.'),
);

/// Réglages enregistrés. Fournis au démarrage, une fois SharedPreferences chargé.
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => throw UnimplementedError('preferencesStoreProvider doit être fourni au démarrage.'),
);

final sessionStorageProvider = Provider<SessionStorage>((ref) => SecureSessionStorage());

final biometricServiceProvider = Provider<BiometricService>((ref) => LocalAuthBiometricService());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    readToken: () => ref.read(sessionStorageProvider).readToken(),
    readLanguage: () => ref.read(settingsControllerProvider).languageCode ?? defaultLanguageCode,
  );
});

final authApiProvider = Provider<AuthApi>((ref) => HttpAuthApi(ref.watch(apiClientProvider)));
