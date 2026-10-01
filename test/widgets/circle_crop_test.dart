import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:realworth/core/widgets/circle_crop.dart';

void main() {
  testWidgets('a portrait is framed square from near the top', (tester) async {
    final dir = Directory.systemTemp.createTempSync('crop');
    addTearDown(() {
      // Windows may still hold the image open; the folder is temporary anyway.
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {}
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );

    // 400 x 800: red top half, blue bottom half.
    final photo = img.Image(width: 400, height: 800);
    img.fillRect(
      photo,
      x1: 0,
      y1: 0,
      x2: 399,
      y2: 399,
      color: img.ColorRgb8(255, 0, 0),
    );
    img.fillRect(
      photo,
      x1: 0,
      y1: 400,
      x2: 399,
      y2: 799,
      color: img.ColorRgb8(0, 0, 255),
    );
    final input = File('${dir.path}/in.jpg')
      ..writeAsBytesSync(img.encodeJpg(photo));

    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await cropToCircle(context, path: input.path),
            child: const Text('go'),
          ),
        ),
      ),
    );
    // Decoding and saving run off the test clock: let real time pass.
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 40 && !done(); i++) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.tap(find.text('go'));
    await until(() => find.byType(InteractiveViewer).evaluate().isNotEmpty);
    await tester.tap(find.text('Use photo'));
    await until(() => result != null);

    expect(result, isNotNull);
    final out = img.decodeJpg(File(result!).readAsBytesSync())!;
    expect(out.width, out.height);
    expect(out.width, 400); // the full width, never enlarged
    // Taken from near the top: mostly the red half.
    final centre = out.getPixel(200, 150);
    expect(centre.r, greaterThan(200));
    expect(centre.b, lessThan(60));
  });
}
