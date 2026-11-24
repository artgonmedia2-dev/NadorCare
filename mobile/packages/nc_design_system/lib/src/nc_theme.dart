import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nc_colors.dart';
import 'nc_spacing.dart';

/// Thème clair (le mode sombre est prévu en version 2).
///
/// Refonte du 2026-11-24 : les couleurs sont celles du site et du back-office (`NcColors`), posées
/// une à une et non dérivées d'une couleur « graine », pour que les trois surfaces se ressemblent.
abstract final class NcTheme {
  static const Color seed = NcColors.primary;

  /// Polices embarquées dans ce paquet : un nom de famille d'un paquet se préfixe ainsi.
  static const String headingFont = 'packages/nc_design_system/Figtree';
  static const String bodyFont = 'packages/nc_design_system/NotoSans';

  /// Relais pour les lettres que les polices latines n'ont pas : l'arabe.
  static const List<String> fontFallback = <String>['packages/nc_design_system/NotoSansArabic'];

  /// Titres et boutons en Figtree, comme sur le site.
  static TextStyle? _heading(TextStyle? style) => style?.copyWith(fontFamily: headingFont);

  /// Barres du système assorties à l'écran : fond clair, icônes sombres, en haut comme en bas.
  static SystemUiOverlayStyle overlayStyle(ColorScheme scheme) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: scheme.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  static ColorScheme get scheme => ColorScheme.fromSeed(seedColor: seed).copyWith(
    primary: NcColors.primary,
    onPrimary: Colors.white,
    primaryContainer: NcColors.primarySoft,
    onPrimaryContainer: NcColors.primaryDeep,
    secondary: NcColors.primaryStrong,
    onSecondary: Colors.white,
    secondaryContainer: NcColors.primarySoft,
    onSecondaryContainer: NcColors.primaryDeep,
    tertiary: NcColors.accent,
    onTertiary: Colors.white,
    tertiaryContainer: NcColors.accentSoft,
    onTertiaryContainer: NcColors.accent,
    error: NcColors.danger,
    onError: Colors.white,
    errorContainer: NcColors.dangerSoft,
    onErrorContainer: NcColors.danger,
    surface: NcColors.page,
    onSurface: NcColors.text,
    onSurfaceVariant: NcColors.textMuted,
    surfaceContainerLowest: NcColors.card,
    surfaceContainerLow: NcColors.card,
    surfaceContainer: NcColors.muted,
    surfaceContainerHigh: NcColors.muted,
    surfaceContainerHighest: NcColors.muted,
    outline: NcColors.borderStrong,
    outlineVariant: NcColors.border,
  );

  static ThemeData light() {
    final scheme = NcTheme.scheme;
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: bodyFont,
      fontFamilyFallback: fontFallback,
    );

    // Boutons en pilule, comme les maquettes de la refonte.
    const shape = StadiumBorder();
    const buttonText = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFamily: headingFont,
      fontFamilyFallback: fontFallback,
    );
    const minimumSize = Size(double.infinity, NcSpacing.touchTarget);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      // Textes plus grands que la valeur par défaut, pour la lisibilité ; titres appuyés comme sur le site.
      textTheme: base.textTheme
          .copyWith(
            displaySmall: _heading(base.textTheme.displaySmall),
            headlineLarge: _heading(base.textTheme.headlineLarge),
            headlineMedium: _heading(base.textTheme.headlineMedium)?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.4,
            ),
            headlineSmall: _heading(base.textTheme.headlineSmall),
            titleLarge: _heading(base.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.w700),
            titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
            bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.45),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.45),
          )
          .apply(bodyColor: NcColors.text, displayColor: NcColors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle(scheme),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NcColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: NcColors.card, surfaceTintColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NcColors.primaryDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          shape: shape,
          textStyle: buttonText,
          backgroundColor: NcColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minimumSize,
          shape: shape,
          textStyle: buttonText,
          foregroundColor: NcColors.primaryStrong,
          backgroundColor: NcColors.card,
          side: const BorderSide(color: NcColors.primary, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, NcSpacing.touchTarget),
          foregroundColor: NcColors.primaryStrong,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: headingFont,
            fontFamilyFallback: fontFallback,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NcColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: NcSpacing.md, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NcColors.cardEdge),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NcColors.primary, width: 2),
        ),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? NcColors.primary : NcColors.borderStrong,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: NcColors.primary, linearTrackColor: NcColors.muted),
    );
  }
}
