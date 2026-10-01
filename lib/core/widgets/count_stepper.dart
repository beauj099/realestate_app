import 'package:flutter/material.dart';

import '../theme/themes.dart';

/// − n + counter, like the guest/bed counters in booking apps.
class CountStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final String semanticsLabel;

  /// The fewest allowed (e.g. 1 for a flatlet's bathrooms).
  final int min;

  static const int max = 20;

  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.textTheme,
    required this.semanticsLabel,
    this.min = 0,
  });

  Widget _button(IconData icon, VoidCallback? onPressed, String tooltip) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton.outlined(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          foregroundColor: theme.primaryColor,
          disabledForegroundColor: theme.borderLight,
          side: BorderSide(
            color: onPressed == null
                ? theme.borderLight
                : theme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          Icons.remove,
          value > min ? () => onChanged(value - 1) : null,
          'Fewer $semanticsLabel',
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
        ),
        _button(
          Icons.add,
          value < max ? () => onChanged(value + 1) : null,
          'More $semanticsLabel',
        ),
      ],
    );
  }
}
