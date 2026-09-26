import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../data/models/enums/condition_rating.dart';

/// How each condition band is drawn: needs-work reds and orange, a neutral
/// grey for average, then deepening greens.
extension ConditionRatingStyle on ConditionRating {
  Color get scaleColor => switch (this) {
    ConditionRating.toBeRemodeled => const Color(0xFFC62828),
    ConditionRating.toBeRenovated => const Color(0xFFEF6C00),
    ConditionRating.average => const Color(0xFF78818C),
    ConditionRating.good => const Color(0xFF7CB342),
    ConditionRating.veryGood => const Color(0xFF43A047),
    ConditionRating.excellent => const Color(0xFF1B7A3A),
  };

  IconData get scaleIcon => switch (this) {
    ConditionRating.toBeRemodeled => Icons.construction_rounded,
    ConditionRating.toBeRenovated => Icons.format_paint_outlined,
    ConditionRating.average => Icons.sentiment_neutral_rounded,
    ConditionRating.good => Icons.sentiment_satisfied_rounded,
    ConditionRating.veryGood => Icons.sentiment_very_satisfied_rounded,
    ConditionRating.excellent => Icons.workspace_premium_rounded,
  };

  /// Short form that fits under a scale step.
  String get shortLabel => switch (this) {
    ConditionRating.toBeRemodeled => 'Remodel',
    ConditionRating.toBeRenovated => 'Renovate',
    ConditionRating.average => 'Average',
    ConditionRating.good => 'Good',
    ConditionRating.veryGood => 'Very\ngood',
    ConditionRating.excellent => 'Excellent',
  };

  /// One line explaining the band, shown for the selected rating.
  String get description => switch (this) {
    ConditionRating.toBeRemodeled => 'Needs a complete remodel',
    ConditionRating.toBeRenovated => 'Needs renovation work',
    ConditionRating.average => 'Liveable, with normal wear',
    ConditionRating.good => 'Well kept, minor touch-ups only',
    ConditionRating.veryGood => 'Very well kept, nothing to fix',
    ConditionRating.excellent => 'As new, or recently renovated',
  };
}

/// The room's condition as a single-choice rating scale, worst to best from
/// left to right. Each step has its own colour and icon; the chosen one fills
/// with its colour and its meaning is spelled out underneath.
class ConditionScale extends StatelessWidget {
  final ConditionRating? selected;
  final ValueChanged<ConditionRating> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const ConditionScale({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = selected;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final rating in ConditionRating.values)
                Expanded(
                  child: _Step(
                    rating: rating,
                    isSelected: rating == chosen,
                    anySelected: chosen != null,
                    textTheme: textTheme,
                    theme: theme,
                    onTap: () => onChanged(rating),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // The scale's colour ramp, so worst-to-best reads at a glance.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  for (final rating in ConditionRating.values)
                    Expanded(
                      child: Container(
                        color: chosen == null || rating.level <= chosen.level
                            ? rating.scaleColor
                            : rating.scaleColor.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: chosen == null
                ? Text(
                    'Tap one to rate this room',
                    key: const ValueKey('none'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  )
                : Row(
                    key: ValueKey(chosen),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        chosen.scaleIcon,
                        size: 18,
                        color: chosen.scaleColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: chosen.label,
                                style: TextStyle(
                                  color: chosen.scaleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: ' · ${chosen.description}',
                                style: TextStyle(color: theme.textSecondary),
                              ),
                            ],
                          ),
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final ConditionRating rating;
  final bool isSelected;
  final bool anySelected;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _Step({
    required this.rating,
    required this.isSelected,
    required this.anySelected,
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = rating.scaleColor;
    // Once one is chosen, the others step back so the choice stands out.
    final dimmed = anySelected && !isSelected;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${rating.label}: ${rating.description}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : color.withValues(alpha: dimmed ? 0.07 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : color.withValues(alpha: dimmed ? 0.25 : 0.45),
                    width: isSelected ? 2 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  rating.scaleIcon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : color.withValues(alpha: dimmed ? 0.55 : 1),
                ),
              ),
              const SizedBox(height: 6),
              // Scaled down rather than broken mid-word on narrow phones.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  rating.shortLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.15,
                    color: isSelected
                        ? color
                        : (dimmed ? theme.textSecondary : theme.textPrimary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
