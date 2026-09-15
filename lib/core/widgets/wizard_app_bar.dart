import 'package:flutter/material.dart';

import '../theme/themes.dart';

class WizardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double bottomBorderHeight;
  final RealEstateTheme theme;

  const WizardAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.bottomBorderHeight = 1.0,
    required this.theme,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + bottomBorderHeight);

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;

    return AppBar(
      backgroundColor: theme.cardBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: onBack != null
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: theme.textPrimary,
                size: 20,
              ),
              onPressed: onBack,
            )
          : null,
      centerTitle: true,
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      actions: [...?actions],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomBorderHeight),
        child: Container(color: theme.borderLight, height: bottomBorderHeight),
      ),
    );
  }
}
