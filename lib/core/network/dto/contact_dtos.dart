class AddContactRequest {
  final String? fullName;
  final String? idNumber;
  final String? companyName;
  final String? companyRegistrationNumber;
  final String? mobilePhone;
  final String? emailAddress;
  final String? role;

  const AddContactRequest({
    this.fullName,
    this.idNumber,
    this.companyName,
    this.companyRegistrationNumber,
    this.mobilePhone,
    this.emailAddress,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        if (fullName != null && fullName!.isNotEmpty) 'fullName': fullName,
        if (idNumber != null && idNumber!.isNotEmpty) 'idNumber': idNumber,
        if (companyName != null && companyName!.isNotEmpty)
          'companyName': companyName,
        if (companyRegistrationNumber != null &&
            companyRegistrationNumber!.isNotEmpty)
          'companyRegistrationNumber': companyRegistrationNumber,
        if (mobilePhone != null && mobilePhone!.isNotEmpty)
          'mobilePhone': mobilePhone,
        if (emailAddress != null && emailAddress!.isNotEmpty)
          'emailAddress': emailAddress,
        if (role != null && role!.isNotEmpty) 'role': role,
      };
}

class UpdateContactRequest {
  final String? fullName;
  final String? idNumber;
  final String? companyName;
  final String? companyRegistrationNumber;
  final String? mobilePhone;
  final String? emailAddress;
  final String? role;

  const UpdateContactRequest({
    this.fullName,
    this.idNumber,
    this.companyName,
    this.companyRegistrationNumber,
    this.mobilePhone,
    this.emailAddress,
    this.role,
  });

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (idNumber != null) 'idNumber': idNumber,
        if (companyName != null) 'companyName': companyName,
        if (companyRegistrationNumber != null)
          'companyRegistrationNumber': companyRegistrationNumber,
        if (mobilePhone != null) 'mobilePhone': mobilePhone,
        if (emailAddress != null) 'emailAddress': emailAddress,
        if (role != null) 'role': role,
      };
}

class ContactDto {
  final int id;
  final String? fullName;
  final String? idNumber;
  final String? companyName;
  final String? companyRegistrationNumber;
  final String? mobilePhone;
  final String? emailAddress;
  final String? role;
  final int listingId;

  const ContactDto({
    required this.id,
    this.fullName,
    this.idNumber,
    this.companyName,
    this.companyRegistrationNumber,
    this.mobilePhone,
    this.emailAddress,
    this.role,
    required this.listingId,
  });

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    return ContactDto(
      id: json['id'] as int,
      fullName: json['fullName'] as String?,
      idNumber: json['idNumber'] as String?,
      companyName: json['companyName'] as String?,
      companyRegistrationNumber:
          json['companyRegistrationNumber'] as String?,
      mobilePhone: json['mobilePhone'] as String?,
      emailAddress: json['emailAddress'] as String?,
      role: json['role'] as String?,
      listingId: json['listingId'] as int,
    );
  }
}
