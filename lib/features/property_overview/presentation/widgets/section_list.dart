import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';

// Building blocks for the settings-style section lists shared by Property
// Features and the room screen: a section title with a small Add action, a
// card of divider-separated rows, and the tinted icon those rows lead with.

/// Section title with an optional count/detail and a compact Add action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? detail;
  final VoidCallback? onAdd;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const SectionHeader({
    super.key,
    required this.title,
    required this.theme,
    required this.textTheme,
    this.detail,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 8),
            Text(
              detail!,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const Spacer(),
          if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add, size: 18, color: theme.primaryColor),
              label: Text(
                'Add',
                style: textTheme.labelLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      ),
    );
  }
}

/// One card holding divider-separated rows, or a quiet line when empty.
class RowsCard extends StatelessWidget {
  final List<Widget> children;
  final String? emptyText;
  final RealEstateTheme theme;

  const RowsCard({
    super.key,
    required this.children,
    required this.theme,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.toThemeData().textTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      child: children.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text(
                emptyText ?? '',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: theme.borderLight.withValues(alpha: 0.7),
                    ),
                  children[i],
                ],
              ],
            ),
    );
  }
}

/// Leading glyph in a soft brand-tinted circle, shared by every row.
class RowIcon extends StatelessWidget {
  final IconData icon;
  final RealEstateTheme theme;
  final bool muted;

  const RowIcon({
    super.key,
    required this.icon,
    required this.theme,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: muted
            ? theme.borderLight.withValues(alpha: 0.5)
            : theme.primaryColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 19,
        color: muted ? theme.textSecondary : theme.primaryColor,
      ),
    );
  }
}
