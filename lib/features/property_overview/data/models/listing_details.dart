import 'dart:convert';

/// The listing's further details from the myEdge listing form that have no
/// home of their own: ownership and subtype, construction and views, the
/// overall condition, renovations, billing, letting, portal references and
/// the mandate information. Kept by the API as one JSON object
/// (`Listings.DetailsJson`, `PUT /api/listings/{id}/details`).
///
/// The option lists are the form's own wording.
class ListingDetails {
  // ---- Property info -------------------------------------------------------
  final String ownershipType;
  final String subtype;
  final bool forLet;
  final String listingTitle;

  // ---- Building ------------------------------------------------------------
  final String style;
  final List<String> roof;
  final List<String> walls;
  final List<String> windows;
  final List<String> views;
  final String heightRestriction;

  /// The home as a whole, on the CMA tools' seven-step scale
  /// ([overallConditions]); empty until set.
  final String overallCondition;
  final String specialFeatures;
  final bool subdivisionRights;
  final List<Renovation> renovations;

  // ---- Running costs -------------------------------------------------------
  /// "Prepaid" or "Billed".
  final String electricityBilling;

  /// "Included in levy" or "Billed separately".
  final String waterBilling;

  // ---- Mandate and letting -------------------------------------------------
  final String mandateType;
  final DateTime? mandateSigned;
  final DateTime? mandateExpiry;
  final DateTime? occupationDate;
  final String mandateSource;
  final String referralName;
  final String referralPhone;
  final String referralPercent;
  final String reasonForSelling;
  final String includedItems;
  final String excludedItems;
  final String defects;
  final String currentRental;
  final DateTime? leaseExpiry;
  final String tenantViewing;

  // ---- Portals -------------------------------------------------------------
  final String kwlRef;
  final String p24Ref;
  final String entegralRef;
  final List<String> display;

  const ListingDetails({
    this.ownershipType = '',
    this.subtype = '',
    this.forLet = false,
    this.listingTitle = '',
    this.style = '',
    this.roof = const [],
    this.walls = const [],
    this.windows = const [],
    this.views = const [],
    this.heightRestriction = '',
    this.overallCondition = '',
    this.specialFeatures = '',
    this.subdivisionRights = false,
    this.renovations = const [],
    this.electricityBilling = '',
    this.waterBilling = '',
    this.mandateType = '',
    this.mandateSigned,
    this.mandateExpiry,
    this.occupationDate,
    this.mandateSource = '',
    this.referralName = '',
    this.referralPhone = '',
    this.referralPercent = '',
    this.reasonForSelling = '',
    this.includedItems = '',
    this.excludedItems = '',
    this.defects = '',
    this.currentRental = '',
    this.leaseExpiry,
    this.tenantViewing = '',
    this.kwlRef = '',
    this.p24Ref = '',
    this.entegralRef = '',
    this.display = const [],
  });

  static const ownershipTypes = [
    'Full Title',
    'Sectional Title',
    'Share Block',
    'Lease Hold',
    'Fractional',
    'Time Share',
  ];
  static const subtypes = [
    'Free Standing',
    'Cluster Home',
    'Simplex',
    'Duplex',
    'Single Storey',
    'Double Storey',
    'Multi Storey',
    'Duet',
    'Semi Detached',
    'Guest House',
    'Villa',
  ];
  static const styles = [
    'A-Frame',
    'Architect Design',
    'Balinese',
    'Cape Dutch',
    'Colonial',
    'Contemporary',
    'Conventional',
    'Mediterranean',
    'Modern',
    'Spanish',
    'Split Level',
    'Tuscan',
    'Victorian',
  ];
  static const roofs = [
    'Aluminium',
    'Asbestos',
    'Concrete',
    'Fibre Glass',
    'Flat Roof',
    'Glass Dome',
    'Insulation',
    'Iron',
    'Slate',
    'Thatch',
    'Tile',
    'Waterproofing',
    'Zinc',
  ];
  static const wallTypes = [
    'Asbestos',
    'Brick',
    'Concrete',
    'Face Brick',
    'Iron',
    'Plaster',
    'Stone',
    'Wood',
  ];
  static const windowTypes = [
    'Aluminium',
    'Bay',
    'Cottage',
    'Double Glaze',
    'Lead',
    'Skylight',
    'Stained',
    'Steel',
    'Wood',
  ];
  static const viewOptions = [
    'Green Belt',
    'Mountain View',
    'Sea View',
    'Street Front',
  ];

