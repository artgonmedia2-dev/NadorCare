import 'package:flutter/material.dart';

import 'nc_spacing.dart';

/// Thème clair (le mode sombre est prévu en version 2).
abstract final class NcTheme {
  static const Color seed = Color(0xFF0F766E);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const buttonText = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    const minimumSize = Size(double.infinity, NcSpacing.touchTarget);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      // Textes plus grands que la valeur par défaut, pour la lisibilité.
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.4),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: minimumSize, shape: shape, textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minimumSize, shape: shape, textStyle: buttonText),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, NcSpacing.touchTarget),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: NcSpacing.md, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
    );
  }
}
