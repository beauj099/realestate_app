import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/contact.dart';
import '../../providers/property_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/wizard_section_scaffold.dart';

class OwnerDetailsScreen extends ConsumerStatefulWidget {
  const OwnerDetailsScreen({super.key});

  @override
  ConsumerState<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

// Deprecated: use OwnerDetailsScreen instead
typedef ContactsScreen = OwnerDetailsScreen;

class _OwnerDetailsScreenState extends ConsumerState<OwnerDetailsScreen> {
  final _errors = <String, String?>{};

  String? _validate() {
    final c = ref.read(propertyViewModelProvider).primaryContact;
    _errors.clear();
    final isBusiness = c.ownerType == OwnerType.business;
    if (c.fullName.trim().isEmpty) {
      _errors['name'] = isBusiness
          ? 'Contact person is required'
          : 'Full name is required';
    }
    if (isBusiness && c.companyName.trim().isEmpty) {
      _errors['company'] = 'Company name is required';
    }
    if (c.emailAddress.trim().isEmpty) _errors['email'] = 'Email is required';
    if (c.mobilePhone.trim().isEmpty) _errors['phone'] = 'Phone is required';
    setState(() {});
    if (_errors.isEmpty) return null;
    return friendlySaveMessage(const ValidationFailure().message, 'owners');
  }

  Future<String?> _save() async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    await viewModel.saveContacts();
    final error = ref.read(propertyViewModelProvider).errorMessage;
    return error == null ? null : friendlySaveMessage(error, 'owners');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    _errors.removeWhere((k, v) {
      if (k == 'name') return state.primaryContact.fullName.trim().isNotEmpty;
      if (k == 'email') {
        return state.primaryContact.emailAddress.trim().isNotEmpty;
      }
      if (k == 'phone') {
        return state.primaryContact.mobilePhone.trim().isNotEmpty;
      }
      return true;
    });

    return WizardSectionScaffold(
      title: 'Owner Details',
      sectionName: 'owner',
      validate: _validate,
      onSave: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Owners',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => viewModel.addCoContact(),
                icon: Icon(
                  Icons.add_circle,
                  color: theme.primaryColor,
                  size: 16,
                ),
                label: Text(
                  'Add Co-Owner',
                  style: textTheme.labelLarge?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ContactCard(
            theme: theme,
            textTheme: textTheme,
            contact: state.primaryContact,
            label: 'Primary Owner',
            showRemove: false,
            onChanged: (contact) {
              viewModel.updatePrimaryContact(contact);
            },
            fullNameError: _errors['name'] ?? _errors['company'],
            emailError: _errors['email'],
            phoneError: _errors['phone'],
          ),
          ...state.coContacts.asMap().entries.map((entry) {
            final index = entry.key;
            final coContact = entry.value;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ContactCard(
                theme: theme,
                textTheme: textTheme,
                contact: coContact,
                label: 'Co-Owner ${index + 1}',
                showRemove: true,
                onChanged: (contact) =>
                    viewModel.updateCoContact(index, contact),
                onRemove: () => viewModel.removeCoContact(coContact.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}