  /// Worst to best, as CMA tools rate a home.
  static const overallConditions = [
    'To Remodel',
    'To Renovate',
    'Average',
    'Good',
    'Very Good',
    'Excellent',
    'Exceptional',
  ];
  static const electricityOptions = ['Prepaid', 'Billed'];
  static const waterOptions = ['Included in levy', 'Billed separately'];
  static const mandateTypes = [
    'Sole Mandate',
    'Exclusive Mandate',
    'Open Mandate',
    'Dual Mandate',
    'Multi Listing',
  ];
  static const mandateSources = [
    'Canvassing',
    'For Sale Board',
    'Personal Contact',
    'Phone in',
    'Referral',
    'Show House',
    'Walk in',
    'Website',
    'Other',
  ];
  static const displayOptions = [
    'Display on Website',
    'Feed to Property 24',
    'Feed to Entegral',
  ];

  ListingDetails copyWith({
    String? ownershipType,
    String? subtype,
    bool? forLet,
    String? listingTitle,
    String? style,
    List<String>? roof,
    List<String>? walls,
    List<String>? windows,
    List<String>? views,
    String? heightRestriction,
    String? overallCondition,
    String? specialFeatures,
    bool? subdivisionRights,
    List<Renovation>? renovations,
    String? electricityBilling,
    String? waterBilling,
    String? mandateType,
    DateTime? mandateSigned,
    DateTime? mandateExpiry,
    DateTime? occupationDate,
    bool clearMandateSigned = false,
    bool clearMandateExpiry = false,
    bool clearOccupationDate = false,
    String? mandateSource,
    String? referralName,
    String? referralPhone,
    String? referralPercent,
    String? reasonForSelling,
    String? includedItems,
    String? excludedItems,
    String? defects,
    String? currentRental,
    DateTime? leaseExpiry,
    bool clearLeaseExpiry = false,
    String? tenantViewing,
    String? kwlRef,
    String? p24Ref,
    String? entegralRef,
    List<String>? display,
  }) => ListingDetails(
    ownershipType: ownershipType ?? this.ownershipType,
    subtype: subtype ?? this.subtype,
    forLet: forLet ?? this.forLet,
    listingTitle: listingTitle ?? this.listingTitle,
    style: style ?? this.style,
    roof: roof ?? this.roof,
    walls: walls ?? this.walls,
    windows: windows ?? this.windows,
    views: views ?? this.views,
    heightRestriction: heightRestriction ?? this.heightRestriction,
    overallCondition: overallCondition ?? this.overallCondition,
    specialFeatures: specialFeatures ?? this.specialFeatures,
    subdivisionRights: subdivisionRights ?? this.subdivisionRights,
    renovations: renovations ?? this.renovations,
    electricityBilling: electricityBilling ?? this.electricityBilling,
    waterBilling: waterBilling ?? this.waterBilling,
    mandateType: mandateType ?? this.mandateType,
    mandateSigned: clearMandateSigned
        ? null
        : mandateSigned ?? this.mandateSigned,
    mandateExpiry: clearMandateExpiry
        ? null
        : mandateExpiry ?? this.mandateExpiry,
    occupationDate: clearOccupationDate
        ? null
        : occupationDate ?? this.occupationDate,
    mandateSource: mandateSource ?? this.mandateSource,
    referralName: referralName ?? this.referralName,
    referralPhone: referralPhone ?? this.referralPhone,
    referralPercent: referralPercent ?? this.referralPercent,
    reasonForSelling: reasonForSelling ?? this.reasonForSelling,
    includedItems: includedItems ?? this.includedItems,
    excludedItems: excludedItems ?? this.excludedItems,
    defects: defects ?? this.defects,
    currentRental: currentRental ?? this.currentRental,
    leaseExpiry: clearLeaseExpiry ? null : leaseExpiry ?? this.leaseExpiry,
    tenantViewing: tenantViewing ?? this.tenantViewing,
    kwlRef: kwlRef ?? this.kwlRef,
    p24Ref: p24Ref ?? this.p24Ref,
    entegralRef: entegralRef ?? this.entegralRef,
    display: display ?? this.display,
  );

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() {
    final j = <String, dynamic>{
      'ownershipType': ownershipType,
      'subtype': subtype,
      'forLet': forLet,
      'listingTitle': listingTitle,
      'style': style,
      'roof': roof,
      'walls': walls,
      'windows': windows,
      'views': views,
      'heightRestriction': heightRestriction,
      'overallCondition': overallCondition,
      'specialFeatures': specialFeatures,
      'subdivisionRights': subdivisionRights,
      'renovations': [for (final r in renovations) r.toJson()],
      'electricityBilling': electricityBilling,
      'waterBilling': waterBilling,
      'mandateType': mandateType,
      'mandateSigned': mandateSigned == null ? null : _day(mandateSigned!),
      'mandateExpiry': mandateExpiry == null ? null : _day(mandateExpiry!),
      'occupationDate': occupationDate == null ? null : _day(occupationDate!),
      'mandateSource': mandateSource,
      'referralName': referralName,
      'referralPhone': referralPhone,
      'referralPercent': referralPercent,
      'reasonForSelling': reasonForSelling,
      'includedItems': includedItems,
      'excludedItems': excludedItems,
      'defects': defects,
      'currentRental': currentRental,
      'leaseExpiry': leaseExpiry == null ? null : _day(leaseExpiry!),
      'tenantViewing': tenantViewing,
      'kwlRef': kwlRef,
      'p24Ref': p24Ref,
      'entegralRef': entegralRef,
      'display': display,
    };
    // Only what is set: the JSON stays small and readable.
    j.removeWhere(
      (_, v) =>
          v == null ||
          v == false ||
          (v is String && v.trim().isEmpty) ||
          (v is List && v.isEmpty),
    );
    return j;
  }

