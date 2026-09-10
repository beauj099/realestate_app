import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../data/models/contact.dart';
import '../../providers/property_provider.dart';
import '../widgets/contact_card.dart';

class OwnerDetailsScreen extends ConsumerStatefulWidget {
  const OwnerDetailsScreen({super.key});

  @override
  ConsumerState<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

// Deprecated: use OwnerDetailsScreen instead
typedef ContactsScreen = OwnerDetailsScreen;

class _OwnerDetailsScreenState extends ConsumerState<OwnerDetailsScreen> {
  final _errors = <String, String?>{};

  bool _validate(Contact c) {
    _errors.clear();
    if (c.fullName.trim().isEmpty) _errors['name'] = 'Full name is required';
    if (c.emailAddress.trim().isEmpty) _errors['email'] = 'Email is required';
    if (c.mobilePhone.trim().isEmpty) _errors['phone'] = 'Phone is required';
    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _saveAndPop() async {
    final state = ref.read(propertyViewModelProvider);
    if (!_validate(state.primaryContact)) {
      if (mounted) {
        final theme = ref.read(themeConfigProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlySaveMessage(
                const ValidationFailure().message,
                'contacts',
              ),
            ),
            backgroundColor: theme.error,
          ),
        );
        context.pop();
      }
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    await viewModel.saveContacts();
    if (!mounted) return;
    Navigator.pop(context);
    final error = ref.read(propertyViewModelProvider).errorMessage;
    if (error != null && mounted) {
      final theme = ref.read(themeConfigProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlySaveMessage(error, 'contacts')),
          backgroundColor: theme.error,
        ),
      );
    }
    if (mounted) context.pop();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Owner Details',
          onBack: () => Navigator.maybePop(context),
          theme: theme,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner Details',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter the primary owner and co-owners for this property.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Owners',
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
                    fullNameError: _errors['name'],
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
            ),
          ),
        ),
      ),
    );
  }
}
