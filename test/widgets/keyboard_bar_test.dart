import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/widgets/app_snack.dart';
import 'package:realworth/core/widgets/keyboard_bar.dart';

void main() {
  test('messages stay long enough to read, within limits', () {
    expect(readingTime('Saved'), const Duration(seconds: 3));
    expect(readingTime(List.filled(8, 'word').join(' ')).inMilliseconds, 3500);
    expect(
      readingTime(List.filled(200, 'word').join(' ')),
      const Duration(seconds: 5),
    );
  });

  testWidgets('the bar above the keyboard steps through the fields', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    // An open keyboard.
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardBar(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: first),
              ElevatedButton(onPressed: () {}, child: const Text('Chip')),
              TextField(focusNode: second),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Done'), findsNothing);

    first.requestFocus();
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('More below'), findsOneWidget);

    // Next skips the button and lands on the next field.
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);
    expect(find.text('More below'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(second.hasFocus, isFalse);
    expect(find.text('Done'), findsNothing);
  });
}
