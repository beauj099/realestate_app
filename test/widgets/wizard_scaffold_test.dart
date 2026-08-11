import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/core/widgets/wizard_scaffold.dart';

void main() {
  testWidgets('WizardScaffold renders title and description', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: WizardScaffold(
            title: 'Test Step',
            description: 'Test Description',
            children: [const Text('Body Content')],
          ),
        ),
      ),
    );

    expect(find.text('Test Step'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('Body Content'), findsOneWidget);
  });
}
