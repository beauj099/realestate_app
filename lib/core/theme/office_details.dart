/// An office's details as the report pack prints them (header, letter,
/// footer). Every field is optional: an agent's own office fields fall back to
/// their agency's defaults field by field ([orDefaults]).
/// An office's logo variants (R2 URLs), for the report pack: a square
/// [mark], a [wide] logo for a light background, and a wide logo drawn for
/// the agency colour ([wideOnBrand], e.g. white on red).
class OfficeLogos {
  final String? mark;
  final String? wide;
  final String? wideOnBrand;

  const OfficeLogos({this.mark, this.wide, this.wideOnBrand});

  static const kinds = ['mark', 'wide', 'wideOnBrand'];

  String? operator [](String kind) => switch (kind) {
    'mark' => mark,
    'wide' => wide,
    'wideOnBrand' => wideOnBrand,
    _ => null,
  };

  OfficeLogos orDefaults(OfficeLogos d) => OfficeLogos(
    mark: mark ?? d.mark,
    wide: wide ?? d.wide,
    wideOnBrand: wideOnBrand ?? d.wideOnBrand,
  );

  factory OfficeLogos.fromJson(Map<String, dynamic>? j) => OfficeLogos(
    mark: j?['mark'] as String?,
    wide: j?['wide'] as String?,
    wideOnBrand: j?['wideOnBrand'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'mark': mark,
    'wide': wide,
    'wideOnBrand': wideOnBrand,
  };

  @override
  bool operator ==(Object other) =>
      other is OfficeLogos &&
      other.mark == mark &&
      other.wide == wide &&
      other.wideOnBrand == wideOnBrand;

  @override
  int get hashCode => Object.hash(mark, wide, wideOnBrand);
}

class OfficeDetails {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;

  /// The legal line printed at the foot of letters, e.g. "Directors: … ·
  /// Each office is independently owned and operated".
  final String footer;

  /// The office's slogan, top right of the "Your agent" page.
  final String slogan;

  /// The "Your agent" page heading after "YOUR"; a word in *asterisks* is
  /// printed in the agency colour. Empty uses [defaultHeadline].
  final String headline;

  /// Logo variants; uploaded separately, never sent with the text fields.
  final OfficeLogos logos;

  /// "serif" to set the report's headings in a serif (brands with a serif
  /// identity); empty for the body font.
  final String headingFont;

  static const defaultHeadline = 'residential & *lifestyle* realty partner';

  const OfficeDetails({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.footer = '',
    this.slogan = '',
    this.headline = '',
    this.logos = const OfficeLogos(),
    this.headingFont = '',
  });

  bool get isEmpty =>
      name.isEmpty &&
      address.isEmpty &&
      phone.isEmpty &&
      email.isEmpty &&
      website.isEmpty &&
      footer.isEmpty &&
      slogan.isEmpty &&
      headline.isEmpty &&
      headingFont.isEmpty;

  /// This office with each empty field taken from [defaults].
  OfficeDetails orDefaults(OfficeDetails defaults) => OfficeDetails(
    name: name.isNotEmpty ? name : defaults.name,
    address: address.isNotEmpty ? address : defaults.address,
    phone: phone.isNotEmpty ? phone : defaults.phone,
    email: email.isNotEmpty ? email : defaults.email,
    website: website.isNotEmpty ? website : defaults.website,
    footer: footer.isNotEmpty ? footer : defaults.footer,
    slogan: slogan.isNotEmpty ? slogan : defaults.slogan,
    headline: headline.isNotEmpty ? headline : defaults.headline,
    logos: logos.orDefaults(defaults.logos),
    headingFont: headingFont.isNotEmpty ? headingFont : defaults.headingFont,
  );

  OfficeDetails copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? footer,
    String? slogan,
    String? headline,
    OfficeLogos? logos,
    String? headingFont,
  }) => OfficeDetails(
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    website: website ?? this.website,
    footer: footer ?? this.footer,
    slogan: slogan ?? this.slogan,
    headline: headline ?? this.headline,
    logos: logos ?? this.logos,
    headingFont: headingFont ?? this.headingFont,
  );

  factory OfficeDetails.fromJson(Map<String, dynamic>? j) => OfficeDetails(
    name: j?['name'] as String? ?? '',
    address: j?['address'] as String? ?? '',
    phone: j?['phone'] as String? ?? '',
    email: j?['email'] as String? ?? '',
    website: j?['website'] as String? ?? '',
    footer: j?['footer'] as String? ?? '',
    slogan: j?['slogan'] as String? ?? '',
    headline: j?['headline'] as String? ?? '',
    logos: OfficeLogos.fromJson(j?['logos'] as Map<String, dynamic>?),
    headingFont: j?['headingFont'] as String? ?? '',
  );

  /// Empty strings are sent as "" so the API clears them.
  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'website': website,
    'footer': footer,
    'slogan': slogan,
    'headline': headline,
    'headingFont': headingFont,
  };

  /// For the device cache: the text fields and the logos.
  Map<String, dynamic> toCacheJson() => {...toJson(), 'logos': logos.toJson()};

  @override
  bool operator ==(Object other) =>
      other is OfficeDetails &&
      other.name == name &&
      other.address == address &&
      other.phone == phone &&
      other.email == email &&
      other.website == website &&
      other.footer == footer &&
      other.slogan == slogan &&
      other.headline == headline &&
      other.headingFont == headingFont &&
      other.logos == logos;

  @override
  int get hashCode => Object.hash(
    name,
    address,
    phone,
    email,
    website,
    footer,
    slogan,
    headline,
    logos,
    headingFont,
  );
}
