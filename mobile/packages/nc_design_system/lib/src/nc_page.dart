import 'package:flutter/material.dart';

import 'nc_spacing.dart';

/// Gabarit d'un écran : titre, texte d'aide, contenu défilant, actions collées en bas.
///
/// Le contenu défile pour rester utilisable avec une très grande taille de texte,
/// et les marges suivent le sens de lecture (droite à gauche en arabe).
class NcPage extends StatelessWidget {
  const NcPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const <Widget>[],
    this.appBar,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Boutons affichés en bas de l'écran, l'action principale en premier.
  final List<Widget> actions;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: NcSpacing.maxContentWidth),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      NcSpacing.lg,
                      NcSpacing.lg,
                      NcSpacing.lg,
                      NcSpacing.md,
                    ),
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(title, style: textTheme.headlineMedium),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: NcSpacing.sm),
                        Text(subtitle!, style: textTheme.bodyLarge),
                      ],
                      const SizedBox(height: NcSpacing.lg),
                      ...children,
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      NcSpacing.lg,
                      NcSpacing.sm,
                      NcSpacing.lg,
                      NcSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final (index, action) in actions.indexed) ...<Widget>[
                          if (index > 0) const SizedBox(height: NcSpacing.sm),
                          action,
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
