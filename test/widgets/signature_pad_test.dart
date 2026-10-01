import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/theme/themes.dart';
import 'package:realworth/features/settings/presentation/widgets/signature_pad.dart';

void main() {
  testWidgets('drawing enables saving; undo and clear take it away', (
    tester,
  ) async {
    final theme = RealEstateTheme.crimson();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSignaturePad(context, theme),
            child: const Text('Sign'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Sign'));
    await tester.pumpAndSettle();

    FilledButton save() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Use this signature'),
    );
    expect(save().onPressed, isNull, reason: 'nothing drawn yet');

    // A stroke across the signing box.
    final box = tester.getCenter(find.byKey(const ValueKey('signature-area')));
    await tester.dragFrom(box - const Offset(60, 0), const Offset(120, 20));
    await tester.pump();
    expect(save().onPressed, isNotNull);
    expect(find.text('Sign here'), findsNothing);

    // Another ink, another stroke, then undo both.
    await tester.tap(find.byTooltip('Blue'));
    await tester.dragFrom(box, const Offset(40, -10));
    await tester.pump();
    await tester.tap(find.byTooltip('Undo'));
    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect(save().onPressed, isNull);
    expect(find.text('Sign here'), findsOneWidget);
  });
}
