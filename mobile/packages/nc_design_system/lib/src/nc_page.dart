import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nc_spacing.dart';
import 'nc_theme.dart';

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
    this.onRefresh,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Boutons affichés en bas de l'écran, l'action principale en premier.
  final List<Widget> actions;
  final PreferredSizeWidget? appBar;

  /// Si renseigné, tirer l'écran vers le bas le recharge.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final surface = theme.scaffoldBackgroundColor;

    final Widget list = ListView(
      // Toujours défilant, pour que le geste de rechargement marche sur un écran court.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(NcSpacing.lg, NcSpacing.lg, NcSpacing.lg, NcSpacing.lg),
      children: <Widget>[
        Semantics(header: true, child: Text(title, style: textTheme.headlineMedium)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: NcSpacing.sm),
          Text(subtitle!, style: textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: NcSpacing.lg),
        ...children,
      ],
    );

    // Les écrans sans barre de titre règlent eux-mêmes les barres du système.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: NcTheme.overlayStyle(theme.colorScheme),
      child: Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: NcSpacing.maxContentWidth),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list),
                        ),
                        // Fondu : le contenu qui passe sous les actions s'estompe au lieu d'être coupé net.
                        if (actions.isNotEmpty)
                          PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 0,
                            height: NcSpacing.lg,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: <Color>[surface.withValues(alpha: 0), surface],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
      ),
    );
  }
}
