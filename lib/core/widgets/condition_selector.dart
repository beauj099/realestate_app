import 'package:flutter/material.dart';

import '../../features/property_overview/data/models/enums/condition_rating.dart';
import '../theme/themes.dart';

/// Six tappable condition bands.
///
/// Replaces the drag-to-set percentage slider: agents were picking a band, not
/// a percentage, and a drag target is fiddly one-handed on site. Tapping a
/// labelled block is one gesture and says in words what was chosen.
class ConditionSelector extends StatelessWidget {
  final ConditionRating? selected;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<ConditionRating> onChanged;

  const ConditionSelector({
    super.key,
    required this.selected,
    required this.theme,
    required this.textTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns keeps every label readable without truncation; three
        // would clip "To be remodeled" on narrow handsets.
        const columns = 2;
        const gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: ConditionRating.values.map((rating) {
            final isSelected = rating == selected;
            final accent = rating.color(
              theme.pendingColor,
              theme.completeColor,
              theme.textSecondary,
            );

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => onChanged(rating),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.12)
                        : theme.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accent : theme.borderLight,
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 18,
                        color: isSelected ? accent : theme.borderLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rating.label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.textPrimary
                                : theme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
