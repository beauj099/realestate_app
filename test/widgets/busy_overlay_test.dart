import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/core/widgets/busy_overlay.dart';

void main() {
  Widget host({required bool busy, required VoidCallback onTap}) {
    return MaterialApp(
      home: BusyOverlay(
        busy: busy,
        theme: RealEstateTheme.crimson(),
        title: 'Saving Rooms…',
        child: Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: onTap, child: const Text('Save')),
          ),
        ),
      ),
    );
  }

  testWidgets('while busy, taps are blocked and messages rotate', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(host(busy: true, onTap: () => taps++));
    expect(find.text('Saving Rooms…'), findsOneWidget);

    await tester.tap(find.text('Save'), warnIfMissed: false);
    expect(taps, 0);

    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Working on it…'), findsOneWidget);
  });

  testWidgets('when not busy the screen works normally', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(busy: false, onTap: () => taps++));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Save'));
    expect(taps, 1);
  });
}
