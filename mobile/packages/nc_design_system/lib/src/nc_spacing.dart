/// Échelle d'espacement, en pixels logiques.
abstract final class NcSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Hauteur minimale des zones tactiles : boutons larges pour les personnes âgées (§11).
  static const double touchTarget = 56;

  /// Largeur maximale du contenu sur tablette.
  static const double maxContentWidth = 520;
}
