import 'package:flutter/material.dart';

import 'nc_colors.dart';

/// Logo Nador Care (piste C « Maison-pouls », 2026-11-24) : un toit au-dessus d'un tracé de
/// pouls, dans un carré arrondi comme l'icône de l'application, puis le nom. Même géométrie que
/// `docs/marque/icone-patient.svg` (grille de 64).
class NcLogo extends StatelessWidget {
  const NcLogo({this.name, this.size = 56, this.pro = false, super.key});

  /// Nom affiché à côté du symbole (« Nador Care », « Nador Care Pro ») ; sans nom, le symbole seul.
  final String? name;
  final double size;

  /// Couleurs de l'application soignant : fond teal profond, pouls orange clair.
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(pro: pro)),
    );

    if (name == null) {
      // Symbole seul : décoratif, le nom est dit ailleurs sur l'écran.
      return ExcludeSemantics(child: mark);
    }

    // « Nador » en teal profond, le reste en teal : comme sur le site et le back-office.
    final parts = name!.split(' ');
    final first = parts.first;
    final rest = parts.length > 1 ? ' ${parts.sublist(1).join(' ')}' : '';
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontSize: size * 0.5,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1,
      color: NcColors.primaryDeep,
    );

    return Semantics(
      label: name,
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          mark,
          SizedBox(width: size * 0.25),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: first,
                style: style,
                children: <TextSpan>[TextSpan(text: rest, style: style?.copyWith(color: NcColors.primary))],
              ),
              // Le nom de la marque s'écrit en lettres latines, de gauche à droite, même en arabe.
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.pro});

  final bool pro;

  static const List<Offset> _roof = <Offset>[Offset(13, 30), Offset(32, 14.5), Offset(51, 30)];
  static const List<Offset> _pulse = <Offset>[
    Offset(13, 42),
    Offset(22.5, 42),
    Offset(26.2, 35.5),
    Offset(31, 49.5),
    Offset(35.8, 27.5),
    Offset(39.5, 42),
    Offset(51, 42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 64;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(15 * unit)),
      Paint()..color = pro ? NcColors.primaryDeep : NcColors.primary,
    );

    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width < 40 ? 6 : 5) * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path line(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx * unit, points.first.dy * unit);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * unit, point.dy * unit);
      }
      return path;
    }

    canvas
      ..drawPath(line(_roof), stroke(NcColors.card))
      ..drawPath(line(_pulse), stroke(pro ? NcColors.accentLight : NcColors.card));
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => oldDelegate.pro != pro;
}
