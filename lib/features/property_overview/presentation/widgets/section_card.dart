import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isComplete;
  final VoidCallback? onTap;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isComplete,
    this.onTap,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? theme.completeColor.withValues(alpha: 0.3)
              : theme.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? theme.completeColor.withValues(alpha: 0.1)
                        : theme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isComplete
                        ? theme.completeColor
                        : theme.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // A coloured mark rather than a text pill, so the title keeps
                // the width. Still announced to screen readers.
                Tooltip(
                  message: isComplete ? 'Complete' : 'Required details missing',
                  child: Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 24,
                    color: isComplete
                        ? theme.completeColor
                        : theme.pendingColor,
                    semanticLabel: isComplete ? 'Complete' : 'Incomplete',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: theme.textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
