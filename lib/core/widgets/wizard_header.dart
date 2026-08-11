import 'package:flutter/material.dart';

import '../theme/themes.dart';

class WizardHeader extends StatelessWidget {
  final String progressLabel;
  final String title;
  final String? description;
  final RealEstateTheme theme;

  const WizardHeader({
    super.key,
    required this.progressLabel,
    required this.title,
    this.description,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progressLabel.toUpperCase(),
          style: textTheme.labelLarge?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}
