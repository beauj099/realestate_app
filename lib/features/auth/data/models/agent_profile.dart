import '../../../../core/theme/office_details.dart';
import '../../../report_settings/data/models/report_settings.dart';

export '../../../../core/theme/office_details.dart';

/// The signed-in agent's registration details, and what the report pack
/// prints about them.
///
/// The server copy (`GET`/`PUT /api/agents/me`) is the source of truth; the
/// copy kept on the device is a cache so the profile shows offline and first
/// and last name survive a round trip — the API stores one full name only.
class AgentProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String agencyName;

  /// Slug of the white-label agency, when the name matched one.
  final String? agencySlug;

  final String agencyRegistrationNumber;

  /// The agent's FFC (Fidelity Fund Certificate) number.
  final String licenceNumber;

  final String ppraNumber;
  final String jobTitle;
  final String bio;
  final List<String> qualifications;
  final String website;

  /// Profile photo and signature (R2 URLs), shown in the report pack.
  final String? photoUrl;
  final String? signatureUrl;

  /// The agent's own office details; empty fields use the agency's.
  final OfficeDetails office;

  /// The agent's own brochure pages; null uses the agency's.
  final List<String>? brochurePages;

  final ReportSettings reportSettings;

  const AgentProfile({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.mobile = '',
    this.agencyName = '',
    this.agencySlug,
    this.agencyRegistrationNumber = '',
    this.licenceNumber = '',
    this.ppraNumber = '',
    this.jobTitle = '',
    this.bio = '',
    this.qualifications = const [],
    this.website = '',
    this.photoUrl,
    this.signatureUrl,
    this.office = const OfficeDetails(),
    this.brochurePages,
    this.reportSettings = const ReportSettings(),
  });

  String get fullName => '$firstName $lastName'.trim();

  /// Up to two initials for a photo placeholder, e.g. "Collin Bruwer" -> "CB".
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  bool get isEmpty =>
      fullName.isEmpty &&
      email.isEmpty &&
      mobile.isEmpty &&
      agencyName.isEmpty &&
      agencyRegistrationNumber.isEmpty &&
      licenceNumber.isEmpty;

  /// Splits a full name at the first space: "Jan van der Merwe" becomes
  /// "Jan" + "van der Merwe".
  static (String, String) splitName(String fullName) {
    final trimmed = fullName.trim();
    final space = trimmed.indexOf(RegExp(r'\s'));
    if (space == -1) return (trimmed, '');
    return (trimmed.substring(0, space), trimmed.substring(space + 1).trim());
  }

  AgentProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? agencyName,
    String? agencySlug,
    String? agencyRegistrationNumber,
    String? licenceNumber,
    String? ppraNumber,
    String? jobTitle,
    String? bio,
    List<String>? qualifications,
    String? website,
    String? photoUrl,
    String? signatureUrl,
    OfficeDetails? office,
    List<String>? brochurePages,
    bool clearBrochurePages = false,
    ReportSettings? reportSettings,
  }) {
    return AgentProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      agencyName: agencyName ?? this.agencyName,
      agencySlug: agencySlug ?? this.agencySlug,
      agencyRegistrationNumber:
          agencyRegistrationNumber ?? this.agencyRegistrationNumber,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      ppraNumber: ppraNumber ?? this.ppraNumber,
      jobTitle: jobTitle ?? this.jobTitle,
      bio: bio ?? this.bio,
      qualifications: qualifications ?? this.qualifications,
      website: website ?? this.website,
      photoUrl: photoUrl ?? this.photoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      office: office ?? this.office,
      brochurePages: clearBrochurePages
          ? null
          : brochurePages ?? this.brochurePages,
      reportSettings: reportSettings ?? this.reportSettings,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'mobile': mobile,
    'agencyName': agencyName,
    'agencySlug': agencySlug,
    'agencyRegistrationNumber': agencyRegistrationNumber,
    'licenceNumber': licenceNumber,
    'ppraNumber': ppraNumber,
    'jobTitle': jobTitle,
    'bio': bio,
    'qualifications': qualifications,
    'website': website,
    'photoUrl': photoUrl,
    'signatureUrl': signatureUrl,
    'office': office.toCacheJson(),
    'brochurePages': brochurePages,
    'reportSettings': reportSettings.toJson(),
  };

  static List<String>? _strings(Object? v) =>
      v is List ? [for (final e in v) e.toString()] : null;

  /// The report-pack fields, shared by the cache and the API shapes.
  static AgentProfile _withPackFields(
    AgentProfile base,
    Map<String, dynamic> json,
  ) => base.copyWith(
    ppraNumber: json['ppraNumber'] as String? ?? '',
    jobTitle: json['jobTitle'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    qualifications: _strings(json['qualifications']) ?? const [],
    website: json['website'] as String? ?? '',
    photoUrl: json['photoUrl'] as String?,
    signatureUrl: json['signatureUrl'] as String?,
    office: OfficeDetails.fromJson(json['office'] as Map<String, dynamic>?),
    brochurePages: _strings(json['brochurePages']),
    reportSettings: ReportSettings.fromJson(
      json['reportSettings'] as Map<String, dynamic>?,
    ),
  );

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    var first = json['firstName'] as String? ?? '';
    var last = json['lastName'] as String? ?? '';
    // Caches written before the name was split hold only `fullName`.
    if (first.isEmpty && last.isEmpty) {
      (first, last) = splitName(json['fullName'] as String? ?? '');
    }
    return _withPackFields(
      AgentProfile(
        firstName: first,
        lastName: last,
        email: json['email'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        agencyName: json['agencyName'] as String? ?? '',
        agencySlug: json['agencySlug'] as String?,
        agencyRegistrationNumber:
            json['agencyRegistrationNumber'] as String? ?? '',
        licenceNumber: json['licenceNumber'] as String? ?? '',
      ),
      json,
    );
  }

  /// Maps an `AgentProfileDto` from the API.
  ///
  /// The API holds a single display name, so a cached first/last split is kept
  /// when it still spells the same name — otherwise "Mary Anne" + "Smith"
  /// would come back as "Mary" + "Anne Smith".
  factory AgentProfile.fromApi(
    Map<String, dynamic> json, {
    AgentProfile? cached,
  }) {
    final displayName = (json['displayName'] as String? ?? '').trim();
    final keepSplit = cached != null && cached.fullName == displayName;
    final (first, last) = keepSplit
        ? (cached.firstName, cached.lastName)
        : splitName(displayName);
    final agencyName = json['agencyName'] as String? ?? '';
    return _withPackFields(
      AgentProfile(
        firstName: first,
        lastName: last,
        email: json['email'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        agencyName: agencyName,
        // The API's slug wins; else the cached one while the agency name is
        // unchanged; otherwise the caller resolves it from the name.
        agencySlug:
            json['agencySlug'] as String? ??
            (cached?.agencyName == agencyName ? cached?.agencySlug : null),
        agencyRegistrationNumber:
            json['agencyRegistrationNumber'] as String? ?? '',
        licenceNumber: json['licenceNumber'] as String? ?? '',
      ),
      json,
    );
  }

  /// Body for `PUT /api/agents/me`. Photo, signature, brochure pages and
  /// report settings have their own endpoints.
  Map<String, dynamic> toApiJson() => {
    'displayName': fullName,
    'email': email,
    'mobile': mobile,
    'agencyName': agencyName.isEmpty ? null : agencyName,
    'agencyRegistrationNumber': agencyRegistrationNumber.isEmpty
        ? null
        : agencyRegistrationNumber,
    'licenceNumber': licenceNumber.isEmpty ? null : licenceNumber,
    // Report-pack fields: "" clears a field on the server.
    'agencySlug': agencySlug ?? '',
    'ppraNumber': ppraNumber,
    'jobTitle': jobTitle,
    'bio': bio,
    'qualifications': qualifications,
    'website': website,
    'office': office.toJson(),
  };
}
