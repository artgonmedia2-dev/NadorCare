import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Signature recueillie : l'image et le nom de la personne qui a signé.
typedef CollectedSignature = ({Uint8List png, String signedByName});

/// Transforme les traits en image PNG. L'interface permet de s'en passer dans les tests.
abstract interface class SignatureEncoder {
  Future<Uint8List> encode(List<List<Offset>> strokes, Size size);
}

class PngSignatureEncoder implements SignatureEncoder {
  const PngSignatureEncoder();

  @override
  Future<Uint8List> encode(List<List<Offset>> strokes, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawRect(Offset.zero & size, Paint()..color = Colors.white);
    paintStrokes(canvas, strokes, Colors.black);

    final image = await recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return data!.buffer.asUint8List();
  }
}

final signatureEncoderProvider = Provider<SignatureEncoder>((ref) => const PngSignatureEncoder());

void paintStrokes(Canvas canvas, List<List<Offset>> strokes, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  for (final stroke in strokes) {
    if (stroke.length == 1) {
      canvas.drawPoints(ui.PointMode.points, stroke, paint);
      continue;
    }
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (final point in stroke.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }
}

/// Écran de signature : le patient, ou un proche présent, signe avec le doigt.
/// Renvoie un [CollectedSignature], ou rien si l'on revient en arrière.
class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({this.initialName, super.key});

  /// Nom proposé : celui du patient.
  final String? initialName;

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName ?? '');
  final List<List<Offset>> _strokes = <List<Offset>>[];
  Size _padSize = Size.zero;
  String? _nameError;
  String? _padError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    final name = _name.text.trim();

    setState(() {
      _nameError = name.length < 2 ? l10n.fieldRequired : null;
      _padError = _strokes.isEmpty ? l10n.signatureEmpty : null;
    });
    if (_nameError != null || _padError != null) {
      return;
    }

    setState(() => _busy = true);
    final png = await ref.read(signatureEncoderProvider).encode(_strokes, _padSize);
    if (mounted) {
      Navigator.of(context).pop<CollectedSignature>((png: png, signedByName: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportSignatureTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NcSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('signature-name'),
                controller: _name,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.signatureName, errorText: _nameError),
              ),
              Text(l10n.signatureHelp),
              const SizedBox(height: NcSpacing.sm),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _padSize = constraints.biggest;

                    // Le tracé se fait toujours sur fond blanc, à l'encre noire, comme sur papier.
                    return GestureDetector(
                      key: const ValueKey<String>('signature-pad'),
                      onPanStart: (details) => setState(() {
                        _padError = null;
                        _strokes.add(<Offset>[details.localPosition]);
                      }),
                      onPanUpdate: (details) => setState(() => _strokes.last.add(details.localPosition)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _padError == null ? scheme.outline : scheme.error, width: 2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CustomPaint(painter: _SignaturePainter(_strokes), size: Size.infinite),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_padError != null) ...<Widget>[
                const SizedBox(height: NcSpacing.sm),
                Text(_padError!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: NcSpacing.md),
              NcPrimaryButton(
                key: const ValueKey<String>('signature-confirm'),
                label: l10n.signatureConfirm,
                isLoading: _busy,
                onPressed: _busy ? null : _confirm,
              ),
              const SizedBox(height: NcSpacing.sm),
              NcSecondaryButton(
                key: const ValueKey<String>('signature-clear'),
                label: l10n.signatureClear,
                onPressed: _busy ? null : () => setState(_strokes.clear),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) => paintStrokes(canvas, strokes, Colors.black);

  // La liste est modifiée sur place : on redessine à chaque trait.
  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
