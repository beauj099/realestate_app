import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/locale/countries.dart';
import '../../../../core/validation/phone_format.dart';
import '../../../../core/validation/sa_formats.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../data/models/contact.dart';

/// Owner capture form.
///
/// An owner is either a person or a registered entity, never both, so the type
/// is chosen first and only that type's fields are shown. Previously every
/// owner saw ID number *and* company registration number and had to work out
/// which applied.
///
/// Only a business asks for a role, as the contact person's capacity
/// (director, trustee, member) — it is what shows they may sign for the
/// entity. A natural person listed here is the owner, so the field added
/// nothing for them. A role already stored on a person is kept untouched.
class ContactFields extends StatelessWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final Contact contact;

  /// The agent's country: sets the phone prefix and rules, and whether the
  /// South African ID format applies.
  final Country country;
  final ValueChanged<Contact> onChanged;

  /// Field errors keyed `name`, `company`, `id`, `email`, `phone` — see
  /// [validateContact].
  final Map<String, String> errors;

  const ContactFields({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.contact,
    required this.country,
    required this.onChanged,
    this.errors = const {},
  });

  @override
  Widget build(BuildContext context) {
    final ownerType = contact.ownerType;
    final isBusiness = ownerType == OwnerType.business;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OwnerTypeToggle(
          selected: ownerType,
          theme: theme,
          textTheme: textTheme,
          onChanged: (type) => onChanged(contact.asOwnerType(type)),
        ),
        const SizedBox(height: 16),
        if (isBusiness) ...[
          CustomTextInput(
            theme: theme,
            label: 'COMPANY NAME',
            textCapitalization: TextCapitalization.words,
            placeholder: 'Acme Properties Pty Ltd',
            initialValue: contact.companyName,
            errorText: errors['company'],
            onChanged: (val) => onChanged(contact.copyWith(companyName: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'REGISTRATION NUMBER',
            keyboardType: TextInputType.datetime,
            placeholder: 'e.g. 2021/123456/07',
            initialValue: contact.companyRegistrationNumber,
            onChanged: (val) =>
                onChanged(contact.copyWith(companyRegistrationNumber: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'CONTACT PERSON',
            textCapitalization: TextCapitalization.words,
            placeholder: 'Who signs for the company',
            initialValue: contact.fullName,
            autofillHints: const [AutofillHints.name],
            errorText: errors['name'],
            onChanged: (val) => onChanged(contact.copyWith(fullName: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'CAPACITY',
            textCapitalization: TextCapitalization.words,
            placeholder: 'e.g. Director, Trustee, Member',
            initialValue: contact.role,
            onChanged: (val) => onChanged(contact.copyWith(role: val)),
          ),
        ] else ...[
          CustomTextInput(
            theme: theme,
            label: 'FULL NAME',
            textCapitalization: TextCapitalization.words,
            placeholder: 'John Doe',
            initialValue: contact.fullName,
            autofillHints: const [AutofillHints.name],
            errorText: errors['name'],
            onChanged: (val) => onChanged(contact.copyWith(fullName: val)),
          ),
          const SizedBox(height: 16),
          // South African ID: typed as digits only, shown as YYMMDD GGGG CCC
          // and checked. Other countries: any ID or passport, as typed.
          if (country.isoCode == Country.defaultIsoCode)
            CustomTextInput(
              theme: theme,
              label: 'ID NUMBER',
              placeholder: 'YYMMDD GGGG CCC',
              initialValue: SaIdNumber.format(contact.idNumber),
              keyboardType: TextInputType.number,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                GroupedDigitsFormatter(const [6, 4, 3]),
              ],
              errorText: errors['id'],
              subtext: _idSummary(contact.idNumber),
              onChanged: (val) => onChanged(
                contact.copyWith(idNumber: SaIdNumber.digitsOnly(val)),
              ),
            )
          else
            CustomTextInput(
              theme: theme,
              label: 'ID / PASSPORT NUMBER',
              initialValue: contact.idNumber,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              errorText: errors['id'],
              onChanged: (val) =>
                  onChanged(contact.copyWith(idNumber: val.trim())),
            ),
        ],
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'EMAIL ADDRESS',
          placeholder: 'john.doe@example.com',
          initialValue: contact.emailAddress,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          enableSuggestions: false,
          errorText: errors['email'],
          onChanged: (val) => onChanged(contact.copyWith(emailAddress: val)),
        ),
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'PHONE NUMBER',
          placeholder: '82 123 4567',
          initialValue: CountryPhone.format(contact.mobilePhone, country),
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [CountryPhone.inputFormatter(country)],
          prefixIcon: PhonePrefix(country: country, theme: theme),
          errorText: errors['phone'],
          onChanged: (val) => onChanged(
            contact.copyWith(mobilePhone: CountryPhone.toStored(val, country)),
          ),
        ),
      ],
    );
  }
}

/// Segmented person/business switch.
class _OwnerTypeToggle extends StatelessWidget {
  final OwnerType selected;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<OwnerType> onChanged;

  const _OwnerTypeToggle({
    required this.selected,
    required this.theme,
    required this.textTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.borderLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: OwnerType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.cardBackgroundColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: isSelected
                      ? Border.all(color: theme.primaryColor, width: 1.4)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == OwnerType.business
                          ? Icons.domain_outlined
                          : Icons.person_outline,
                      size: 18,
                      color: isSelected
                          ? theme.primaryColor
                          : theme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// "Born 6 Dec 1983 · Female · SA citizen" once the ID number is valid.
String? _idSummary(String idNumber) {
  final info = SaIdNumber.parse(idNumber);
  if (info == null) return null;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final dob = info.dateOfBirth;
  return [
    'Born ${dob.day} ${months[dob.month - 1]} ${dob.year}',
    info.isFemale ? 'Female' : 'Male',
    info.isCitizen ? 'SA citizen' : 'Permanent resident',
  ].join(' · ');
}

/// Field errors for one owner, keyed `name`, `company`, `id`, `email`,
/// `phone`; empty when the owner is fine.
///
/// The primary owner must have a name, email and phone (and a company name
/// for a business). For every owner, whatever *is* filled in must be valid.
Map<String, String> validateContact(
  Contact c, {
  required bool isPrimary,
  Country? country,
}) {
  final region = country ?? Country.southAfrica;
  final errors = <String, String>{};
  final isBusiness = c.ownerType == OwnerType.business;
  if (isPrimary) {
    if (c.fullName.trim().isEmpty) {
      errors['name'] = isBusiness
          ? 'Contact person is required'
          : 'Full name is required';
    }
    if (isBusiness && c.companyName.trim().isEmpty) {
      errors['company'] = 'Company name is required';
    }
    if (c.emailAddress.trim().isEmpty) errors['email'] = 'Email is required';
    if (c.mobilePhone.trim().isEmpty) errors['phone'] = 'Phone is required';
  }
  // The ID checks are South Africa's; elsewhere any ID/passport is kept as
  // typed.
  if (!isBusiness &&
      c.idNumber.trim().isNotEmpty &&
      region.isoCode == Country.defaultIsoCode) {
    final idError = SaIdNumber.validate(c.idNumber);
    if (idError != null) errors['id'] = idError;
  }
  if (c.emailAddress.trim().isNotEmpty && !isValidEmail(c.emailAddress)) {
    errors['email'] = 'Enter a valid email address';
  }
  if (c.mobilePhone.trim().isNotEmpty) {
    final phoneError = CountryPhone.validate(c.mobilePhone, region);
    if (phoneError != null) errors['phone'] = phoneError;
  }
  return errors;
}
