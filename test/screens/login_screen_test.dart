import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realworth/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen accepts an email or a username', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const LoginScreen())),
    );

    expect(find.text('Email or username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('LoginScreen offers a password reset', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const LoginScreen())),
    );

    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('LoginScreen has sign-in button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: const LoginScreen())),
    );

    expect(find.text('Sign In'), findsWidgets);
  });
}
