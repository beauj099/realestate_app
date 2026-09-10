import 'package:flutter/material.dart';

import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../data/models/contact.dart';

class ContactFields extends StatelessWidget {
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final Contact contact;
  final ValueChanged<Contact> onChanged;
  final String? fullNameError;
  final String? emailError;
  final String? phoneError;

  const ContactFields({
    super.key,
    required this.theme,
    required this.textTheme,
    required this.contact,
    required this.onChanged,
    this.fullNameError,
    this.emailError,
    this.phoneError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextInput(
          theme: theme,
          label: 'FULL NAME',
          placeholder: 'John Doe / Acme Properties',
          initialValue: contact.fullName,

          autofillHints: const [AutofillHints.name],
          errorText: fullNameError,
          onChanged: (val) => onChanged(contact.copyWith(fullName: val)),
        ),
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
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'ID NUMBER',
          placeholder: 'Optional',
          initialValue: contact.idNumber,
          onChanged: (val) => onChanged(contact.copyWith(idNumber: val)),
        ),
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'COMPANY NAME',
          placeholder: 'Acme Properties Pty Ltd',
          initialValue: contact.companyName,

          onChanged: (val) => onChanged(contact.copyWith(companyName: val)),
        ),
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'COMPANY REGISTRATION NUMBER',
          placeholder: 'Optional',
          initialValue: contact.companyRegistrationNumber,
          onChanged: (val) =>
              onChanged(contact.copyWith(companyRegistrationNumber: val)),
        ),
        const SizedBox(height: 16),
        CustomTextInput(
          theme: theme,
          label: 'ROLE',
          placeholder: 'e.g. Owner, Director, Agent',
          initialValue: contact.role,
          onChanged: (val) => onChanged(contact.copyWith(role: val)),
        ),
      ],
    );
  }
}
