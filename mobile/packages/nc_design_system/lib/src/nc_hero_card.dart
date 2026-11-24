import 'package:flutter/material.dart';

import 'nc_colors.dart';
import 'nc_spacing.dart';

/// Bandeau d'accueil : un surtitre, un titre, un texte, une action, puis quelques engagements
/// cochés. Fond teal dégradé, traversé d'un tracé de pouls discret (refonte du 2026-11-24).
class NcHeroCard extends StatelessWidget {
  const NcHeroCard({
    required this.title,
    required this.action,
    this.eyebrow,
    this.body,
    this.points = const <String>[],
    super.key,
  });

  /// Lieu ou contexte, dans une pastille au-dessus du titre.
  final String? eyebrow;
  final String title;
  final String? body;

  /// L'action principale du bandeau (un `NcPrimaryButton`, en général) : elle passe en blanc.
  final Widget action;

  /// Engagements affichés sous l'action, chacun précédé d'une coche.
  final List<String> points;

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const onHero = NcColors.card;

    // Sur le fond teal, le bouton principal s'inverse : blanc, texte teal.
    final invertedButtons = theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: theme.filledButtonTheme.style?.copyWith(
          backgroundColor: const WidgetStatePropertyAll<Color>(onHero),
          foregroundColor: const WidgetStatePropertyAll<Color>(NcColors.primaryStrong),
          overlayColor: WidgetStatePropertyAll<Color>(NcColors.primary.withValues(alpha: 0.08)),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: NcSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[NcColors.primary, NcColors.primaryDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(color: NcColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: ExcludeSemantics(child: CustomPaint(painter: _PulsePainter()))),
            Padding(
              padding: const EdgeInsets.all(NcSpacing.lg - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (eyebrow != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: NcSpacing.sm + 4, vertical: NcSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: onHero.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.place_outlined, size: 16, color: onHero),
                          const SizedBox(width: NcSpacing.xs + 2),
                          Flexible(
                            child: Text(
                              eyebrow!,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: onHero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NcSpacing.md),
                  ],
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.15, color: onHero),
                    ),
                  ),
                  if (body != null) ...<Widget>[
                    const SizedBox(height: NcSpacing.sm),
                    Text(body!, style: textTheme.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.9))),
                  ],
                  const SizedBox(height: NcSpacing.md + 4),
                  Theme(data: invertedButtons, child: action),
                  if (points.isNotEmpty) ...<Widget>[
                    const SizedBox(height: NcSpacing.md),
                    Wrap(
                      spacing: NcSpacing.md,
                      runSpacing: NcSpacing.xs + 2,
                      children: <Widget>[
                        for (final point in points)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(Icons.check_circle, size: 18, color: onHero),
                              const SizedBox(width: NcSpacing.xs + 2),
                              Text(
                                point,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: onHero,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tracé de pouls, très pâle, dans le haut du bandeau.
class _PulsePainter extends CustomPainter {
  const _PulsePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NcColors.card.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Au pied du bandeau, sous les engagements : il ne traverse aucun texte.
    final y = size.height - 16;
    final w = size.width;
    final path = Path()
      ..moveTo(0, y)
      ..lineTo(w * 0.62, y)
      ..lineTo(w * 0.66, y - 8)
      ..lineTo(w * 0.70, y + 8)
      ..lineTo(w * 0.75, y - 22)
      ..lineTo(w * 0.79, y + 6)
      ..lineTo(w * 0.82, y)
      ..lineTo(w, y);
    canvas.drawPath(path, paint);

    // Deux cercles très clairs, pour donner du relief au coin.
    final glow = Paint()..color = NcColors.card.withValues(alpha: 0.06);
    canvas
      ..drawCircle(Offset(w * 0.95, size.height * 0.95), size.width * 0.32, glow)
      ..drawCircle(Offset(w * 0.98, size.height * 0.98), size.width * 0.18, glow);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => false;
}
