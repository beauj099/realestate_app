import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/themes.dart';

/// The ink colours offered for a drawn signature.
const signatureInks = <(String, Color)>[
  ('Black', Color(0xFF111111)),
  ('Dark blue', Color(0xFF16265C)),
  ('Blue', Color(0xFF1F5FC9)),
  ('Green', Color(0xFF1E6B3A)),
  ('Burgundy', Color(0xFF7A1F2B)),
];

/// The default ink: the dark blue of a fountain pen.
const defaultSignatureInk = Color(0xFF16265C);

/// Opens a full-screen box to sign in with a finger. Returns the path of a
/// PNG of the signature (cropped to the strokes, transparent background), or
/// null when cancelled. Full screen, so drawing never scrolls the page.
Future<String?> showSignaturePad(BuildContext context, RealEstateTheme theme) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SignaturePadScreen(theme: theme),
      ),
    );

class _Stroke {
  final Color colour;
  final List<Offset> points = [];

  _Stroke(this.colour);
}

class _SignaturePadScreen extends StatefulWidget {
  final RealEstateTheme theme;

  const _SignaturePadScreen({required this.theme});

  @override
  State<_SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<_SignaturePadScreen> {
  final _strokes = <_Stroke>[];
  Color _ink = defaultSignatureInk;
  bool _saving = false;

  static const _width = 3.2;

  void _start(Offset at) =>
      setState(() => _strokes.add(_Stroke(_ink)..points.add(at)));

  void _extend(Offset at) => setState(() => _strokes.last.points.add(at));

  /// The strokes as a PNG, cropped to them with a small margin, drawn at 3x
  /// so it prints sharply.
  Future<Uint8List?> _png() async {
    final points = [for (final s in _strokes) ...s.points];
    if (points.isEmpty) return null;
    const margin = 12.0, scale = 3.0;
    var left = points.first.dx, right = left;
    var top = points.first.dy, bottom = top;
    for (final p in points) {
      if (p.dx < left) left = p.dx;
      if (p.dx > right) right = p.dx;
      if (p.dy < top) top = p.dy;
      if (p.dy > bottom) bottom = p.dy;
    }
    final bounds = Rect.fromLTRB(left, top, right, bottom).inflate(margin);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top);
    _SignaturePainter(_strokes, _width).paint(canvas, bounds.size);
    final image = await recorder.endRecording().toImage(
      (bounds.width * scale).ceil(),
      (bounds.height * scale).ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final bytes = await _png();
    if (bytes == null) {
      setState(() => _saving = false);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/signature-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    if (mounted) Navigator.of(context).pop(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final empty = _strokes.isEmpty;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Draw your signature'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo),
            onPressed: empty ? null : () => setState(_strokes.removeLast),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: empty ? null : () => setState(_strokes.clear),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign with your finger in the box. Turning the phone sideways '
                'gives you more room.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.borderLight),
                    ),
                    child: Stack(
                      children: [
                        // A signing line, as on paper.
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 48,
                          child: Container(
                            height: 1,
                            color: const Color(0xFFBFC6CF),
                          ),
                        ),
                        if (empty)
                          Center(
                            child: Text(
                              'Sign here',
                              style: textTheme.titleMedium?.copyWith(
                                color: const Color(0xFFBFC6CF),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: GestureDetector(
                            key: const ValueKey('signature-area'),
                            onPanStart: (d) => _start(d.localPosition),
                            onPanUpdate: (d) => _extend(d.localPosition),
                            child: CustomPaint(
                              painter: _SignaturePainter(_strokes, _width),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final (name, colour) in signatureInks)
                    Tooltip(
                      message: name,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _ink = colour),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colour,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _ink == colour
                                  ? theme.primaryColor
                                  : Colors.white,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: _ink == colour
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
              ),
              onPressed: empty || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Use this signature'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<_Stroke> strokes;
  final double width;

  _SignaturePainter(this.strokes, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.colour
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      if (s.points.length == 1) {
        canvas.drawCircle(
          s.points.first,
          width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      // Smooth: a curve through the midpoints between touch points.
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length - 1; i++) {
        final p = s.points[i], next = s.points[i + 1];
        path.quadraticBezierTo(
          p.dx,
          p.dy,
          (p.dx + next.dx) / 2,
          (p.dy + next.dy) / 2,
        );
      }
      path.lineTo(s.points.last.dx, s.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  // Strokes grow in place, so always repaint.
  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
