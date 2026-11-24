import 'package:flutter/material.dart';

import 'nc_colors.dart';
import 'nc_spacing.dart';

/// Rayon commun des cartes et des champs.
const double ncRadius = 18;

/// Ombre des cartes blanches : elle les détache du fond gris, à la place d'une bordure.
const List<BoxShadow> ncCardShadow = <BoxShadow>[
  BoxShadow(color: NcColors.shadow, blurRadius: 16, offset: Offset(0, 3)),
];

/// Couleurs d'un ton (fond clair, premier plan), partagées par les étiquettes et les pastilles.
(Color, Color) ncToneColors(NcBadgeTone tone) => switch (tone) {
  NcBadgeTone.neutral => (NcColors.muted, NcColors.textMuted),
  NcBadgeTone.success => (NcColors.successSoft, NcColors.success),
  NcBadgeTone.progress => (NcColors.warningSoft, NcColors.warning),
  NcBadgeTone.danger => (NcColors.dangerSoft, NcColors.danger),
  NcBadgeTone.info => (NcColors.infoSoft, NcColors.info),
  NcBadgeTone.brand => (NcColors.primarySoft, NcColors.primaryStrong),
};

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

  /// Couleur de fond ; par défaut, une carte blanche ombrée.
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        // Une carte colorée (choix sélectionné) n'a pas besoin d'ombre : sa couleur la distingue.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ncRadius),
          boxShadow: color == null ? ncCardShadow : null,
        ),
        child: Material(
          color: color ?? NcColors.card,
          borderRadius: BorderRadius.circular(ncRadius),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Titre d'une partie d'écran, avec un lien « Tout voir » facultatif.
/// Annoncé comme un titre par les lecteurs d'écran.
class NcSectionTitle extends StatelessWidget {
  const NcSectionTitle(this.title, {this.trailing, this.actionLabel, this.onAction, this.actionKey, super.key});

  final String title;

  /// Élément placé en fin de ligne (un compteur, par exemple).
  final Widget? trailing;

  /// Lien en fin de ligne (« Tout voir ») ; affiché si [onAction] est renseigné.
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: NcSpacing.xs, bottom: NcSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, color: NcColors.text)),
            ),
          ),
          ?trailing,
          if (onAction != null && actionLabel != null)
            TextButton(
              key: actionKey,
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: NcSpacing.sm),
              ),
              child: Text(actionLabel!),
            ),
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
        color: NcColors.card.withValues(alpha: 0.6),
        border: Border.all(color: NcColors.cardEdge),
        borderRadius: BorderRadius.circular(ncRadius),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: NcColors.muted, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: NcSpacing.md),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

/// Tons des étiquettes, les mêmes que le back-office : neutre, succès, en attente (ambre),
/// danger, information (en route), marque (affectée, confirmée par l'agence).
enum NcBadgeTone { neutral, success, progress, danger, info, brand }

/// Étiquette d'état : une icône et un texte, jamais la couleur seule.
class NcStatusBadge extends StatelessWidget {
  const NcStatusBadge({required this.label, required this.icon, this.tone = NcBadgeTone.neutral, super.key});

  final String label;
  final IconData icon;
  final NcBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (Color background, Color foreground) = ncToneColors(tone);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      // Largeur de son contenu : plusieurs étiquettes tiennent sur une ligne dans un `Wrap`.
      widthFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: NcSpacing.sm + 2, vertical: NcSpacing.xs + 2),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
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
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: NcColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, color: NcColors.primaryStrong, size: 22),
          ),
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
          // Un segment par étape : les étapes faites et l'étape en cours en teal.
          ExcludeSemantics(
            child: Row(
              children: <Widget>[
                for (var step = 1; step <= total; step++) ...<Widget>[
                  if (step > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: step <= current ? NcColors.primary : NcColors.cardEdge,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
