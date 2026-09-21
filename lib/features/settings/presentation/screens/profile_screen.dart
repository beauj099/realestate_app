import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/agency.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/searchable_picker.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../../auth/data/models/agent_profile.dart';
import '../../../auth/providers/agent_profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/agency_logo.dart';

/// Lets an agent review and change everything they entered at registration.
///
/// Saving also re-brands the app when the chosen agency changes, which is the
/// white-label switch: pick Seeff and the whole app turns Seeff blue.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _agencyRegNoController;
  late final TextEditingController _licenceController;

  late Agency _agency;
  bool _isSaving = false;
  bool _isDirty = false;

  String? _fullNameError;
  String? _emailError;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(agentProfileProvider);
    final authName = ref.read(authProvider).displayName ?? '';
    _fullNameController = TextEditingController(
      text: profile.fullName.isNotEmpty ? profile.fullName : authName,
    );
    _emailController = TextEditingController(text: profile.email);
    _mobileController = TextEditingController(text: profile.mobile);
    _agencyRegNoController = TextEditingController(
      text: profile.agencyRegistrationNumber,
    );
    _licenceController = TextEditingController(text: profile.licenceNumber);
    _agency =
        Agency.fromSlug(profile.agencySlug) == Agency.realWorth &&
            profile.agencySlug == null
        ? ref.read(agencyProvider)
        : Agency.fromSlug(profile.agencySlug);

    for (final c in [
      _fullNameController,
      _emailController,
      _mobileController,
      _agencyRegNoController,
      _licenceController,
    ]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fullNameController,
      _emailController,
      _mobileController,
      _agencyRegNoController,
      _licenceController,
    ]) {
      c.removeListener(_markDirty);
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phoneRegex = RegExp(r'^[\d\+\-\s\(\)]{7,20}$');

    setState(() {
      _fullNameError = _fullNameController.text.trim().isEmpty
          ? 'Full name is required'
          : null;
      if (email.isEmpty) {
        _emailError = 'Email address is required';
      } else if (!emailRegex.hasMatch(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }
      if (mobile.isEmpty) {
        _mobileError = 'Mobile/contact number is required';
      } else if (!phoneRegex.hasMatch(mobile)) {
        _mobileError = 'Enter a valid mobile number';
      } else {
        _mobileError = null;
      }
    });

    return _fullNameError == null &&
        _emailError == null &&
        _mobileError == null;
  }

  Future<void> _pickAgency() async {
    final theme = ref.read(themeConfigProvider);
    final result = await showSearchablePicker<Agency>(
      context: context,
      theme: theme,
      title: 'Agency',
      searchHint: 'Search agencies…',
      selectedValue: _agency,
      options: Agency.all
          .map(
            (a) => PickerOption<Agency>(
              value: a,
              label: a.name,
              icon: Icons.apartment_outlined,
            ),
          )
          .toList(),
      customLabel: 'Use name',
      customHint: 'Not listed —',
    );
    if (result == null) return;

    setState(() {
      _isDirty = true;
      if (result.isCustom) {
        // An unlisted agency keeps the house palette; there is no brand to
        // theme from, and guessing colours would look broken.
        _agency = Agency(
          slug: 'custom',
          name: result.customLabel!,
          monogram: result.customLabel!.characters.first.toUpperCase(),
          primaryColor: Agency.realWorth.primaryColor,
          secondaryColor: Agency.realWorth.secondaryColor,
        );
      } else {
        _agency = result.option!.value;
      }
    });
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final profile = AgentProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      agencyName: _agency.name,
      agencySlug: _agency.slug == 'custom' ? null : _agency.slug,
      agencyRegistrationNumber: _agencyRegNoController.text.trim(),
      licenceNumber: _licenceController.text.trim(),
    );

    await ref.read(agentProfileProvider.notifier).save(profile);
    if (_agency.slug != 'custom') {
      await ref.read(agencyProvider.notifier).setAgency(_agency);
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isDirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated'),
        backgroundColor: ref.read(themeConfigProvider).primaryColor,
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _handleBack() async {
    if (!_isDirty) {
      if (mounted) context.pop();
      return;
    }
    final theme = ref.read(themeConfigProvider);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardBackgroundColor,
        title: const Text('Discard changes?'),
        content: const Text(
          'Your profile changes have not been saved. '
          'Go back and they will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Keep editing',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: theme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'My Profile',
          onBack: _handleBack,
          theme: theme,
        ),
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Agent', theme, textTheme),
                  CustomTextInput(
                    theme: theme,
                    label: 'Full name',
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    isRequired: true,
                    errorText: _fullNameError,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Email address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Mobile / contact number',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                    errorText: _mobileError,
                  ),
                  const SizedBox(height: 28),
                  _sectionLabel('Agency', theme, textTheme),
                  _AgencyField(
                    agency: _agency,
                    theme: theme,
                    textTheme: textTheme,
                    onTap: _pickAgency,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Agency registration number',
                    controller: _agencyRegNoController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Licence / FFC number',
                    controller: _licenceController,
                    subtext:
                        'Professional registration / Fidelity Fund Certificate',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Stored on this device. Syncing to your agency account '
                    'arrives with the next API update.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            border: Border(top: BorderSide(color: theme.borderLight)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: _isSaving
                    ? Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.primaryColor,
                          ),
                        ),
                      )
                    : CustomButton(
                        text: 'Save Changes',
                        fullWidth: true,
                        theme: theme,
                        onTap: _save,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, theme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          color: theme.textLabel,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Agency row showing the current brand mark and opening the agency picker.
class _AgencyField extends StatelessWidget {
  final Agency agency;
  final dynamic theme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _AgencyField({
    required this.agency,
    required this.theme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AgencyLogo(agency: agency, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agency / company',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.textLabel,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agency.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
