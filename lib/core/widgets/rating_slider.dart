import 'package:flutter/material.dart';

import '../theme/themes.dart';

class RatingSlider extends StatefulWidget {
  final int? conditionRating;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<int> onChanged;

  const RatingSlider({
    super.key,
    required this.conditionRating,
    required this.theme,
    required this.textTheme,
    required this.onChanged,
  });

  @override
  State<RatingSlider> createState() => _RatingSliderState();
}

class _RatingSliderState extends State<RatingSlider> {
  double _dragValue = 0;
  bool _fromSelfChange = false;

  @override
  void initState() {
    super.initState();
    _dragValue = _levelToMidpoint(widget.conditionRating ?? 1);
  }

  @override
  void didUpdateWidget(RatingSlider old) {
    super.didUpdateWidget(old);
    if (widget.conditionRating != old.conditionRating) {
      if (!_fromSelfChange) {
        _dragValue = _levelToMidpoint(widget.conditionRating ?? 1);
      }
      _fromSelfChange = false;
    }
  }

  static double _levelToMidpoint(int? level) {
    switch (level) {
      case 1: return 12;
      case 2: return 37;
      case 3: return 62;
      case 4: return 87;
      default: return 0;
    }
  }

  static int _valueToLevel(double value) {
    if (value < 25) return 1;
    if (value < 50) return 2;
    if (value < 75) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final activeLevel = _valueToLevel(_dragValue);
    final displayValue = _dragValue;

    final segments = [
      {'range': '0\u201324%', 'level': 1},
      {'range': '25\u201349%', 'level': 2},
      {'range': '50\u201374%', 'level': 3},
      {'range': '75\u2013100%', 'level': 4},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final pixelsPerPercent = barWidth / 100;
            setState(() {
              _dragValue = (_dragValue +
                      details.delta.dx / pixelsPerPercent)
                  .clamp(0.0, 100.0);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_valueToLevel(_dragValue) != widget.conditionRating) {
              _fromSelfChange = true;
              widget.onChanged(_valueToLevel(_dragValue));
            } else {
              setState(() {});
            }
          },
          onTapUp: (details) {
            final tapPercent = (details.localPosition.dx / barWidth) * 100;
            _dragValue = tapPercent;
            _fromSelfChange = true;
            widget.onChanged(_valueToLevel(tapPercent));
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.theme.borderLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  Row(
                    children: List.generate(4, (i) {
                      final lvl = i + 1;
                      final isActive = lvl == activeLevel;
                      return Expanded(
                        child: Container(
                          color: isActive
                              ? widget.theme.primaryColor.withValues(alpha: 0.12)
                              : widget.theme.cardBackgroundColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                segments[i]['range'] as String,
                                style: widget.textTheme.labelLarge?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? widget.theme.primaryColor
                                      : widget.theme.textSecondary
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned(
                    left: ((displayValue / 100) * barWidth - 14).clamp(0.0, barWidth - 28),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.theme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: widget.theme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${displayValue.round()}%',
                          style: widget.textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
