import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('RegisterScreen renders all input fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const RegisterScreen())),
    );

    expect(find.text('First name *'), findsOneWidget);
    expect(find.text('Last name *'), findsOneWidget);
    expect(find.text('Email address *'), findsOneWidget);
    expect(find.text('Mobile number *'), findsOneWidget);
    expect(find.text('Agency *'), findsOneWidget);
    expect(find.text('Password *'), findsOneWidget);
    expect(find.text('Confirm password *'), findsOneWidget);
  });

  testWidgets('RegisterScreen keeps registration numbers optional', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const RegisterScreen())),
    );

    expect(find.text('Agency reg. no.'), findsOneWidget);
    expect(find.text('Licence / FFC no.'), findsOneWidget);
  });

  testWidgets('RegisterScreen has create account button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const RegisterScreen())),
    );

    expect(find.text('Create Agent Account'), findsWidgets);
    expect(find.text('Register as an agent'), findsNothing);
  });

  testWidgets('RegisterScreen has sign-in link', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const RegisterScreen())),
    );

    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });
}
