import 'package:flutter/painting.dart';

/// Couleurs de l'identité Nador Care (refonte du 2026-11-24), les mêmes que le site et le
/// back-office : maquettes Figma « Nador Care — Refonte UX/UI ». Les écrans ne les lisent pas
/// directement : ils passent par le thème (`Theme.of(context).colorScheme`) ou par les composants.
abstract final class NcColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryStrong = Color(0xFF0B5C56);
  static const Color primaryDeep = Color(0xFF083F3B);
  static const Color primarySoft = Color(0xFFD5F2EC);

  /// Ce qui demande une action (compteurs, urgences).
  static const Color accent = Color(0xFFC2410C);
  static const Color accentSoft = Color(0xFFFDEBDD);

  /// Pouls du logo de l'application soignant, sur fond teal profond.
  static const Color accentLight = Color(0xFFFDBA8C);

  /// Fond chaleureux des écrans d'accueil.
  static const Color sand = Color(0xFFFBF6EE);

  /// Fond des écrans : gris très clair, sur lequel les cartes blanches se détachent sans bordure
  /// (refonte du 2026-11-24, inspirée d'une application de soins à domicile).
  static const Color page = Color(0xFFF1F4F4);
  static const Color card = Color(0xFFFFFFFF);

  /// Bord discret des champs de saisie, posés sur le fond gris.
  static const Color cardEdge = Color(0xFFE1E8E6);

  /// Ombre portée des cartes : très légère, elle remplace la bordure.
  static const Color shadow = Color(0x0F10201D);
  static const Color muted = Color(0xFFEAF1EF);

  static const Color text = Color(0xFF10201D);
  static const Color textMuted = Color(0xFF4A5956);

  static const Color border = Color(0xFFD3DEDB);
  static const Color borderStrong = Color(0xFF8EA09C);

  static const Color success = Color(0xFF15803D);
  static const Color successSoft = Color(0xFFDCF5E3);
  static const Color warning = Color(0xFF92400E);
  static const Color warningSoft = Color(0xFFFEF0C7);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSoft = Color(0xFFFDE8E6);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoSoft = Color(0xFFE0EAFF);
}
