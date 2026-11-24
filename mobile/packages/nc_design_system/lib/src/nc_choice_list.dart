import 'package:flutter/material.dart';

import 'nc_colors.dart';
import 'nc_home.dart';
import 'nc_spacing.dart';
import 'nc_surface.dart';

/// Une option d'une [NcChoiceList].
class NcChoice<T> {
  const NcChoice({required this.value, required this.label, this.subtitle, this.icon, this.warning});

  final T value;
  final String label;

  /// Précision sous le libellé (une adresse, par exemple).
  final String? subtitle;

  /// Icône dans une pastille, avant le libellé.
  final IconData? icon;

  /// Avertissement sous la précision (« hors zone »), en couleur d'alerte.
  final String? warning;
}

/// Choix d'une seule valeur parmi quelques-unes, une grande ligne par option.
/// Préféré aux boutons radio : la zone tactile couvre toute la ligne.
class NcChoiceList<T> extends StatelessWidget {
  const NcChoiceList({
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.keyPrefix,
    super.key,
  });

  final List<NcChoice<T>> choices;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// Préfixe des clés de chaque ligne (`préfixe-valeur`), pour les tests.
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        for (final choice in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: NcSpacing.sm),
            child: Semantics(
              selected: choice.value == selected,
              button: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ncRadius),
                  boxShadow: choice.value == selected ? null : ncCardShadow,
                ),
                child: Material(
                // Carte blanche ombrée ; teal clair et bordure teal une fois choisie.
                color: choice.value == selected ? scheme.primaryContainer : NcColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ncRadius),
                  side: choice.value == selected ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
                ),
                child: InkWell(
                  key: keyPrefix == null ? null : ValueKey<String>('$keyPrefix-${choice.value}'),
                  borderRadius: BorderRadius.circular(ncRadius),
                  onTap: () => onSelected(choice.value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: NcSpacing.touchTarget),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: NcSpacing.md, vertical: NcSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          if (choice.icon != null) ...<Widget>[
                            NcIconBubble(
                              icon: choice.icon!,
                              size: 40,
                              background: choice.value == selected ? NcColors.card : NcColors.primarySoft,
                            ),
                            const SizedBox(width: NcSpacing.sm + 4),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  choice.label,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: choice.subtitle == null ? null : FontWeight.w700,
                                  ),
                                ),
                                if (choice.subtitle != null)
                                  Text(
                                    choice.subtitle!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NcColors.textMuted),
                                  ),
                                if (choice.warning != null)
                                  Text(
                                    choice.warning!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: NcColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            choice.value == selected ? Icons.check_circle : Icons.circle_outlined,
                            color: choice.value == selected ? scheme.primary : scheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ligne d'une liste ou entrée de menu : titre, précision, et une flèche qui suit le sens de lecture.
class NcListCard extends StatelessWidget {
  const NcListCard({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.badge,
    this.highlighted = false,
    this.iconTone = NcBadgeTone.brand,
    super.key,
  });

  /// Ton de la pastille d'icône : celui de l'état, pour une réservation ou une mission.
  final NcBadgeTone iconTone;

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Met la carte en avant : pour l'action principale d'un écran d'accueil.
  final bool highlighted;

  /// Petit élément affiché sous le texte (état, étiquette).
  final Widget? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.sm + 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ncRadius),
          boxShadow: highlighted ? null : ncCardShadow,
        ),
        child: Material(
        // Carte blanche ombrée ; ce qui attend une réponse ressort en teal clair.
        color: highlighted ? NcColors.primarySoft : NcColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ncRadius),
          side: highlighted ? const BorderSide(color: NcColors.primary, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(ncRadius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NcSpacing.touchTarget + 16),
            child: Padding(
              padding: const EdgeInsets.all(NcSpacing.md),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    NcIconBubble(
                      icon: icon!,
                      background: highlighted ? NcColors.card : ncToneColors(iconTone).$1,
                      foreground: ncToneColors(iconTone).$2,
                    ),
                    const SizedBox(width: NcSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: textTheme.titleMedium),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: NcSpacing.xs),
                          Text(subtitle!, style: textTheme.bodyMedium),
                        ],
                        if (badge != null) ...<Widget>[const SizedBox(height: NcSpacing.sm), badge!],
                      ],
                    ),
                  ),
                  // Icône directionnelle : elle s'inverse en arabe.
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                    textDirection: Directionality.of(context),
                  ),
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
