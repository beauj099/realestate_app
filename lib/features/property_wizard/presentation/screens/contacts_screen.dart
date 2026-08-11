import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/wizard_scaffold.dart';
import '../../providers/property_provider.dart';
import '../widgets/contact_card.dart';
import '../widgets/wizard_actions.dart';

class ContactsStep extends ConsumerWidget {
  const ContactsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return WizardScaffold(
      title: 'Contact Information',
      description: 'Enter the primary contact and co-contacts for this listing.',
      onBack: () => goBackWizard(context, ref),
      onNext: () => advanceWizard(context, ref),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contact Information',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
                'Add Co-Contact',
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
          label: 'Primary Contact',
          showRemove: false,
          onChanged: (contact) => viewModel.updatePrimaryContact(contact),
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
              label: 'Co-Contact ${index + 1}',
              showRemove: true,
              onChanged: (contact) =>
                  viewModel.updateCoContact(index, contact),
              onRemove: () => viewModel.removeCoContact(coContact.id),
            ),
          );
        }),
      ],
    );
  }
}
