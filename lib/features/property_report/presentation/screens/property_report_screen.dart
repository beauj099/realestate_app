import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/busy_overlay.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../../auth/providers/agent_profile_provider.dart';
import '../../../property_overview/providers/property_provider.dart';
import '../../data/models/property_report.dart';
import '../../data/property_report_repository.dart';
import '../../providers/city_records_autofill.dart';
import '../../providers/property_report_provider.dart';
import '../../report/valuation_report_pdf.dart';
import '../widgets/report_widgets.dart';

/// Valuation report for the listing being captured, from public municipal
/// data: site, buildings, municipal value, suburb trend, comparable sales and
/// an indicative range, with a PDF to share. Looks the property up by the
/// listing's coordinates, erf or address.
class PropertyReportScreen extends ConsumerStatefulWidget {
  const PropertyReportScreen({super.key});

  @override
  ConsumerState<PropertyReportScreen> createState() =>
      _PropertyReportScreenState();
}

class _PropertyReportScreenState extends ConsumerState<PropertyReportScreen> {
  late final TextEditingController _addressController;
  bool _exporting = false;

  static const _lookupMessages = [
    'Finding the erf…',
    'Reading the valuation roll…',
    'Checking recent sales nearby…',
    'Filtering comparable sales…',
    'Indexing sales to today…',
    'Drawing the site plan…',
    'Still busy — the City can be slow…',
    'Almost there…',
  ];