  factory ListingDetails.fromJson(Map<String, dynamic> j) {
    String s(String k) => j[k]?.toString() ?? '';
    List<String> l(String k) => [
      for (final v in (j[k] as List? ?? const [])) v.toString(),
    ];
    DateTime? d(String k) => DateTime.tryParse(s(k));
    return ListingDetails(
      ownershipType: s('ownershipType'),
      subtype: s('subtype'),
      forLet: j['forLet'] == true,
      listingTitle: s('listingTitle'),
      style: s('style'),
      roof: l('roof'),
      walls: l('walls'),
      windows: l('windows'),
      views: l('views'),
      heightRestriction: s('heightRestriction'),
      overallCondition: s('overallCondition'),
      specialFeatures: s('specialFeatures'),
      subdivisionRights: j['subdivisionRights'] == true,
      renovations: [
        for (final r in (j['renovations'] as List? ?? const []))
          if (r is Map<String, dynamic>) Renovation.fromJson(r),
      ],
      electricityBilling: s('electricityBilling'),
      waterBilling: s('waterBilling'),
      mandateType: s('mandateType'),
      mandateSigned: d('mandateSigned'),
      mandateExpiry: d('mandateExpiry'),
      occupationDate: d('occupationDate'),
      mandateSource: s('mandateSource'),
      referralName: s('referralName'),
      referralPhone: s('referralPhone'),
      referralPercent: s('referralPercent'),
      reasonForSelling: s('reasonForSelling'),
      includedItems: s('includedItems'),
      excludedItems: s('excludedItems'),
      defects: s('defects'),
      currentRental: s('currentRental'),
      leaseExpiry: d('leaseExpiry'),
      tenantViewing: s('tenantViewing'),
      kwlRef: s('kwlRef'),
      p24Ref: s('p24Ref'),
      entegralRef: s('entegralRef'),
      display: l('display'),
    );
  }

  /// From the API's JSON text; empty details when there is none or it is
  /// unreadable.
  static ListingDetails parse(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const ListingDetails();
    try {
      return ListingDetails.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ListingDetails();
    }
  }

  String encode() => jsonEncode(toJson());

  /// Anything captured on the Mandate & Listing screen.
  bool get hasMandateInfo =>
      mandateType.isNotEmpty ||
      mandateSigned != null ||
      mandateExpiry != null ||
      mandateSource.isNotEmpty;
}

/// Work done on the home: when, what it cost, and what was done ("2019,
/// R 360 000, kitchen, both bathrooms, floors & carport").
class Renovation {
  final int? year;
  final String amount;
  final String description;

  const Renovation({this.year, this.amount = '', this.description = ''});

  Renovation copyWith({int? year, String? amount, String? description}) =>
      Renovation(
        year: year ?? this.year,
        amount: amount ?? this.amount,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
    'year': ?year,
    if (amount.trim().isNotEmpty) 'amount': amount.trim(),
    if (description.trim().isNotEmpty) 'description': description.trim(),
  };

  factory Renovation.fromJson(Map<String, dynamic> j) => Renovation(
    year: (j['year'] as num?)?.toInt(),
    amount: j['amount']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
  );
}
