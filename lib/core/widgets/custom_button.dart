import 'package:flutter/material.dart';

import '../theme/themes.dart';

enum ButtonType { primary, outline, text, back }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final ButtonType type;
  final Widget? icon;
  final bool fullWidth;
  final double height;
  final RealEstateTheme? theme;

  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
    this.type = ButtonType.primary,
    this.icon,
    this.fullWidth = false,
    this.height = 54.0,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? RealEstateTheme.crimson();
    final textTheme = theme.toThemeData().textTheme;

    if (type == ButtonType.back) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: theme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: textTheme.bodyLarge?.copyWith(
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (type == ButtonType.text) {
      return TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          text,
          style: textTheme.bodyLarge?.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isOutline = type == ButtonType.outline;

    Widget buttonBody = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: onTap == null
            ? theme.borderLight
            : (isOutline ? Colors.transparent : theme.primaryColor),
        borderRadius: BorderRadius.circular(12.0),
        border: isOutline
            ? Border.all(color: theme.borderLight, width: 1.5)
            : null,
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: textTheme.titleMedium?.copyWith(
                color: isOutline ? theme.textPrimary : theme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (icon != null) ...[const SizedBox(width: 8), icon!],
          ],
        ),
      ),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: buttonBody,
      ),
    );
  }
}
