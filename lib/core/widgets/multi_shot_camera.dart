import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// A photo taken with [MultiShotCamera], ready to upload.
typedef CameraShot = ({String path, Uint8List bytes, String filename});

/// Opens the in-app camera, which stays open for as many photos as the agent
/// wants (up to [limit]), and returns them all when they tap Done, close it
/// or go back. Null when the phone's camera cannot be used here (no camera,
/// permission refused), so the caller can fall back to the system camera.
Future<List<CameraShot>?> takePhotos(
  BuildContext context, {
  required int limit,
}) async {
  final List<CameraDescription> cameras;
  try {
    cameras = await availableCameras();
  } catch (_) {
    return null;
  }
  final back = cameras
      .where((c) => c.lensDirection == CameraLensDirection.back)
      .followedBy(cameras)
      .firstOrNull;
  if (back == null || !context.mounted) return null;
  return Navigator.of(context, rootNavigator: true).push<List<CameraShot>?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MultiShotCamera(camera: back, limit: limit),
    ),
  );
}

/// Full-screen camera: shutter, flash, how many are taken, the last photo,
/// and Done. Each photo is saved at 1600 px / JPEG 80 (as picked photos are)
/// while the agent carries on shooting.
class MultiShotCamera extends StatefulWidget {
  final CameraDescription camera;
  final int limit;

  const MultiShotCamera({super.key, required this.camera, required this.limit});

  @override
  State<MultiShotCamera> createState() => _MultiShotCameraState();
}

class _MultiShotCameraState extends State<MultiShotCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;
  bool _finishing = false;
  bool _flashVisible = false;
  FlashMode _flash = FlashMode.auto;

  /// Shots in the order taken; each resolves once it is saved small.
  final _shots = <Future<CameraShot?>>[];
  Uint8List? _lastThumb;

  int get _taken => _shots.length;
  bool get _full => _taken >= widget.limit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // The camera is released while the app is in the background, as the
  // platforms require, and opened again on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      c?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && c == null) {
      _start();
    }
  }

  Future<void> _start() async {
    final c = CameraController(
      widget.camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await c.initialize();
      await c.setFlashMode(_flash);
    } on CameraException catch (e) {
      await c.dispose();
      if (mounted) {
        setState(
          () => _error = e.code.contains('Denied')
              ? 'RealWorth may not use the camera. Allow it in the phone '
                    "Settings under RealWorth's permissions."
              : "The camera couldn't be opened (${e.description ?? e.code}).",
        );
      }
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() {
      _controller = c;
      _error = null;
    });
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing || _full) return;
    setState(() {
      _capturing = true;
      _flashVisible = true;
    });
    try {
      final file = await c.takePicture();
      final raw = await file.readAsBytes();
      final dir = await getTemporaryDirectory();
      final n = DateTime.now().microsecondsSinceEpoch;
      final out = '${dir.path}/photo-$n.jpg';
      _shots.add(
        compute(_shrink, (raw, out)).then<CameraShot?>(
          (bytes) => (path: out, bytes: bytes, filename: 'photo-$n.jpg'),
          onError: (Object _) => null,
        ),
      );
      _lastThumb = raw;
    } on CameraException catch (e) {
      debugPrint('Camera: photo not taken: $e');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _flashVisible = false);
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final next = switch (_flash) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    try {
      await _controller?.setFlashMode(next);
      setState(() => _flash = next);
    } on CameraException catch (_) {}
  }

  /// Done, close and back all keep the photos taken.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final shots = [for (final s in await Future.wait(_shots)) ?s];
    if (mounted) Navigator.of(context).pop(shots);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : c == null || !c.value.isInitialized
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CameraPreview(c),
                ),
              ),
              // A brief white blink: the photo was taken.
              if (_flashVisible)
                Positioned.fill(
                  child: IgnorePointer(child: Container(color: Colors.white54)),
                ),
              Positioned(top: 0, left: 0, right: 0, child: _topBar()),
              Positioned(bottom: 0, left: 0, right: 0, child: _bottomBar()),
              if (_finishing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _taken == 1
                              ? 'Adding the photo…'
                              : 'Adding $_taken photos…',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _finish,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _full
                  ? '$_taken of ${widget.limit} – that is the most'
                  : '$_taken of ${widget.limit}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(switch (_flash) {
              FlashMode.always => Icons.flash_on,
              FlashMode.off => Icons.flash_off,
              _ => Icons.flash_auto,
            }, color: Colors.white),
            onPressed: _controller == null ? null : _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final thumb = _lastThumb;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: Colors.black45,
      child: Row(
        children: [
          // The last photo, with how many so far.
          SizedBox(
            width: 64,
            height: 64,
            child: thumb == null
                ? null
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          thumb,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          cacheWidth: 192,
                          gaplessPlayback: true,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Text(
                            '$_taken',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _shoot,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _full || _capturing
                          ? Colors.white38
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white24,
                padding: EdgeInsets.zero,
              ),
              onPressed: _taken == 0 ? null : _finish,
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns the camera's photo upright and saves it at most 1600 px on its
/// longest side as JPEG 80 at [args].$2; runs off the UI thread.
Uint8List _shrink((Uint8List, String) args) {
  final (raw, out) = args;
  var photo = img.decodeJpg(raw);
  if (photo == null) {
    File(out).writeAsBytesSync(raw);
    return raw;
  }
  photo = img.bakeOrientation(photo);
  const longest = 1600;
  if (photo.width > longest || photo.height > longest) {
    photo = photo.width >= photo.height
        ? img.copyResize(photo, width: longest)
        : img.copyResize(photo, height: longest);
  }
  final bytes = img.encodeJpg(photo, quality: 80);
  File(out).writeAsBytesSync(bytes);
  return bytes;
}
