import 'package:flutter/material.dart';

import 'nc_colors.dart';
import 'nc_spacing.dart';
import 'nc_surface.dart';

// Composants des écrans d'accueil (refonte du 2026-11-24, inspirée d'une maquette d'application
// de soins à domicile) : en-tête de salutation, pastilles d'icône, tuiles d'accès rapide,
// lignes d'activité compactes et chiffres du jour.

/// Icône posée dans un rond de couleur claire. Décorative : le texte voisin porte le sens.
class NcIconBubble extends StatelessWidget {
  const NcIconBubble({
    required this.icon,
    this.size = 44,
    this.background = NcColors.primarySoft,
    this.foreground = NcColors.primaryStrong,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.52, color: foreground),
      ),
    );
  }
}

/// Bouton rond blanc, pour les actions d'un en-tête (réglages, rafraîchir).
class NcRoundIconButton extends StatelessWidget {
  const NcRoundIconButton({required this.icon, required this.tooltip, required this.onPressed, super.key});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: ncCardShadow),
      child: Material(
        color: NcColors.card,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: NcColors.text),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        ),
      ),
    );
  }
}

/// Initiale du compte dans un rond teal.
class NcAvatar extends StatelessWidget {
  const NcAvatar({required this.name, this.size = 48, super.key});

  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = (name ?? '').trim();
    final initial = trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase();

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[NcColors.primary, NcColors.primaryDeep],
          ),
        ),
        child: initial.isEmpty
            ? Icon(Icons.person_outline, color: NcColors.card, size: size * 0.5)
            : Text(
                initial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: NcColors.card, fontSize: size * 0.42),
              ),
      ),
    );
  }
}

/// En-tête d'accueil : une ligne discrète, la salutation en grand, puis des actions rondes.
class NcHomeHeader extends StatelessWidget {
  const NcHomeHeader({required this.greeting, this.caption, this.trailing = const <Widget>[], super.key});

  final String greeting;

  /// Ligne discrète sous la salutation.
  final String? caption;

  /// Boutons ronds et avatar, en fin de ligne.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(header: true, child: Text(greeting, style: textTheme.headlineMedium)),
                if (caption != null) ...<Widget>[
                  const SizedBox(height: NcSpacing.xs),
                  Text(caption!, style: textTheme.bodyMedium?.copyWith(color: NcColors.textMuted)),
                ],
              ],
            ),
          ),
          for (final widget in trailing) ...<Widget>[const SizedBox(width: NcSpacing.sm), widget],
        ],
      ),
    );
  }
}

/// Tuile carrée : une pastille d'icône et un libellé centré, parfois une précision dessous.
class NcActionTile extends StatelessWidget {
  const NcActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.flat = false,
    super.key,
  });

  /// Tuile posée dans une carte blanche : fond gris clair, sans ombre.
  final bool flat;

  final IconData icon;
  final String label;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(ncRadius), boxShadow: flat ? null : ncCardShadow),
      child: Material(
        color: flat ? NcColors.page : NcColors.card,
        borderRadius: BorderRadius.circular(ncRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(ncRadius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: flat ? 96 : 112),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NcSpacing.sm, vertical: NcSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  NcIconBubble(icon: icon, background: flat ? NcColors.card : NcColors.primarySoft),
                  const SizedBox(height: NcSpacing.sm + 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: NcColors.text,
                      height: 1.25,
                    ),
                  ),
                  if (caption != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: NcColors.textMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grille de tuiles de même hauteur par rangée, sur [columns] colonnes.
class NcTileGrid extends StatelessWidget {
  const NcTileGrid({required this.children, this.columns = 2, super.key});

  final List<Widget> children;
  final int columns;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var column = 0; column < columns; column++) {
        if (column > 0) {
          cells.add(const SizedBox(width: _gap));
        }
        final index = start + column;
        cells.add(Expanded(child: index < children.length ? children[index] : const SizedBox.shrink()));
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.sm),
      child: Column(children: rows),
    );
  }
}

/// Ligne d'activité compacte : une pastille d'icône, un texte, une précision en fin de ligne.
class NcFeedRow extends StatelessWidget {
  const NcFeedRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.tone = NcBadgeTone.brand,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Élément en fin de ligne (une étiquette d'état, par exemple).
  final Widget? trailing;
  final NcBadgeTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (Color background, Color foreground) = ncToneColors(tone);

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(ncRadius), boxShadow: ncCardShadow),
        child: Material(
          color: NcColors.card,
          borderRadius: BorderRadius.circular(ncRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(ncRadius),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: NcSpacing.touchTarget + 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: NcSpacing.md - 2, vertical: NcSpacing.sm + 2),
                child: Row(
                  children: <Widget>[
                    NcIconBubble(icon: icon, size: 40, background: background, foreground: foreground),
                    const SizedBox(width: NcSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(title, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                          if (subtitle != null)
                            Text(subtitle!, style: textTheme.bodyMedium?.copyWith(color: NcColors.textMuted, fontSize: 14)),
                        ],
                      ),
                    ),
                    if (trailing != null) ...<Widget>[const SizedBox(width: NcSpacing.sm), trailing!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chiffre du jour : un nombre en grand et son libellé, dans une carte.
class NcStatTile extends StatelessWidget {
  const NcStatTile({required this.value, required this.label, required this.icon, this.tone = NcBadgeTone.brand, super.key});

  final String value;
  final String label;
  final IconData icon;
  final NcBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (Color background, Color foreground) = ncToneColors(tone);

    return Semantics(
      container: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(NcSpacing.sm + 4),
        decoration: BoxDecoration(
          color: NcColors.card,
          borderRadius: BorderRadius.circular(ncRadius),
          boxShadow: ncCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NcIconBubble(icon: icon, size: 36, background: background, foreground: foreground),
            const SizedBox(height: NcSpacing.sm),
            Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodyMedium?.copyWith(color: NcColors.textMuted, fontSize: 13, height: 1.25)),
          ],
        ),
      ),
    );
  }
}
