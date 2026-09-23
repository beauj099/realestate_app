import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';
import '../theme/themes.dart';

/// Applies [theme] to [child] as its Material theme, overriding the app-wide
/// agency theme for one screen.
///
/// Screens already paint with their [RealEstateTheme] directly; this covers
/// the widgets that read `Theme.of` instead — progress indicators, text
/// buttons, snackbars, dialogs and sheets opened from the screen.
class ScopedBrandTheme extends ConsumerWidget {
  final RealEstateTheme theme;
  final Widget child;

  const ScopedBrandTheme({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Theme(
      data: isDark ? theme.toDarkThemeData() : theme.toThemeData(),
      child: child,
    );
  }
}
