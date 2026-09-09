import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/core/widgets/custom_card.dart';

void main() {
  testWidgets('CustomCard renders child widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomCard(child: const Text('Card Content'))),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });

  testWidgets('CustomCard is tappable when onTap provided', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomCard(
            onTap: () => tapped = true,
            child: const Text('Tappable'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tappable'));
    expect(tapped, true);
  });
}
