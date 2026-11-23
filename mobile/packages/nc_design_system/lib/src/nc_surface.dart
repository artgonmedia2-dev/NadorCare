import 'package:flutter/material.dart';

import 'nc_spacing.dart';

/// Rayon commun des cartes, boutons et champs.
const double ncRadius = 14;

/// Carte : regroupe ce qui va ensemble (un justificatif, un jour de l'agenda, un réglage).
///
/// Elle porte un `Material`, pour que les lignes tactiles posées dedans gardent leur retour
/// visuel au toucher.
class NcSurface extends StatelessWidget {
  const NcSurface({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(NcSpacing.md),
    this.margin = const EdgeInsets.only(bottom: NcSpacing.sm),
    super.key,
  });

  final Widget child;

  /// Couleur de fond ; par défaut, le gris clair des cartes.
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: margin,
      child: Material(
        color: color ?? scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(ncRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Titre d'une partie d'écran. Annoncé comme un titre par les lecteurs d'écran.
class NcSectionTitle extends StatelessWidget {
  const NcSectionTitle(this.title, {this.trailing, super.key});

  final String title;

  /// Élément placé en fin de ligne (un compteur, par exemple).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// État vide d'une liste : discret, pour ne pas le confondre avec un message à lire.
class NcEmptyState extends StatelessWidget {
  const NcEmptyState({required this.message, required this.icon, super.key});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: NcSpacing.sm),
      padding: const EdgeInsets.all(NcSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(ncRadius),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: NcSpacing.md),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

enum NcBadgeTone { neutral, success, progress, danger }

/// Étiquette d'état : une icône et un texte, jamais la couleur seule.
class NcStatusBadge extends StatelessWidget {
  const NcStatusBadge({required this.label, required this.icon, this.tone = NcBadgeTone.neutral, super.key});

  final String label;
  final IconData icon;
  final NcBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color background, Color foreground) = switch (tone) {
      NcBadgeTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      NcBadgeTone.success => (scheme.primaryContainer, scheme.onPrimaryContainer),
      // Ambre, comme les avertissements : la couleur tertiaire du thème tire vers le bleu.
      NcBadgeTone.progress => (const Color(0xFFFFF1CC), const Color(0xFF4A3600)),
      NcBadgeTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: NcSpacing.sm + 2, vertical: NcSpacing.xs + 2),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: NcSpacing.xs + 2),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une information en lecture : une icône, un libellé discret, puis la valeur.
class NcInfoRow extends StatelessWidget {
  const NcInfoRow({required this.icon, required this.label, required this.value, super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NcSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: NcSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avancement d'un parcours en plusieurs écrans : « Étape 2 sur 4 » et une barre.
class NcStepIndicator extends StatelessWidget {
  const NcStepIndicator({required this.label, required this.current, required this.total, super.key});

  /// Texte déjà traduit, lu aussi par les lecteurs d'écran.
  final String label;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: NcSpacing.sm),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: current / total,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
