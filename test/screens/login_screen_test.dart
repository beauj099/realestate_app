import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders username and password fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const LoginScreen())),
    );

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('LoginScreen has sign-in button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const LoginScreen())),
    );

    expect(find.text('Sign In'), findsWidgets);
  });
}
