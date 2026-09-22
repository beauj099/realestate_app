import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
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
  final ValueChanged<Contact> onChanged;
  final String? fullNameError;
  final String? companyNameError;
  final String? emailError;
  final String? phoneError;

  const ContactFields({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.contact,
    required this.onChanged,
    this.fullNameError,
    this.companyNameError,
    this.emailError,
    this.phoneError,
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
            placeholder: 'Acme Properties Pty Ltd',
            initialValue: contact.companyName,
            errorText: companyNameError,
            onChanged: (val) => onChanged(contact.copyWith(companyName: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'REGISTRATION NUMBER',
            placeholder: 'e.g. 2021/123456/07',
            initialValue: contact.companyRegistrationNumber,
            onChanged: (val) =>
                onChanged(contact.copyWith(companyRegistrationNumber: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'CONTACT PERSON',
            placeholder: 'Who signs for the company',
            initialValue: contact.fullName,
            autofillHints: const [AutofillHints.name],
            errorText: fullNameError,
            onChanged: (val) => onChanged(contact.copyWith(fullName: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'CAPACITY',
            placeholder: 'e.g. Director, Trustee, Member',
            initialValue: contact.role,
            onChanged: (val) => onChanged(contact.copyWith(role: val)),
          ),
        ] else ...[
          CustomTextInput(
            theme: theme,
            label: 'FULL NAME',
            placeholder: 'John Doe',
            initialValue: contact.fullName,
            autofillHints: const [AutofillHints.name],
            errorText: fullNameError,
            onChanged: (val) => onChanged(contact.copyWith(fullName: val)),
          ),
          const SizedBox(height: 16),
          CustomTextInput(
            theme: theme,
            label: 'ID NUMBER',
            placeholder: 'e.g. 8001015009087',
            initialValue: contact.idNumber,
            keyboardType: TextInputType.number,
            onChanged: (val) => onChanged(contact.copyWith(idNumber: val)),
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
          errorText: emailError,
          onChanged: (val) => onChanged(contact.copyWith(emailAddress: val)),
        ),
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'PHONE NUMBER',
          placeholder: '+27 82 000 0000',
          initialValue: contact.mobilePhone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          errorText: phoneError,
          onChanged: (val) => onChanged(contact.copyWith(mobilePhone: val)),
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
