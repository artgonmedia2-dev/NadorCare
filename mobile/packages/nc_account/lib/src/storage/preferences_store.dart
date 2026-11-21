import 'package:shared_preferences/shared_preferences.dart';

import '../settings/app_settings.dart';

/// Réglages de l'appareil (langue, taille du texte, verrouillage). Rien de sensible ici.
abstract interface class PreferencesStore {
  AppSettings read();

  Future<void> write(AppSettings settings);
}

class SharedPreferencesStore implements PreferencesStore {
  const SharedPreferencesStore(this._preferences);

  static const String _language = 'nc.settings.language';
  static const String _textScale = 'nc.settings.text_scale';
  static const String _biometric = 'nc.settings.biometric';

  final SharedPreferences _preferences;

  @override
  AppSettings read() {
    return AppSettings(
      languageCode: _preferences.getString(_language),
      textSize: NcTextSize.fromName(_preferences.getString(_textScale)),
      biometricEnabled: _preferences.getBool(_biometric) ?? false,
    );
  }

  @override
  Future<void> write(AppSettings settings) async {
    final language = settings.languageCode;
    if (language == null) {
      await _preferences.remove(_language);
    } else {
      await _preferences.setString(_language, language);
    }
    await _preferences.setString(_textScale, settings.textSize.name);
    await _preferences.setBool(_biometric, settings.biometricEnabled);
  }
}

/// Réglages en mémoire, pour les tests.
class InMemoryPreferencesStore implements PreferencesStore {
  InMemoryPreferencesStore([this.settings = const AppSettings()]);

  AppSettings settings;

  @override
  AppSettings read() => settings;

  @override
  Future<void> write(AppSettings settings) async => this.settings = settings;
}
