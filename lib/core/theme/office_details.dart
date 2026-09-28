/// An office's details as the report pack prints them (header, letter,
/// footer). Every field is optional: an agent's own office fields fall back to
/// their agency's defaults field by field ([orDefaults]).
class OfficeDetails {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;

  /// The legal line printed at the foot of letters, e.g. "Directors: … ·
  /// Each office is independently owned and operated".
  final String footer;

  const OfficeDetails({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.footer = '',
  });

  bool get isEmpty =>
      name.isEmpty &&
      address.isEmpty &&
      phone.isEmpty &&
      email.isEmpty &&
      website.isEmpty &&
      footer.isEmpty;

  /// This office with each empty field taken from [defaults].
  OfficeDetails orDefaults(OfficeDetails defaults) => OfficeDetails(
    name: name.isNotEmpty ? name : defaults.name,
    address: address.isNotEmpty ? address : defaults.address,
    phone: phone.isNotEmpty ? phone : defaults.phone,
    email: email.isNotEmpty ? email : defaults.email,
    website: website.isNotEmpty ? website : defaults.website,
    footer: footer.isNotEmpty ? footer : defaults.footer,
  );

  OfficeDetails copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? footer,
  }) => OfficeDetails(
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    website: website ?? this.website,
    footer: footer ?? this.footer,
  );

  factory OfficeDetails.fromJson(Map<String, dynamic>? j) => OfficeDetails(
    name: j?['name'] as String? ?? '',
    address: j?['address'] as String? ?? '',
    phone: j?['phone'] as String? ?? '',
    email: j?['email'] as String? ?? '',
    website: j?['website'] as String? ?? '',
    footer: j?['footer'] as String? ?? '',
  );

  /// Empty strings are sent as "" so the API clears them.
  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'website': website,
    'footer': footer,
  };

  @override
  bool operator ==(Object other) =>
      other is OfficeDetails &&
      other.name == name &&
      other.address == address &&
      other.phone == phone &&
      other.email == email &&
      other.website == website &&
      other.footer == footer;

  @override
  int get hashCode => Object.hash(name, address, phone, email, website, footer);
}
