import 'package:flutter/foundation.dart';

/// Taille du texte réglable (§11). Le facteur s'ajoute au réglage du système.
enum NcTextSize {
  normal(1),
  large(1.15),
  extraLarge(1.3);

  const NcTextSize(this.factor);

  final double factor;

  static NcTextSize fromName(String? name) {
    return NcTextSize.values.firstWhere((size) => size.name == name, orElse: () => NcTextSize.normal);
  }
}

@immutable
class AppSettings {
  const AppSettings({
    this.languageCode,
    this.textSize = NcTextSize.normal,
    this.biometricEnabled = false,
  });

  /// `null` tant que l'utilisateur n'a pas choisi : l'écran de langue s'affiche alors.
  final String? languageCode;
  final NcTextSize textSize;
  final bool biometricEnabled;

  AppSettings copyWith({String? languageCode, NcTextSize? textSize, bool? biometricEnabled}) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      textSize: textSize ?? this.textSize,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.languageCode == languageCode &&
      other.textSize == textSize &&
      other.biometricEnabled == biometricEnabled;

  @override
  int get hashCode => Object.hash(languageCode, textSize, biometricEnabled);
}
