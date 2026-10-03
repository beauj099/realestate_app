import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/formatting/time_ago.dart';
import '../../data/pack_record.dart';

import '../../../../core/theme/office_details.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/busy_overlay.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../../auth/providers/agent_profile_provider.dart';
import '../../../property_overview/providers/property_provider.dart';
import '../../data/models/agent_sales.dart';
import '../../data/models/area_details.dart';
import '../../data/models/property_report.dart';
import '../../data/property_report_repository.dart';
import '../../providers/city_records_autofill.dart';
import '../../providers/property_report_provider.dart';
import '../../providers/report_preparer.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../report_settings/providers/report_settings_provider.dart';
import '../../report/logo_trim.dart';
import '../../report/agency_logo_bytes.dart';
import '../../report/costs_calculator.dart';
import '../../report/pack_images.dart';
import '../../report/pack_listing.dart';
import '../../report/listing_flyer.dart';
import '../../report/report_pack_pdf.dart';
import '../widgets/report_pack_sheet.dart';
import '../../report/valuation_report_pdf.dart';
import '../widgets/agent_sale_sheet.dart';
import '../widgets/area_and_market_cards.dart';
import '../widgets/report_widgets.dart';
import '../../../../core/widgets/app_snack.dart';

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
  bool _savingSale = false;

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

  void _lookUp({bool useListing = false, bool refresh = false}) {
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
          listingId: listing.listingId,
          // Filed under the listing's own address, erf and pin, so a report
          // made from a retyped address is still found next time, and a
          // changed listing gets a new one.
          cacheKey: reportKeyForListing(listing),
          refresh: refresh,
          hints: reportHintsForListing(listing),
        );
  }

  /// Makes a new report from the City's current records, replacing the one
  /// kept on the phone.
  Future<void> _regenerate(RealEstateTheme theme) async {
    final textTheme = theme.toThemeData().textTheme;
    final go = await showRealEstateDialog<bool>(
      context: context,
      title: 'Make a new report?',
      theme: theme,
      content: Text(
        "This asks the City again for this property's records and recent "
        'sales, and takes up to half a minute. The report you have is '
        'replaced.',
        style: textTheme.bodyLarge,
      ),
      actions: [
        dialogCancelButton(context: context, theme: theme),
        dialogActionButton(
          theme: theme,
          text: 'Make a new one',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (go == true && mounted) _lookUp(useListing: true, refresh: true);
  }

  /// Older than this, the report offers a refresh up front; until then it
  /// sits in the menu. Municipal sales arrive a few times a month.
  static const _staleAfter = Duration(days: 7);

  void _snack(String message, RealEstateTheme theme, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnack(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? theme.error : theme.primaryColor,
      ),
    );
  }

  Future<void> _logSale(PropertyReport report, RealEstateTheme theme) async {
    final sale = await showAgentSaleSheet(
      context: context,
      theme: theme,
      report: report,
    );
    if (sale == null || !mounted) return;
    setState(() => _savingSale = true);
    try {
      final duplicate = await ref
          .read(propertyReportProvider.notifier)
          .addAgentSale(sale);
      _snack(
        duplicate
            ? 'This sale was already logged. Thank you: it now counts as '
                  'confirmed.'
            : 'Sale saved. Agents reporting on ${titleCase(report.suburb)} '
                  'will see it.',
        theme,
      );
    } catch (e) {
      _snack(
        "Couldn't save the sale. Check your connection and try again.",
        theme,
        error: true,
      );
    } finally {
      if (mounted) setState(() => _savingSale = false);
    }
  }

  Future<void> _deleteSale(AgentSale sale, RealEstateTheme theme) async {
    final textTheme = theme.toThemeData().textTheme;
    final confirmed = await showRealEstateDialog<bool>(
      context: context,
      title: 'Delete sale',
      theme: theme,
      content: Text(
        'Delete the sale of ${titleCase(sale.address)}? Other agents will '
        'no longer see it.',
        style: textTheme.bodyLarge,
      ),
      actions: [
        dialogCancelButton(context: context, theme: theme),
        dialogActionButton(
          theme: theme,
          text: 'Delete',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    setState(() => _savingSale = true);
    try {
      await ref.read(propertyReportProvider.notifier).deleteAgentSale(sale.id);
    } catch (e) {
      _snack("Couldn't delete the sale. Try again.", theme, error: true);
    } finally {
      if (mounted) setState(() => _savingSale = false);
    }
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

  /// Asks for the pack's figures, gathers its pictures and shares the pack.
  Future<void> _createPack() async {
    final state = ref.read(propertyReportProvider);
    final report = state.report;
    if (report == null) return;
    final brand = ref.read(themeConfigProvider);
    final listing = ref.read(propertyViewModelProvider);
    final (preparedFor, greeting) = packOwners(listing);
    final photos = [
      ...listing.exteriorPhotos,
      for (final r in listing.rooms)
        for (final p in r.photos) p.path,
    ];
    final options = await showReportPackSheet(
      context: context,
      theme: brand,
      floorAreaWarning: report.floorAreaWarning,
      photos: photos,
      baseUrl: ref.read(apiClientProvider).baseUrl,
      initial: initialPackOptions(
        report: report,
        preparedFor: preparedFor,
        greeting: greeting,
        valuation: listing.listingValuation,
        calculator: ref.read(reportSettingsProvider).calculator,
        coverPhoto: listing.exteriorPhotos.firstOrNull,
        gallery: packGallery(listing),
      ),
    );
    if (options == null || !mounted) return;

    // The figures chosen are the listing's Price & Commission from now on.
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final before = listing.listingValuation.content;
    viewModel.editValuation((v) => valuationWithPack(v, options));
    if (!listEquals(
      before,
      ref.read(propertyViewModelProvider).listingValuation.content,
    )) {
      unawaited(viewModel.saveValuation());
    }

    setState(() => _exporting = true);
    try {
      final pdf = await _packPdf(state, report, options);
      final bytes = await pdf.build();
      // What the pack was made from, so the overview can say when it is
      // out of date.
      final made = ref.read(propertyViewModelProvider);
      if (made.listingId case final id?) {
        await PackRecord.save(id, made);
        ref.invalidate(packRecordProvider(id));
      }
      await Printing.sharePdf(bytes: bytes, filename: pdf.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnack(
          SnackBar(content: Text("Couldn't create the report pack: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// The report pack (or, for [PackAudience.buyer], the property brochure)
  /// for this listing, its pictures fetched.
  Future<ReportPackPdf> _packPdf(
    PropertyReportState state,
    PropertyReport report,
    PackOptions options, {
    PackAudience audience = PackAudience.seller,
  }) async {
    final buyer = audience == PackAudience.buyer;
    final brand = ref.read(themeConfigProvider);
    final listing = ref.read(propertyViewModelProvider);
    final api = ref.read(apiClientProvider);
    final profile = ref.read(agentProfileProvider);
    final agency = ref.read(agencyProvider);
    // A buyer's brochure shows no other homes for sale.
    final forSale = buyer ? null : state.forSale;
    // The agent's own pages when they have any, else the agency's (an
    // empty list from the API means "none of my own", not "no pages").
    final own = profile.brochurePages ?? const <String>[];
    final brochure = own.isNotEmpty ? own : agency.brochurePages;
    final office = profile.office.orDefaults(agency.office);
    final fetched = await Future.wait([
      packImageBytes(options.coverPhoto, api),
      packImageBytes(options.gallery.firstOrNull, api),
      packImageBytes(profile.photoUrl, api),
      packImageBytes(profile.signatureUrl, api),
      agencyLogoBytes(agency),
      for (final l in forSale?.listings ?? const [])
        packImageBytes(l.imageUrl, api),
      for (final page in brochure) packImageBytes(page, api),
    ]);
    final listingCount = forSale?.listings.length ?? 0;
    // Three more photos of each home for sale, for its card.
    final morePhotos = await Future.wait([
      for (final l in forSale?.listings ?? const <ForSaleListing>[])
        Future.wait([
          for (final p in l.morePhotos.take(3)) packImageBytes(p, api),
        ]),
    ]);
    // The cover's row of photos under the main one.
    final gallery = await Future.wait([
      for (final g in options.gallery) packImageBytes(g, api),
    ]);
    final logos = await Future.wait([
      for (final kind in OfficeLogos.kinds)
        packImageBytes(office.logos[kind], api),
    ]);
    final parkingTypes = ref
        .read(parkingTypesProvider)
        .maybeWhen(data: (t) => t, orElse: () => fallbackParkingTypes);
    final (street, area) = buyer
        ? marketedAddress(listing)
        : packAddress(listing);
    // The buyer's photo pages: every photo of the home, captioned.
    final captioned = buyer
        ? buyerPhotoList(listing)
        : const <({String caption, String path})>[];
    final photoBytes = await Future.wait([
      for (final p in captioned) packImageBytes(p.path, api),
    ]);
    final c = options.calculator;
    return ReportPackPdf(
      report: report,
      sitePlanSvg: state.sitePlanSvg,
      areaMapSvg: state.areaMapSvg,
      blockMapSvg: state.blockMapSvg,
      images: state.images,
      agent: PackAgent(
        name: profile.fullName,
        jobTitle: profile.jobTitle,
        email: profile.email,
        mobile: profile.mobile,
        website: profile.website,
        ppraNumber: profile.ppraNumber,
        ffcNumber: profile.licenceNumber,
        bio: profile.bio,
        qualifications: profile.qualifications,
        agencyName: agency.name,
        office: office,
      ),
      listing: PackListing(
        preparedFor: options.preparedFor,
        greeting: options.greeting,
        portfolio: packPortfolio(listing),
        street: street,
        area: area,
        facts: packFacts(listing, parkingTypes),
        ownersPurchase: packOwnersPurchase(listing),
        inspection: packInspection(listing),
        flatletRents: packFlatletRents(listing),
      ),
      valuation: PackValuation(
        low: options.low,
        high: options.high,
        listingPrice: options.listingPrice,
        adjustmentReason: options.adjustmentReason,
      ),
      costs: CostsSummary(
        // A buyer pays the asking price.
        valuationPrice: buyer ? options.listingPrice : options.high,
        listingPrice: options.listingPrice,
        commissionEarlyPercent: c.commissionEarlyPercent,
        commissionLatePercent: c.commissionLatePercent,
        earlyMonths: c.earlyMonths,
        commissionIncludesVat: c.commissionIncludesVat,
        interestRatePercent: c.interestRatePercent,
        bondTermYears: c.bondTermYears,
        depositPercent: c.depositPercent,
      ),
      area: state.area,
      forSale: forSale,
      pictures: PackImages(
        coverPhoto: fetched[0],
        secondPhoto: fetched[1],
        gallery: [for (final g in gallery) ?g],
        agentPhoto: fetched[2],
        signature: fetched[3],
        // Square logo tiles trimmed to their artwork, to fill the band.
        logo: fetched[4] == null ? null : trimLogoBorder(fetched[4]!),
        logoMark: logos[0],
        logoWide: logos[1],
        logoWideOnBrand: logos[2],
        listingPhotos: {
          for (var i = 0; i < listingCount; i++)
            forSale!.listings[i].listingNumber: ?fetched[5 + i],
        },
        listingMorePhotos: {
          for (var i = 0; i < listingCount; i++)
            forSale!.listings[i].listingNumber: [
              for (final bytes in morePhotos[i]) ?bytes,
            ],
        },
        photoPages: [
          for (var i = 0; i < captioned.length; i++)
            if (photoBytes[i] case final bytes?)
              (caption: captioned[i].caption, bytes: bytes),
        ],
        brochurePages: [
          for (final bytes in fetched.skip(5 + listingCount)) ?bytes,
        ],
      ),
      brandColor: brand.primaryColor,
      onBrandColor: brand.onPrimary,
      logoBackground: agency.bannerColor,
      audience: audience,
    );
  }

  /// What to make for buyers: the property brochure, or a flyer for social
  /// media or print. None shows the owners or the valuation.
  Future<void> _forBuyers() async {
    final theme = ref.read(themeConfigProvider);
    final choice = await showRealEstateBottomSheet<String>(
      context: context,
      theme: theme,
      builder: (sheet) {
        Widget option(String value, IconData icon, String title, String text) =>
            ListTile(
              leading: Icon(icon, color: theme.primaryColor),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              subtitle: Text(text),
              onTap: () => Navigator.pop(sheet, value),
            );
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  'For buyers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'At the asking price. Never the owners, the valuation or '
                  'the sales analysis.',
                  style: TextStyle(color: theme.textSecondary),
                ),
              ),
              option(
                'brochure',
                Icons.menu_book_outlined,
                'Property brochure',
                'PDF for open houses and buyers: the home, every photo, the '
                    'area and the costs of buying.',
              ),
              option(
                'square',
                Icons.crop_square_rounded,
                'Social media post',
                'Square picture for Facebook, Instagram and WhatsApp.',
              ),
              option(
                'story',
                Icons.crop_portrait_rounded,
                'Story',
                'Tall picture for Instagram, Facebook and WhatsApp status.',
              ),
              option(
                'a5',
                Icons.print_outlined,
                'Printed flyer',
                'A5 PDF to print or hand out.',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    final price = await _askingPrice();
    if (price == null || !mounted) return;
    switch (choice) {
      case 'brochure':
        await _buyerBrochure(price);
      case 'square':
        await _flyer(FlyerFormat.square, price);
      case 'story':
        await _flyer(FlyerFormat.story, price);
      case 'a5':
        await _flyer(FlyerFormat.a5, price);
    }
  }

  /// The asking price from Price & Commission; asked for (and saved there)
  /// when it is not set yet. Null when the agent cancels.
  Future<double?> _askingPrice() async {
    final listing = ref.read(propertyViewModelProvider);
    final set = double.tryParse(listing.listingValuation.listingPrice.trim());
    if (set != null && set > 0) return set;
    final controller = TextEditingController();
    final theme = ref.read(themeConfigProvider);
    final entered = await showDialog<double>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: const Text('Asking price'),
        content: CustomTextInput(
          theme: theme,
          label: 'Asking price (R)',
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          subtext: 'Saved on the listing\'s Price & Commission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialog,
              double.tryParse(
                controller.text.replaceAll(RegExp(r'[\s,R]'), ''),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (entered == null || entered <= 0) return null;
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    viewModel.editValuation(
      (v) => v.copyWith(listingPrice: entered.round().toString()),
    );
    unawaited(viewModel.saveValuation());
    return entered;
  }

  /// The property brochure: the buyer's version of the report pack.
  Future<void> _buyerBrochure(double price) async {
    final state = ref.read(propertyReportProvider);
    final report = state.report;
    if (report == null) return;
    final listing = ref.read(propertyViewModelProvider);
    final base = initialPackOptions(
      report: report,
      preparedFor: '',
      greeting: '',
      valuation: listing.listingValuation,
      calculator: ref.read(reportSettingsProvider).calculator,
      coverPhoto: listing.exteriorPhotos.firstOrNull,
      gallery: packGallery(listing),
    );
    final options = PackOptions(
      preparedFor: '',
      greeting: '',
      low: base.low,
      high: base.high,
      listingPrice: price,
      calculator: base.calculator,
      coverPhoto: base.coverPhoto,
      gallery: base.gallery,
    );
    setState(() => _exporting = true);
    try {
      final pdf = await _packPdf(
        state,
        report,
        options,
        audience: PackAudience.buyer,
      );
      await Printing.sharePdf(bytes: await pdf.build(), filename: pdf.fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnack(
          SnackBar(content: Text("Couldn't create the brochure: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// A flyer: pictures for social media are shared as images (with a line
  /// of text to post with them); the A5 flyer as a PDF.
  Future<void> _flyer(FlyerFormat format, double price) async {
    setState(() => _exporting = true);
    try {
      final api = ref.read(apiClientProvider);
      final listing = ref.read(propertyViewModelProvider);
      final profile = ref.read(agentProfileProvider);
      final agency = ref.read(agencyProvider);
      final brand = ref.read(themeConfigProvider);
      final parkingTypes = ref
          .read(parkingTypesProvider)
          .maybeWhen(data: (t) => t, orElse: () => fallbackParkingTypes);
      final (street, area) = marketedAddress(listing);
      final photos = await Future.wait([
        packImageBytes(listing.exteriorPhotos.firstOrNull, api),
        for (final g in packGallery(listing, count: 2)) packImageBytes(g, api),
      ]);
      final logo = await agencyLogoBytes(agency);
      final facts = packFacts(listing, parkingTypes);
      final flyer = ListingFlyer(
        street: street,
        area: area,
        askingPrice: price,
        facts: facts,
        mainPhoto: photos.first,
        morePhotos: [for (final p in photos.skip(1)) ?p],
        agentName: profile.fullName,
        agentPhone: profile.mobile,
        agencyName: agency.name,
        logo: logo == null ? null : trimLogoBorder(logo),
        brandColor: brand.primaryColor,
        onBrandColor: brand.onPrimary,
      );
      if (!format.isImage) {
        await Printing.sharePdf(
          bytes: await flyer.pdf(format),
          filename: flyer.fileName(format),
        );
        return;
      }
      final png = await flyer.png(format);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${flyer.fileName(format)}');
      await file.writeAsBytes(png);
      final beds = facts.bedrooms > 0 ? '${facts.bedrooms} bedroom ' : '';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text:
              'For sale: ${beds}home in ${area.split(',').first}, '
              '${rand(price)}. ${profile.fullName}'
              '${profile.mobile.isEmpty ? '' : ', ${profile.mobile}'}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnack(SnackBar(content: Text("Couldn't create the flyer: $e")));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf({required bool print}) async {
    final state = ref.read(propertyReportProvider);
    final report = state.report;
    if (report == null) return;
    setState(() => _exporting = true);
    try {
      // The agent's own agency: its logo on every page, its colours throughout.
      final brand = ref.read(themeConfigProvider);
      final pdf = ValuationReportPdf(
        report: report,
        sitePlanSvg: state.sitePlanSvg,
        areaMapSvg: state.areaMapSvg,
        blockMapSvg: state.blockMapSvg,
        images: state.images,
        author: _author(),
        brandColor: brand.primaryColor,
        onBrandColor: brand.onPrimary,
        ownersPurchase: packOwnersPurchase(ref.read(propertyViewModelProvider)),
        logo: switch (await agencyLogoBytes(ref.read(agencyProvider))) {
          final bytes? => trimLogoBorder(bytes),
          null => null,
        },
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
        ).showSnack(SnackBar(content: Text("Couldn't create the PDF: $e")));
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
      busy: state.loading || _exporting || _savingSale,
      theme: theme,
      title: _exporting
          ? 'Creating the report pack…'
          : _savingSale
          ? 'Updating agent sales…'
          : 'Looking up the property…',
      messages: _exporting
          ? const [
              'Gathering the photos…',
              'Laying out the pages…',
              'Adding your letter…',
              'Almost there…',
            ]
          : _savingSale
          ? const ['Saving…', 'Refreshing the report…']
          : _lookupMessages,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Valuation report',
          theme: theme,
          onBack: () => context.pop(),
          actions: [
            if (report != null) ...[
              IconButton(
                tooltip: 'Print',
                icon: Icon(Icons.print_outlined, color: theme.textPrimary),
                onPressed: () => _exportPdf(print: true),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.textPrimary),
                onSelected: (_) => _regenerate(theme),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'regenerate',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Make a new report'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
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
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomButton(
                            text: 'Report pack',
                            fullWidth: true,
                            theme: theme,
                            onTap: _createPack,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // The buyer's brochure and the flyers.
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: 'For buyers',
                            fullWidth: true,
                            type: ButtonType.outline,
                            theme: theme,
                            onTap: _forBuyers,
                          ),
                        ),
                      ],
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
      'Market data comes from public municipal records — full reports in '
      'Cape Town and Johannesburg: municipal value, recorded '
      'sales nearby and the erf and building plans. In Tshwane, Mossel '
      'Bay and Drakenstein (Paarl, Wellington), the municipal value from '
      'your location.',
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
          ScaffoldMessenger.of(context).showSnack(
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
      if (state.generatedAt case final at?)
        Row(
          children: [
            Icon(Icons.history, size: 14, color: theme.textSecondary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Report generated ${timeAgo(at)}',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ),
            if (DateTime.now().difference(at) > _staleAfter)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _regenerate(theme),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
          ],
        ),
      gap,
      ValueRangeCard(report: r, theme: theme, textTheme: textTheme),
      if (r.coverageNote != null) ...[
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: theme.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                r.coverageNote!,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
      ..._fillListing(r, theme, textTheme),
      gap,
      if (state.blockMapSvg case final block?) ...[
        ReportCard(
          title: 'The property and its neighbourhood',
          theme: theme,
          textTheme: textTheme,
          children: [
            SitePlanView(svg: block, theme: theme, textTheme: textTheme),
          ],
        ),
        gap,
      ],
      if (state.areaMapSvg case final map?
          when r.includedComparables.isNotEmpty) ...[
        ReportCard(
          title: 'Where the comparable sales are',
          subtitle: 'Numbered as in the list of comparable sales',
          theme: theme,
          textTheme: textTheme,
          children: [
            SitePlanView(svg: map, theme: theme, textTheme: textTheme),
          ],
        ),
        gap,
      ],
      // An outline with no buildings says less than the block view above, so
      // it is left out then, as in the PDF.
      if (r.buildings.isNotEmpty || state.blockMapSvg == null)
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
      if (r.municipalValueZar != null) ...[
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
            fact(
              'Roll in effect from',
              r.rollEffectiveFrom == null
                  ? null
                  : DateFormat('d MMMM yyyy').format(r.rollEffectiveFrom!),
            ),
          ],
        ),
      ],
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
                    '${summary.medianPricePerDwellingM2 != null ? 'median ${formatZar(summary.medianPricePerDwellingM2)}/m² of building' : 'median ${formatZar(summary.medianPricePerErfM2)}/m² of erf'}',
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
      if (r.agentSales case final agent?) ...[
        gap,
        ReportCard(
          title: 'Sales reported by agents',
          subtitle: agent.evidenceStatement,
          theme: theme,
          textTheme: textTheme,
          children: [
            if (agent.sales.isNotEmpty)
              AgentSalesList(
                sales: agent.sales,
                theme: theme,
                textTheme: textTheme,
                onDelete: (s) => _deleteSale(s, theme),
              ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Log a sale you know about',
              type: ButtonType.outline,
              icon: Icon(Icons.add, color: theme.primaryColor),
              fullWidth: true,
              theme: theme,
              onTap: () => _logSale(r, theme),
            ),
          ],
        ),
      ],
      if (state.area case final area? when !area.isEmpty) ...[
        gap,
        AreaDetailsCard(area: area, theme: theme, textTheme: textTheme),
      ],
      if (state.forSale case final forSale?) ...[
        gap,
        ForSaleCard(
          forSale: forSale,
          theme: theme,
          textTheme: textTheme,
          onPickSuburb: (id) => ref
              .read(propertyReportProvider.notifier)
              .loadForSale(p24Suburb: id),
        ),
      ],
      if (state.market.isNotEmpty) ...[
        gap,
        ReportCard(
          title: 'Listed by your agency nearby',
          subtitle:
              "Your agency's listings in ${titleCase(r.suburb)}, with the "
              "agents' valuations",
          theme: theme,
          textTheme: textTheme,
          children: [
            MarketListingsList(
              listings: state.market,
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
        'Source: ${r.dataSource}'
        '${r.rollVersion == null ? '' : ' and the ${r.rollVersion} valuation roll'}, '
        'read ${DateFormat('d MMM yyyy').format(r.generatedAt.toLocal())}. '
        'An indicative range, not a certified valuation.',
        style: textTheme.bodySmall?.copyWith(color: theme.textSecondary),
      ),
    ];
  }
}
