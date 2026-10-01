import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Lets the agent place a photo in a circle (drag to move, pinch to zoom) and
/// returns the square JPEG it frames ([outputSide] px), or null when they
/// cancel. Used for the profile photo, which the app and the report show
/// round: a round frame on the whole photo often cut the head off.
Future<String?> cropToCircle(
  BuildContext context, {
  required String path,
  int outputSide = 800,
}) {
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CircleCropScreen(path: path, outputSide: outputSide),
    ),
  );
}

class CircleCropScreen extends StatefulWidget {
  final String path;
  final int outputSide;

  const CircleCropScreen({
    super.key,
    required this.path,
    required this.outputSide,
  });

  @override
  State<CircleCropScreen> createState() => _CircleCropScreenState();
}

class _CircleCropScreenState extends State<CircleCropScreen> {
  final _transform = TransformationController();

  /// The photo, upright, and its size in pixels.
  Uint8List? _bytes;
  Size? _size;
  bool _saving = false;

  /// The circle's diameter on screen, set by the layout.
  double? _side;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final raw = await File(widget.path).readAsBytes();
    final upright = await compute(_upright, raw);
    if (!mounted) return;
    if (upright == null) {
      // Not readable here: keep the photo as it is.
      Navigator.of(context).pop(widget.path);
      return;
    }
    setState(() {
      _bytes = upright.$1;
      _size = Size(upright.$2.toDouble(), upright.$3.toDouble());
    });
  }

  /// How much the photo is scaled so its shorter side fills the circle.
  double _cover(double side) => side / _size!.shortestSide;

  /// The photo starts centred across, and for a portrait near the top, where
  /// the face usually is.
  void _place(double side) {
    if (_side == side) return;
    _side = side;
    final k = _cover(side);
    final w = _size!.width * k, h = _size!.height * k;
    final dy = h > w ? -(h * 0.04) : -(h - side) / 2;
    // Set in place, during layout: notifying would rebuild mid-build.
    _transform.value.setFrom(Matrix4.translationValues(-(w - side) / 2, dy, 0));
  }

  Future<void> _done() async {
    final side = _side, size = _size, bytes = _bytes;
    if (side == null || size == null || bytes == null) return;
    setState(() => _saving = true);
    final m = _transform.value;
    final scale = m.getMaxScaleOnAxis();
    final k = _cover(side) * scale;
    // The circle's square, in the photo's own pixels.
    final x = (-m.storage[12] / k).round();
    final y = (-m.storage[13] / k).round();
    final s = (side / k).round();
    final dir = await getTemporaryDirectory();
    final out =
        '${dir.path}/profile-${DateTime.now().microsecondsSinceEpoch}.jpg';
    await compute(_crop, (bytes, x, y, s, widget.outputSide, out));
    if (mounted) Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final size = _size, bytes = _bytes;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Fit your photo'),
        actions: [
          TextButton(
            onPressed: size == null || _saving ? null : _done,
            child: Text(
              'Use photo',
              style: TextStyle(
                color: size == null ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: size == null || bytes == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, box) {
                // Room left below for the hint and the saving spinner.
                final side = [
                  box.maxWidth - 32,
                  box.maxHeight - 180,
                  600.0,
                ].reduce((a, b) => a < b ? a : b).clamp(120.0, 600.0);
                _place(side);
                final k = _cover(side);
                return Column(
                  children: [
                    const Spacer(),
                    Center(
                      child: SizedBox.square(
                        dimension: side,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            InteractiveViewer(
                              transformationController: _transform,
                              constrained: false,
                              minScale: 1,
                              maxScale: 6,
                              clipBehavior: Clip.none,
                              child: Image.memory(
                                bytes,
                                width: size.width * k,
                                height: size.height * k,
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                              ),
                            ),
                            // Everything outside the circle is dimmed.
                            Positioned(
                              left: -box.maxWidth,
                              top: -box.maxHeight,
                              width: side + 2 * box.maxWidth,
                              height: side + 2 * box.maxHeight,
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _CircleMask(
                                    hole: Rect.fromLTWH(
                                      box.maxWidth,
                                      box.maxHeight,
                                      side,
                                      side,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Text(
                        'Drag to move, pinch to zoom. Keep your face and '
                        'shoulders inside the circle.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _CircleMask extends CustomPainter {
  final Rect hole;

  const _CircleMask({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(hole);
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    canvas.drawOval(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white70,
    );
  }

  @override
  bool shouldRepaint(_CircleMask old) => old.hole != hole;
}

/// The photo turned upright (as phones show it), with its width and height.
(Uint8List, int, int)? _upright(Uint8List raw) {
  try {
    final photo = img.decodeImage(raw);
    if (photo == null) return null;
    final upright = img.bakeOrientation(photo);
    return (img.encodeJpg(upright, quality: 92), upright.width, upright.height);
  } catch (_) {
    return null;
  }
}

/// Cuts the square at (x, y) of side s, scales it to [side] px and saves it.
void _crop((Uint8List, int, int, int, int, String) args) {
  final (bytes, x, y, s, side, out) = args;
  final photo = img.decodeJpg(bytes)!;
  final cx = x.clamp(0, photo.width - 1);
  final cy = y.clamp(0, photo.height - 1);
  final cs = s.clamp(1, (photo.width - cx).clamp(1, photo.height - cy));
  final square = img.copyCrop(photo, x: cx, y: cy, width: cs, height: cs);
  final sized = cs > side
      ? img.copyResize(square, width: side, height: side)
      : square;
  File(out).writeAsBytesSync(img.encodeJpg(sized, quality: 90));
}
