/// The registration details belonging to the signed-in agent.
///
/// The backend currently stores only username/display name/role, and exposes
/// no endpoint to read or update the rest, so these fields live on the device.
/// Once `GET`/`PUT /api/agents/me` ship (see `docs/BACKEND_CHANGES.md`) this
/// model becomes the DTO for those calls and the local copy becomes a cache.
class AgentProfile {
  final String fullName;
  final String email;
  final String mobile;
  final String agencyName;

  /// Slug of the white-label agency, when the typed name matched one.
  final String? agencySlug;

  final String agencyRegistrationNumber;
  final String licenceNumber;

  const AgentProfile({
    this.fullName = '',
    this.email = '',
    this.mobile = '',
    this.agencyName = '',
    this.agencySlug,
    this.agencyRegistrationNumber = '',
    this.licenceNumber = '',
  });

  bool get isEmpty =>
      fullName.isEmpty &&
      email.isEmpty &&
      mobile.isEmpty &&
      agencyName.isEmpty &&
      agencyRegistrationNumber.isEmpty &&
      licenceNumber.isEmpty;

  AgentProfile copyWith({
    String? fullName,
    String? email,
    String? mobile,
    String? agencyName,
    String? agencySlug,
    String? agencyRegistrationNumber,
    String? licenceNumber,
  }) {
    return AgentProfile(
      fullName: fullName ?? this.fullName,
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
    'fullName': fullName,
    'email': email,
    'mobile': mobile,
    'agencyName': agencyName,
    'agencySlug': agencySlug,
    'agencyRegistrationNumber': agencyRegistrationNumber,
    'licenceNumber': licenceNumber,
  };

  factory AgentProfile.fromJson(Map<String, dynamic> json) => AgentProfile(
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    mobile: json['mobile'] as String? ?? '',
    agencyName: json['agencyName'] as String? ?? '',
    agencySlug: json['agencySlug'] as String?,
    agencyRegistrationNumber:
        json['agencyRegistrationNumber'] as String? ?? '',
    licenceNumber: json['licenceNumber'] as String? ?? '',
  );
}
