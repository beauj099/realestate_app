/// The signed-in agent's registration details.
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
  final String licenceNumber;

  const AgentProfile({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.mobile = '',
    this.agencyName = '',
    this.agencySlug,
    this.agencyRegistrationNumber = '',
    this.licenceNumber = '',
  });

  String get fullName => '$firstName $lastName'.trim();

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
  };

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    var first = json['firstName'] as String? ?? '';
    var last = json['lastName'] as String? ?? '';
    // Caches written before the name was split hold only `fullName`.
    if (first.isEmpty && last.isEmpty) {
      (first, last) = splitName(json['fullName'] as String? ?? '');
    }
    return AgentProfile(
      firstName: first,
      lastName: last,
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      agencyName: json['agencyName'] as String? ?? '',
      agencySlug: json['agencySlug'] as String?,
      agencyRegistrationNumber:
          json['agencyRegistrationNumber'] as String? ?? '',
      licenceNumber: json['licenceNumber'] as String? ?? '',
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
    return AgentProfile(
      firstName: first,
      lastName: last,
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      agencyName: agencyName,
      // The API stores no slug; reuse the cached one only while the agency
      // name is unchanged, otherwise the caller resolves it from the name.
      agencySlug: cached?.agencyName == agencyName ? cached?.agencySlug : null,
      agencyRegistrationNumber:
          json['agencyRegistrationNumber'] as String? ?? '',
      licenceNumber: json['licenceNumber'] as String? ?? '',
    );
  }

  /// Body for `PUT /api/agents/me`.
  Map<String, dynamic> toApiJson() => {
    'displayName': fullName,
    'email': email,
    'mobile': mobile,
    'agencyName': agencyName.isEmpty ? null : agencyName,
    'agencyRegistrationNumber': agencyRegistrationNumber.isEmpty
        ? null
        : agencyRegistrationNumber,
    'licenceNumber': licenceNumber.isEmpty ? null : licenceNumber,
  };
}
