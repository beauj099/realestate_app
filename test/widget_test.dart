import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realestate_app/main.dart';

void main() {
  testWidgets('App renders login screen when unauthenticated', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sign In'), findsWidgets);
  });
}
