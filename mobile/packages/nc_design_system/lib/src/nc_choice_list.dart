import 'package:flutter/material.dart';

import 'nc_spacing.dart';

/// Une option d'une [NcChoiceList].
class NcChoice<T> {
  const NcChoice({required this.value, required this.label});

  final T value;
  final String label;
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
              child: Material(
                color: choice.value == selected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: keyPrefix == null ? null : ValueKey<String>('$keyPrefix-${choice.value}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(choice.value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: NcSpacing.touchTarget),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: NcSpacing.md, vertical: NcSpacing.sm),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(choice.label, style: Theme.of(context).textTheme.bodyLarge)),
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
    super.key,
  });

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
      padding: const EdgeInsets.only(bottom: NcSpacing.sm),
      child: Material(
        color: highlighted ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NcSpacing.touchTarget + 16),
            child: Padding(
              padding: const EdgeInsets.all(NcSpacing.md),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: scheme.primary, size: 32),
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
    );
  }
}