  @override
  void initState() {
    super.initState();
    final listing = ref.read(propertyViewModelProvider);
    _addressController = TextEditingController(
      text: [
        '${listing.streetNumber} ${listing.street}'.trim(),
        listing.suburb.trim(),
        listing.city.trim(),
      ].where((p) => p.isNotEmpty).join(', '),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _lookUp(useListing: true),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _lookUp({bool useListing = false}) {
    final listing = ref.read(propertyViewModelProvider);
    ref
        .read(propertyReportProvider.notifier)
        .lookUp(
          ReportQuery(
            address: _addressController.text,
            // The listing's own erf and pin are only trusted for the first,
            // automatic lookup; a retyped address means the agent disagrees.
            erf: useListing ? listing.erfNumber : null,
            suburb: listing.suburb,
            lat: useListing ? listing.latitude : null,
            lng: useListing ? listing.longitude : null,
          ),
        );
  }

  ReportAuthor _author() {
    final profile = ref.read(agentProfileProvider);
    return ReportAuthor(
      name: profile.fullName,
      agencyName: profile.agencyName,
      email: profile.email,
      mobile: profile.mobile,
      licenceNumber: profile.licenceNumber,
    );
  }

  Future<void> _exportPdf({required bool print}) async {
    final state = ref.read(propertyReportProvider);
    final report = state.report;
    if (report == null) return;
    setState(() => _exporting = true);
    try {
      final pdf = ValuationReportPdf(
        report: report,
        sitePlanSvg: state.sitePlanSvg,
        images: state.images,
        author: _author(),
        brandColor: ref.read(themeConfigProvider).primaryColor,
      );
      final bytes = await pdf.build();
      if (print) {
        await Printing.layoutPdf(
          name: pdf.fileName,
          onLayout: (_) async => bytes,
        );
      } else {
        await Printing.sharePdf(bytes: bytes, filename: pdf.fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't create the PDF: $e")));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;
    final state = ref.watch(propertyReportProvider);
    final report = state.report;

    return BusyOverlay(
      busy: state.loading || _exporting,
      theme: theme,
      title: _exporting ? 'Creating the PDF…' : 'Looking up the property…',
      messages: _exporting
          ? const ['Laying out the report…', 'Almost there…']
          : _lookupMessages,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Valuation report',
          theme: theme,
          onBack: () => context.pop(),
          actions: [
            if (report != null)
              IconButton(
                tooltip: 'Print',
                icon: Icon(Icons.print_outlined, color: theme.textPrimary),
                onPressed: () => _exportPdf(print: true),
              ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (report == null)
                ..._search(state, theme, textTheme)
              else
                ..._report(state, report, theme, textTheme),
            ],
          ),
        ),
        bottomNavigationBar: report == null
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  border: Border(top: BorderSide(color: theme.borderLight)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: CustomButton(
                      text: 'Share PDF report',
                      fullWidth: true,
                      theme: theme,
                      onTap: () => _exportPdf(print: false),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Address field, a matching-property picker, or the lookup error.
  List<Widget> _search(
    PropertyReportState state,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) => [
    Text(
      'Market data comes from the City of Cape Town: municipal value, recorded '
      'sales nearby and the erf and building plans.',
      style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
    ),
    const SizedBox(height: 16),
    CustomTextInput(
      theme: theme,
      label: 'Property address',
      placeholder: 'e.g. 17 Pine Road, Claremont',
      controller: _addressController,
      textCapitalization: TextCapitalization.words,
    ),
    const SizedBox(height: 12),
    CustomButton(
      text: 'Look up',
      fullWidth: true,
      theme: theme,
      onTap: state.loading ? null : _lookUp,
    ),
    if (state.error != null) ...[
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.errorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          state.error!,
          style: textTheme.bodyMedium?.copyWith(color: theme.error),
        ),
      ),
    ],
    if (state.candidates.isNotEmpty) ...[
      const SizedBox(height: 20),
      Text(
        'Which property?',
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      for (final c in state.candidates)
        Card(
          color: theme.cardBackgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.borderLight),
          ),
          child: ListTile(
            leading: Icon(
              Icons.location_on_outlined,
              color: theme.primaryColor,
            ),
            title: Text(c.label),
            subtitle: c.sg26 == null ? null : Text(c.sg26!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(propertyReportProvider.notifier).open(c),
          ),
        ),
    ],
  ];

  /// Offers to copy what the listing is missing (erf size, floor area,
  /// zoning…) from this report. Never overwrites what the agent entered.
  List<Widget> _fillListing(
    PropertyReport r,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    final plan = planAutofill(ref.watch(propertyViewModelProvider), r);
    if (plan.filled.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final message = await ref
              .read(cityRecordsAutofillProvider.notifier)
              .apply(r);
          ref.read(cityRecordsAutofillProvider.notifier).clearMessage();
          if (!mounted || message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: theme.primaryColor,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high, color: theme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fill in the listing',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      'Adds ${plan.filled.join(', ')}',
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textSecondary),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _report(
    PropertyReportState state,
    PropertyReport r,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
    Widget fact(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : FactRow(
            label: label,
            value: value,
            theme: theme,
            textTheme: textTheme,
          );
    const gap = SizedBox(height: 14);
    final summary = r.comparableSummary;
    final suburb = r.suburbStats;
    final captured = r.buildings
        .map((b) => b.capturedPeriod)
        .whereType<String>()
        .firstOrNull;

    return [
      Text(
        r.displayAddress,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        [
          'Erf ${r.erf} ${titleCase(r.township)}',
          if (r.valuationRef != null) r.valuationRef!,
        ].join('  ·  '),
        style: textTheme.bodyMedium?.copyWith(color: theme.textSecondary),
      ),
      gap,
      ValueRangeCard(report: r, theme: theme, textTheme: textTheme),
      ..._fillListing(r, theme, textTheme),
      gap,
      ReportCard(
        title: 'Site plan',
        subtitle: captured == null ? null : 'Buildings as surveyed $captured',
        theme: theme,
        textTheme: textTheme,
        children: [
          SitePlanView(
            svg: state.sitePlanSvg,
            theme: theme,
            textTheme: textTheme,
          ),
        ],
      ),
      for (final i in r.imagery) ...[
        gap,
        ReportCard(
          title: i.title,
          theme: theme,
          textTheme: textTheme,
          children: [
            AttributedImage(
              imagery: i,
              bytes: state.images[i.url],
              theme: theme,
              textTheme: textTheme,
            ),
          ],
        ),
      ],
      gap,
      ReportCard(
        title: 'Property',
        theme: theme,
        textTheme: textTheme,
        children: [
          fact('Erf extent', formatM2(r.extentM2)),
          fact(
            'Zoning',
            [r.zoningCode, r.zoningDescription].whereType<String>().join(' · '),
          ),
          fact('Ward', r.ward),
          fact('Legal status', r.legalStatus),
          fact(
            'Dwelling extent',
            r.dwellingExtentM2 == null ? null : formatM2(r.dwellingExtentM2),
          ),
          for (final (i, b) in r.buildings.indexed)
            fact(
              i == 0 ? 'Main building' : 'Building ${i + 1}',
              [
                '${formatM2(b.roofM2)} roof',
                if (b.heightM != null) '${b.heightM!.toStringAsFixed(1)} m',
                if (b.estimatedStoreys != null)
                  '~${b.estimatedStoreys} storey${b.estimatedStoreys == 1 ? '' : 's'}',
              ].join(' · '),
            ),
        ],
      ),
      gap,
      ReportCard(
        title: 'Municipal valuation',
        theme: theme,
        textTheme: textTheme,
        children: [
          fact('Market value', formatZar(r.municipalValueZar)),
          fact(
            'Valued as at',
            r.municipalValueAsAt == null
                ? null
                : DateFormat('d MMMM yyyy').format(r.municipalValueAsAt!),
          ),
          fact(
            'Rating category',
            r.ratingCategory == null ? null : titleCase(r.ratingCategory!),
          ),
          fact('Roll', r.rollVersion),
        ],
      ),
      if (suburb != null) ...[
        gap,
        ReportCard(
          title: 'Suburb: ${titleCase(suburb.name)}',
          subtitle: 'Median values on the last two municipal rolls',
          theme: theme,
          textTheme: textTheme,
          children: [
            fact('Median value 2022', formatZar(suburb.gv2022)),
            fact('Median value 2025', formatZar(suburb.gv2025)),
            fact(
              'Change',
              '${suburb.growthPercent >= 0 ? '+' : ''}${suburb.growthPercent.toStringAsFixed(1)}% '
                  '(${suburb.annualGrowthPercent.toStringAsFixed(1)}% a year)',
            ),
            fact('Median land', formatM2(suburb.medianLandM2)),
            fact('Median building', formatM2(suburb.medianBuildingM2)),
            fact(
              'Residential properties',
              formatCount(suburb.residentialCount),
            ),
          ],
        ),
      ],
      if (r.comparables.isNotEmpty) ...[
        gap,
        ReportCard(
          title: 'Comparable sales',
          subtitle: summary == null
              ? null
              : '${formatCount(summary.raw)} considered, ${formatCount(summary.included)} used · '
                    'median ${formatZar(summary.medianPricePerDwellingM2)}/m² of building',
          theme: theme,
          textTheme: textTheme,
          children: [
            ComparablesList(
              sales: r.comparables,
              theme: theme,
              textTheme: textTheme,
            ),
          ],
        ),
      ],
      if (r.approvedWork.isNotEmpty) ...[
        gap,
        ReportCard(
          title: 'Approved building work',
          theme: theme,
          textTheme: textTheme,
          children: [
            for (final w in r.approvedWork)
              fact(
                w.date ?? '—',
                [
                  w.description ?? w.category ?? 'Building work',
                  if ((w.areaM2 ?? 0) > 0) formatM2(w.areaM2),
                  if ((w.valueZar ?? 0) > 0) formatZar(w.valueZar),
                ].join(' · '),
              ),
          ],
        ),
      ],
      gap,
      Text(
        'Source: City of Cape Town open data and ${r.rollVersion ?? 'GV2025'} valuation roll, '
        'read ${DateFormat('d MMM yyyy').format(r.generatedAt.toLocal())}. '
        'An indicative range, not a certified valuation.',
        style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
      ),
    ];
  }
}
