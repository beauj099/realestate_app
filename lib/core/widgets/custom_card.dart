import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/themes.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? backgroundColor;
  final BorderStyle borderStyle;
  final double borderRadius;
  final double borderWidth;
  final bool hasDashedBorder;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final RealEstateTheme? theme;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.backgroundColor,
    this.borderStyle = BorderStyle.solid,
    this.borderRadius = 12.0,
    this.borderWidth = 1.0,
    this.hasDashedBorder = false,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = this.theme ?? RealEstateTheme.crimson();

    final resolvedBg =
        backgroundColor ??
        (isSelected
            ? theme.cardBackgroundColor
            : theme.backgroundColor.withValues(alpha: 0.4));
    final resolvedBorderColor = isSelected
        ? theme.borderSelected
        : theme.borderLight;
    final resolvedBorderWidth = isSelected ? 1.5 : borderWidth;

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasDashedBorder
            ? null
            : Border.all(
                color: resolvedBorderColor,
                width: resolvedBorderWidth,
              ),
      ),
      child: child,
    );

    // If dashed border requested, paint it
    if (hasDashedBorder) {
      cardContent = CustomPaint(
        painter: _DashedRectPainter(
          color: theme.textSecondary.withValues(alpha: 0.5),
          radius: borderRadius,
          strokeWidth: 1.0,
        ),
        child: cardContent,
      );
    }

    if (onTap != null) {
      return Container(
        margin: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: theme.primaryColor.withValues(alpha: 0.05),
          highlightColor: theme.primaryColor.withValues(alpha: 0.02),
          child: cardContent,
        ),
      );
    }

    return margin != null
        ? Padding(padding: margin!, child: cardContent)
        : cardContent;
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth = 6.0;
  final double dashSpace = 4.0;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashWidth : dashSpace;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
