import 'package:flutter/material.dart';

import 'nc_spacing.dart';

/// Champ de saisie avec son libellé au-dessus, toujours visible.
///
/// Un libellé posé dans le champ disparaît dès qu'on tape et se lit mal avec une grande taille
/// de texte : tous les formulaires passent par ce composant, pour la même présentation partout.
/// Le libellé est exclu de la lecture d'écran car le champ le porte déjà (`semanticsLabel`).
class NcLabeledField extends StatelessWidget {
  const NcLabeledField({required this.label, required this.child, super.key});

  final String label;

  /// Le champ lui-même, sans `labelText` dans sa décoration.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              // Même encre que les titres de partie : dans un formulaire, ils jouent le même rôle.
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: NcSpacing.sm),
        Semantics(label: label, child: child),
      ],
    );
  }
}
