import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../data/models/room_score.dart';

/// The agent's overall 0–10 score for a room, set last once they have seen
/// everything in it. Unscored until the slider is first touched, so an
/// untouched room never quietly counts as a 5 in the house score.
class RoomScoreSlider extends StatelessWidget {
  final double? score;
  final ValueChanged<double?> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const RoomScoreSlider({
    super.key,
    required this.score,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final value = score;
    final isSet = value != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSet
              ? theme.primaryColor.withValues(alpha: 0.35)
              : theme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room Score',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSet
                          ? RoomScore.label(value)
                          : 'Slide to score this room out of 10',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isSet ? theme.primaryColor : theme.textSecondary,
                        fontWeight: isSet ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: isSet ? RoomScore.format(value) : '–',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSet ? theme.primaryColor : theme.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: ' / 10',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isSet ? theme.primaryColor : theme.borderLight,
              inactiveTrackColor: theme.borderLight,
              thumbColor: isSet ? theme.primaryColor : theme.textSecondary,
              overlayColor: theme.primaryColor.withValues(alpha: 0.12),
              valueIndicatorColor: theme.primaryColor,
              valueIndicatorTextStyle: TextStyle(color: theme.onPrimary),
            ),
            child: Slider(
              value: value ?? 5,
              min: RoomScore.min,
              max: RoomScore.max,
              divisions: RoomScore.divisions,
              label: isSet ? RoomScore.format(value) : null,
              semanticFormatterCallback: (v) =>
                  '${RoomScore.format(v)} out of 10',
              onChanged: onChanged,
            ),
          ),
          if (isSet)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onChanged(null),
                child: Text(
                  'Clear score',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
