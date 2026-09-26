import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/themes.dart';
import '../../data/models/property_report.dart';

/// "R 7 100 000", or a dash.
String formatZar(num? v) => v == null ? '—' : rand(v);

/// "R 8.2m" — for the headline range.
String formatZarShort(num? v) {
  if (v == null) return '—';
  if (v >= 1000000) {
    return 'R ${(v / 1000000).toStringAsFixed(v >= 10000000 ? 1 : 2)}m';
  }
  return formatZar(v);
}

String formatM2(num? v) => v == null ? '—' : '${groupDigits(v)} m²';

String formatCount(int v) => groupDigits(v);

/// A card with a title and label/value rows.
class ReportCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const ReportCard({
    super.key,
    required this.title,
    required this.children,
    required this.theme,
    required this.textTheme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// One label and value on a line; skipped by callers when there is no value.
class FactRow extends StatelessWidget {
  final String label;
  final String value;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const FactRow({
    super.key,
    required this.label,
    required this.value,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The indicative market range: a range, never a single number.
class ValueRangeCard extends StatelessWidget {
  final PropertyReport report;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const ValueRangeCard({
    super.key,
    required this.report,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final range = report.indicativeValue;
    final summary = report.comparableSummary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INDICATIVE MARKET RANGE',
            style: textTheme.labelMedium?.copyWith(
              color: theme.onPrimary.withValues(alpha: 0.8),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            range == null
                ? (summary == null
                      ? 'No sales data for this area yet'
                      : 'Not enough comparable sales')
                : '${formatZarShort(range.low)} – ${formatZarShort(range.high)}',
            style: textTheme.headlineSmall?.copyWith(
              color: theme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (range?.mid != null) ...[
            const SizedBox(height: 2),
            Text(
              'Midpoint ${formatZar(range!.mid)}',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: theme.onPrimary.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 12),
          if (report.municipalValueZar != null)
            Text(
              'Municipal value ${formatZar(report.municipalValueZar)}'
              '${report.rollVersion == null ? '' : ' (${report.rollVersion})'}',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (summary != null) ...[
            const SizedBox(height: 4),
            Text(
              'From ${formatCount(summary.included)} comparable sales of '
              '${formatCount(summary.raw)} in the area, indexed to today.',
              style: textTheme.bodySmall?.copyWith(
                color: theme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'An indicative range from public municipal data, not a certified '
            'valuation.',
            style: textTheme.bodySmall?.copyWith(
              color: theme.onPrimary.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// The site plan: our own drawing from the City's cadastre, safe to print.
class SitePlanView extends StatelessWidget {
  final String? svg;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const SitePlanView({
    super.key,
    required this.svg,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: Colors.white,
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 900 / 650,
          child: svg == null
              ? Center(
                  child: Text(
                    'Site plan unavailable',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                )
              : SvgPicture.string(svg!, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Imagery with its attribution locked beneath it. Never cropped (contain),
/// and Street View is marked as app-only.
class AttributedImage extends StatelessWidget {
  final ImageryRef imagery;
  final Uint8List? bytes;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const AttributedImage({
    super.key,
    required this.imagery,
    required this.bytes,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 640 / 400,
            child: bytes == null
                ? Container(
                    color: theme.imagePlaceholder,
                    alignment: Alignment.center,
                    child: Text(
                      'No ${imagery.title.toLowerCase()} here',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                  )
                : Image.memory(bytes!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                imagery.attribution,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            if (!imagery.allowedInPrint) ...[
              Icon(Icons.phone_android, size: 13, color: theme.textSecondary),
              const SizedBox(width: 3),
              Text(
                'App only, not in the PDF',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Comparable sales as compact rows. Near misses stay listed, struck
/// through with the reason: the filtering reads as considered work.
class ComparablesList extends StatelessWidget {
  final List<ComparableSale> sales;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const ComparablesList({
    super.key,
    required this.sales,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final sold = DateFormat('MMM yyyy');
    return Column(
      children: [
        for (final (i, c) in sales.indexed) ...[
          if (i > 0) Divider(height: 1, color: theme.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Opacity(
              opacity: c.included ? 1 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titleCase(c.address),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                            decoration: c.included
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatZar(c.salePriceZar),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      'Sold ${sold.format(c.saleDate)}',
                      if (c.dwellingExtentM2 > 0)
                        '${formatM2(c.dwellingExtentM2)} building',
                      if (c.erfExtentM2 > 0) '${formatM2(c.erfExtentM2)} erf',
                      if (c.pricePerDwellingM2 != null)
                        '${formatZar(c.pricePerDwellingM2)}/m²',
                    ].join('  ·  '),
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  if (!c.included && c.excludedBecause != null)
                    Text(
                      'Not used: ${c.excludedBecause}',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
