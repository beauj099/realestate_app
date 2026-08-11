class Contact {
  final String id;
  final String fullName;
  final String idNumber;
  final String companyName;
  final String companyRegistrationNumber;
  final String mobilePhone;
  final String emailAddress;
  final String role;

  const Contact({
    this.id = '',
    this.fullName = '',
    this.idNumber = '',
    this.companyName = '',
    this.companyRegistrationNumber = '',
    this.mobilePhone = '',
    this.emailAddress = '',
    this.role = '',
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
    );
  }
}
