import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/themes.dart';
import '../../data/models/area_details.dart';
import '../../data/models/property_report.dart';
import 'report_widgets.dart';

/// Area details on screen: population, crime, income and climate, each with
/// its source (the PDF prints the same).
class AreaDetailsCard extends StatelessWidget {
  final AreaDetails area;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const AreaDetailsCard({
    super.key,
    required this.area,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    Widget fact(String label, String value) =>
        FactRow(label: label, value: value, theme: theme, textTheme: textTheme);
    final p = area.population;
    final c = area.crime;
    final i = area.income;
    final w = area.climate;
    return ReportCard(
      title: 'Area details',
      subtitle: [
        if (p?.subPlace != null) p!.subPlace!,
        if (p?.mainPlace != null) p!.mainPlace!,
      ].join(', '),
      theme: theme,
      textTheme: textTheme,
      children: [
        if (p != null) ...[
          if (p.estimatedPopulation != null)
            fact(
              'People (${p.estimateYear} estimate)',
              groupDigits(p.estimatedPopulation!),
            ),
          if (p.households != null)
            fact('Households (Census ${p.year})', groupDigits(p.households!)),
          if (p.peoplePerKm2 != null)
            fact('Density', '${groupDigits(p.peoplePerKm2!)} per km²'),
        ],
        if (c != null) ...[
          fact(
            'Crime (${c.precinct} precinct)',
            [
              '${groupDigits(c.total)} serious crimes',
              if (c.change != null)
                '${c.change! >= 0 ? '+' : ''}${c.change!.toStringAsFixed(0)}% on the year before',
            ].join(' · '),
          ),
          for (final x in c.crimes.where((x) => x.count > 0).take(3))
            fact(
              x.crime,
              '${groupDigits(x.count)} (was ${groupDigits(x.previousCount)})',
            ),
          if (c.band != null) fact('Compared with all precincts', c.band!),
        ],
        if (i != null)
          fact('Middle household income (${i.year})', i.medianBand),
        if (w != null) ...[
          fact(
            'Average high / low',
            '${w.avgMaxC.toStringAsFixed(1)} / ${w.avgMinC.toStringAsFixed(1)} °C',
          ),
          fact('Rainfall', '${groupDigits(w.annualRainMm)} mm a year'),
        ],
      ],
    );
  }
}

/// Similar homes advertised on Property24, credited and linked there. Tapping
/// one opens its listing; the Property24 suburb searched can be changed.
class ForSaleCard extends StatelessWidget {
  final ForSale forSale;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<int> onPickSuburb;

  const ForSaleCard({
    super.key,
    required this.forSale,
    required this.theme,
    required this.textTheme,
    required this.onPickSuburb,
  });

  @override
  Widget build(BuildContext context) {
    final listed = DateFormat('d MMM yyyy');
    return ReportCard(
      title: 'Homes on the market like this one',
      subtitle:
          'From Property24 · ${forSale.suburbs.map((s) => s.name).join(', ')}',
      theme: theme,
      textTheme: textTheme,
      children: [
        if (forSale.listings.isEmpty)
          Text(
            'No similar homes are advertised there right now.',
            style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
          ),
        for (final l in forSale.listings)
          InkWell(
            onTap: () => launchUrl(
              Uri.parse(l.url),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (l.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        l.imageUrl!,
                        width: 96,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const SizedBox(width: 96, height: 64),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.priceZar == null
                              ? 'Price on application'
                              : formatZar(l.priceZar),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          [
                            l.title,
                            l.address ?? l.suburb,
                          ].whereType<String>().join(' · '),
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          [
                            if (l.distanceM != null)
                              formatDistance(l.distanceM!),
                            if (l.floorM2 != null) formatM2(l.floorM2),
                            if (l.erfM2 != null) '${formatM2(l.erfM2)} erf',
                            if (l.listedOn != null)
                              'listed ${listed.format(l.listedOn!)}',
                          ].join(' · '),
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 16, color: theme.textSecondary),
                ],
              ),
            ),
          ),
        if (forSale.suburbs.length > 1)
          Wrap(
            spacing: 6,
            children: [
              for (final s in forSale.suburbs)
                ActionChip(
                  label: Text(s.name),
                  onPressed: () => onPickSuburb(s.id),
                ),
            ],
          ),
      ],
    );
  }
}
