/// Whether an owner is a person or a registered entity.
///
/// Not persisted: the backend `Contact` table has no owner-type column, and the
/// two modes write disjoint fields, so the type is derived on load from whether
/// company details are present. Adding a real column is tracked in
/// `docs/BACKEND_CHANGES.md`.
enum OwnerType {
  naturalPerson('Natural person'),
  business('Business');

  final String label;
  const OwnerType(this.label);
}

class Contact {
  final String id;
  final String fullName;
  final String idNumber;
  final String companyName;
  final String companyRegistrationNumber;
  final String mobilePhone;
  final String emailAddress;
  final String role;

  /// Owner type the agent picked, when they picked one.
  ///
  /// UI-only and never serialised — see [OwnerType].
  final OwnerType? selectedOwnerType;

  const Contact({
    this.id = '',
    this.fullName = '',
    this.idNumber = '',
    this.companyName = '',
    this.companyRegistrationNumber = '',
    this.mobilePhone = '',
    this.emailAddress = '',
    this.role = '',
    this.selectedOwnerType,
  });

  Contact copyWith({
    String? id,
    String? fullName,
    String? idNumber,
    String? companyName,
    String? companyRegistrationNumber,
    String? mobilePhone,
    String? emailAddress,
    String? role,
    OwnerType? selectedOwnerType,
  }) {
    return Contact(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      idNumber: idNumber ?? this.idNumber,
      companyName: companyName ?? this.companyName,
      companyRegistrationNumber: companyRegistrationNumber ?? this.companyRegistrationNumber,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      emailAddress: emailAddress ?? this.emailAddress,
      role: role ?? this.role,
      selectedOwnerType: selectedOwnerType ?? this.selectedOwnerType,
    );
  }

  /// The owner type currently being edited.
  ///
  /// Falls back to inferring from the company fields, which is how a contact
  /// loaded from the API resolves — the backend stores no owner-type column.
  OwnerType get ownerType =>
      selectedOwnerType ??
      (companyName.trim().isNotEmpty ||
              companyRegistrationNumber.trim().isNotEmpty
          ? OwnerType.business
          : OwnerType.naturalPerson);

  /// Returns this contact switched to [type], clearing the fields the other
  /// type owns so a switched-away entity never posts stale mixed details.
  Contact asOwnerType(OwnerType type) {
    return Contact(
      id: id,
      fullName: fullName,
      idNumber: type == OwnerType.naturalPerson ? idNumber : '',
      companyName: type == OwnerType.business ? companyName : '',
      companyRegistrationNumber: type == OwnerType.business
          ? companyRegistrationNumber
          : '',
      mobilePhone: mobilePhone,
      emailAddress: emailAddress,
      role: role,
      selectedOwnerType: type,
    );
  }
}
