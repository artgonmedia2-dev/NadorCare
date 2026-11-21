import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_core/nc_core.dart';

import '../providers.dart';
import 'app_settings.dart';

/// Réglages de l'appareil, enregistrés à chaque changement.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(preferencesStoreProvider).read();

  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguageCodes.contains(languageCode)) {
      return;
    }
    await _update(state.copyWith(languageCode: languageCode));
  }

  Future<void> setTextSize(NcTextSize size) => _update(state.copyWith(textSize: size));

  Future<void> setBiometricEnabled(bool enabled) => _update(state.copyWith(biometricEnabled: enabled));

  Future<void> _update(AppSettings settings) async {
    state = settings;
    await ref.read(preferencesStoreProvider).write(settings);
  }
}

final settingsControllerProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
