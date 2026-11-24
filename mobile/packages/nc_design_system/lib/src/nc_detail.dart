import 'package:flutter/material.dart';

import 'nc_colors.dart';
import 'nc_home.dart';
import 'nc_spacing.dart';
import 'nc_surface.dart';

// Composants des écrans intérieurs (refonte du 2026-11-24) : en-tête de fiche, section en carte,
// suivi en étapes, pastilles de créneaux, bande de jours et message de réussite.

/// En-tête d'une fiche (soin, réservation, mission) : une grande pastille d'icône, le titre,
/// une précision et l'état. Remplace le titre de la page (`NcPage.header`).
class NcDetailHeader extends StatelessWidget {
  const NcDetailHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.tone = NcBadgeTone.brand,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Étiquette d'état, sous le texte.
  final Widget? badge;
  final NcBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (Color background, Color foreground) = ncToneColors(tone);

    return Container(
      margin: const EdgeInsets.only(bottom: NcSpacing.lg),
      padding: const EdgeInsets.all(NcSpacing.md + 2),
      decoration: BoxDecoration(
        color: NcColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ncCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NcIconBubble(icon: icon, size: 56, background: background, foreground: foreground),
          const SizedBox(width: NcSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: NcSpacing.xs),
                  Text(subtitle!, style: textTheme.bodyMedium?.copyWith(color: NcColors.textMuted)),
                ],
                if (badge != null) ...<Widget>[const SizedBox(height: NcSpacing.sm + 2), badge!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section d'un écran, dans une carte blanche : un titre, puis son contenu.
class NcSection extends StatelessWidget {
  const NcSection({required this.title, required this.children, this.icon, this.trailing, super.key});

  final String title;
  final IconData? icon;
  final List<Widget> children;

  /// Élément en fin de ligne du titre (un compteur, par exemple).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: NcSpacing.md),
      padding: const EdgeInsets.fromLTRB(NcSpacing.md, NcSpacing.md, NcSpacing.md, NcSpacing.sm + 4),
      decoration: BoxDecoration(
        color: NcColors.card,
        borderRadius: BorderRadius.circular(ncRadius),
        boxShadow: ncCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                NcIconBubble(icon: icon!, size: 32),
                const SizedBox(width: NcSpacing.sm + 2),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: NcSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

/// Une étape d'un [NcTimeline].
class NcTimelineStep {
  const NcTimelineStep({required this.label, this.caption});

  final String label;
  final String? caption;
}

/// Suivi en étapes, vertical : les étapes passées cochées, l'étape en cours mise en avant,
/// les suivantes en gris.
class NcTimeline extends StatelessWidget {
  const NcTimeline({required this.steps, required this.current, super.key});

  final List<NcTimelineStep> steps;

  /// Index de l'étape en cours (les précédentes sont faites).
  final int current;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        for (final (index, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: 28,
                  child: Column(
                    children: <Widget>[
                      _Dot(done: index < current, active: index == current),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: index < current ? NcColors.primary : NcColors.cardEdge,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: NcSpacing.sm + 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: NcSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          step.label,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: index == current ? FontWeight.w700 : FontWeight.w500,
                            color: index <= current ? NcColors.text : NcColors.textMuted,
                          ),
                        ),
                        if (step.caption != null && index == current)
                          Text(step.caption!, style: textTheme.bodyMedium?.copyWith(color: NcColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? NcColors.primary : (active ? NcColors.primarySoft : NcColors.card),
        border: Border.all(color: done || active ? NcColors.primary : NcColors.cardEdge, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 15, color: NcColors.card)
          : active
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: NcColors.primary, shape: BoxShape.circle),
                  ),
                )
              : null,
    );
  }
}

/// Une pastille d'une [NcChipGrid].
class NcChip<T> {
  const NcChip({required this.value, required this.label});

  final T value;
  final String label;
}

/// Choix d'une valeur parmi des pastilles courtes (des heures), sur [columns] colonnes.
class NcChipGrid<T> extends StatelessWidget {
  const NcChipGrid({
    required this.chips,
    required this.selected,
    required this.onSelected,
    this.columns = 3,
    this.keyPrefix,
    super.key,
  });

  final List<NcChip<T>> chips;
  final T? selected;
  final ValueChanged<T> onSelected;
  final int columns;

  /// Préfixe des clés de chaque pastille (`préfixe-valeur`), pour les tests.
  final String? keyPrefix;

  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;

          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: <Widget>[
              for (final chip in chips)
                SizedBox(
                  width: width,
                  child: Semantics(
                    selected: chip.value == selected,
                    button: true,
                    child: Material(
                      color: chip.value == selected ? NcColors.primary : NcColors.card,
                      shape: StadiumBorder(
                        side: BorderSide(color: chip.value == selected ? NcColors.primary : NcColors.cardEdge),
                      ),
                      child: InkWell(
                        key: keyPrefix == null ? null : ValueKey<String>('$keyPrefix-${chip.value}'),
                        customBorder: const StadiumBorder(),
                        onTap: () => onSelected(chip.value),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 52),
                          child: Center(
                            child: Text(
                              chip.label,
                              textDirection: TextDirection.ltr,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: chip.value == selected ? NcColors.card : NcColors.text,
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
        },
      ),
    );
  }
}

/// Une journée d'une [NcDayStrip] : deux lignes courtes (« lun. » et « 8 »).
class NcDay {
  const NcDay({required this.top, required this.bottom, required this.key, required this.semanticLabel});

  final String top;
  final String bottom;

  /// Clé de la pastille, pour les tests.
  final String key;

  /// Date complète, lue par les lecteurs d'écran.
  final String semanticLabel;
}

/// Bande de jours qui défile à l'horizontale ; la journée choisie est en teal.
class NcDayStrip extends StatelessWidget {
  const NcDayStrip({required this.days, required this.selected, required this.onSelected, super.key});

  final List<NcDay> days;

  /// Index du jour choisi, ou -1 si le jour choisi est hors de la bande.
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final active = index == selected;

          return Semantics(
            selected: active,
            button: true,
            label: day.semanticLabel,
            excludeSemantics: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: active ? null : ncCardShadow,
              ),
              child: Material(
                color: active ? NcColors.primary : NcColors.card,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  key: ValueKey<String>(day.key),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(index),
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          day.top,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: active ? NcColors.card.withValues(alpha: 0.85) : NcColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.bottom,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: active ? NcColors.card : NcColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Message de réussite en tête d'écran : une grande coche, un titre, un texte.
class NcSuccessPanel extends StatelessWidget {
  const NcSuccessPanel({required this.title, this.body, this.icon = Icons.check_rounded, super.key});

  final String title;
  final String? body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: NcSpacing.lg, bottom: NcSpacing.lg),
      child: Column(
        children: <Widget>[
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NcColors.successSoft,
              border: Border.all(color: NcColors.card, width: 8),
              boxShadow: ncCardShadow,
            ),
            child: Icon(icon, size: 72, color: NcColors.success),
          ),
          const SizedBox(height: NcSpacing.lg),
          Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: textTheme.headlineMedium),
          ),
          if (body != null) ...<Widget>[
            const SizedBox(height: NcSpacing.sm),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: NcColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sélecteur à deux ou trois segments, en pilule (« À venir » / « Passées »).
class NcSegmented<T> extends StatelessWidget {
  const NcSegmented({
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.keyPrefix,
    super.key,
  });

  /// Les segments, chacun une valeur et un libellé ([NcChip]).
  final List<NcChip<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Préfixe des clés de chaque segment (`préfixe-valeur`), pour les tests.
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: NcSpacing.md),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NcColors.card,
        borderRadius: BorderRadius.circular(999),
        boxShadow: ncCardShadow,
      ),
      child: Row(
        children: <Widget>[
          for (final segment in segments)
            Expanded(
              child: Semantics(
                selected: segment.value == selected,
                button: true,
                child: Material(
                  color: segment.value == selected ? NcColors.primary : NcColors.card,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    key: keyPrefix == null ? null : ValueKey<String>('$keyPrefix-${segment.value}'),
                    customBorder: const StadiumBorder(),
                    onTap: () => onSelected(segment.value),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: NcSpacing.sm),
                          child: Text(
                            segment.label,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: segment.value == selected ? FontWeight.w700 : FontWeight.w600,
                              color: segment.value == selected ? NcColors.card : NcColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
