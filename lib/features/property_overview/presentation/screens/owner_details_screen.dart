import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../providers/property_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/contact_fields.dart';
import '../widgets/wizard_section_scaffold.dart';

class OwnerDetailsScreen extends ConsumerStatefulWidget {
  const OwnerDetailsScreen({super.key});

  @override
  ConsumerState<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

// Deprecated: use OwnerDetailsScreen instead
typedef ContactsScreen = OwnerDetailsScreen;

class _OwnerDetailsScreenState extends ConsumerState<OwnerDetailsScreen> {
  /// Set by the first Save attempt. From then on errors are recomputed on
  /// every rebuild, so each one disappears the moment its field is valid.
  bool _showErrors = false;

  String? _validate() {
    final state = ref.read(propertyViewModelProvider);
    final country = ref.read(regionProvider).country;
    setState(() => _showErrors = true);
    final invalid =
        validateContact(
          state.primaryContact,
          isPrimary: true,
          country: country,
        ).isNotEmpty ||
        state.coContacts.any(
          (c) =>
              validateContact(c, isPrimary: false, country: country).isNotEmpty,
        );
    if (!invalid) return null;
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
    final country = ref.watch(regionProvider).country;

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
            country: country,
            label: 'Primary Owner',
            showRemove: false,
            onChanged: (contact) {
              viewModel.updatePrimaryContact(contact);
            },
            errors: _showErrors
                ? validateContact(
                    state.primaryContact,
                    isPrimary: true,
                    country: country,
                  )
                : const {},
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
                country: country,
                label: 'Co-Owner ${index + 1}',
                showRemove: true,
                onChanged: (contact) =>
                    viewModel.updateCoContact(index, contact),
                errors: _showErrors
                    ? validateContact(
                        coContact,
                        isPrimary: false,
                        country: country,
                      )
                    : const {},
                onRemove: () => viewModel.removeCoContact(coContact.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}
