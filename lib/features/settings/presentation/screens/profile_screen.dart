import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/theme/agency.dart';
import '../../../../core/theme/agency_directory.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/validation/phone_format.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/scoped_brand_theme.dart';
import '../../../../core/widgets/wizard_app_bar.dart';
import '../../../auth/data/models/agent_profile.dart';
import '../../../auth/providers/agent_profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/agency_picker.dart';

/// Lets an agent review and change everything they entered at registration.
///
/// Picking an agency previews its colours on this screen straight away, but
/// the rest of the app only re-brands once the change is saved.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _agencyRegNoController;
  late final TextEditingController _licenceController;

  late Agency _agency;
  bool _isSaving = false;
  bool _isDirty = false;

  /// What the form held when it was last filled from the profile. Backing out
  /// only asks to discard when the form differs from this — editing a field
  /// and putting it back, or re-picking the same agency, is not a change.
  String _baseline = '';

  String get _formContent => [
    for (final c in _fields.values) c.text.trim(),
    _agency.slug,
  ].join('\u0000');

  bool get _hasChanges => _formContent != _baseline;

  /// Inline errors keyed by field, cleared as soon as that field is edited.
  final _errors = <String, String>{};

  late final Map<String, TextEditingController> _fields;

  /// Set while fields are filled from the provider, so that is not mistaken
  /// for an edit.
  bool _populating = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _agencyRegNoController = TextEditingController();
    _licenceController = TextEditingController();

    _fields = {
      'firstName': _firstNameController,
      'lastName': _lastNameController,
      'email': _emailController,
      'mobile': _mobileController,
      'agencyRegistrationNumber': _agencyRegNoController,
      'licenceNumber': _licenceController,
    };
    _populate(ref.read(agentProfileProvider));
    _fields.forEach((key, controller) {
      var lastText = controller.text;
      controller.addListener(() {
        // Controllers also notify on cursor moves; only edits count.
        if (controller.text == lastText) return;
        lastText = controller.text;
        if (_populating) return;
        setState(() {
          _isDirty = true;
          _errors.remove(key);
          if (key == 'firstName' || key == 'lastName') {
            _errors.remove('displayName');
          }
        });
      });
    });

    // The cached profile shows at once; the server copy replaces it when it
    // arrives, unless the agent has already started editing.
    ref.listenManual(agentProfileProvider, (previous, next) {
      if (!_isDirty && mounted) setState(() => _populate(next));
    });
    ref.read(agentProfileProvider.notifier).refresh();
  }

  void _populate(AgentProfile profile) {
    var (first, last) = (profile.firstName, profile.lastName);
    if (first.isEmpty && last.isEmpty) {
      (first, last) = AgentProfile.splitName(
        ref.read(authProvider).displayName ?? '',
      );
    }
    _populating = true;
    _firstNameController.text = first;
    _lastNameController.text = last;
    _emailController.text = profile.email;
    _mobileController.text = CountryPhone.format(
      profile.mobile,
      ref.read(regionProvider).country,
    );
    _agencyRegNoController.text = profile.agencyRegistrationNumber;
    _licenceController.text = profile.licenceNumber;
    _populating = false;
    _agency = ref.read(agencyProvider);
    _baseline = _formContent;
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    final errors = <String, String>{
      if (_firstNameController.text.trim().isEmpty)
        'firstName': 'First name is required',
      if (email.isEmpty)
        'email': 'Email address is required'
      else if (!emailRegex.hasMatch(email))
        'email': 'Enter a valid email address',
      if (mobile.isEmpty)
        'mobile': 'Mobile number is required'
      else
        'mobile': ?CountryPhone.validate(
          mobile,
          ref.read(regionProvider).country,
        ),
    };
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _pickAgency(RealEstateTheme theme) async {
    final agency = await showAgencyPicker(
      context: context,
      ref: ref,
      theme: theme,
      selected: _agency,
      title: 'Agency',
    );
    if (agency == null || !mounted) return;
    setState(() {
      _isDirty = _isDirty || agency != _agency;
      _agency = agency;
    });
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final profile = AgentProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: CountryPhone.toStored(
        _mobileController.text,
        ref.read(regionProvider).country,
      ),
      agencyName: _agency.name,
      agencySlug: _agency.slug,
      agencyRegistrationNumber: _agencyRegNoController.text.trim(),
      licenceNumber: _licenceController.text.trim(),
    );

    try {
      await ref.read(agentProfileProvider.notifier).save(profile);
    } catch (e) {
      if (!mounted) return;
      final fields = mapFieldErrors(e);
      setState(() {
        _isSaving = false;
        _errors.addAll(fields);
        // The API validates one display name; show it on the first name.
        final nameError = fields['displayName'];
        if (nameError != null) _errors['firstName'] = nameError;
      });
      if (fields.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mapFailure(e).message),
            backgroundColor: ref.read(themeConfigProvider).error,
          ),
        );
      }
      return;
    }

    // Saved: now the rest of the app takes on the agency's brand.
    await ref.read(agencyProvider.notifier).setAgency(_agency);

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
    context.pop();
  }

  Future<void> _handleBack(RealEstateTheme theme) async {
    if (!_hasChanges) {
      if (mounted) context.pop();
      return;
    }
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
    // Keep the agency list current if one is added from the picker.
    ref.watch(selectableAgenciesProvider);
    // Preview the selected agency here only; the global brand changes on save.
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme = isDark
        ? RealEstateTheme.fromAgencyDark(_agency)
        : RealEstateTheme.fromAgency(_agency);
    final textTheme = theme.toThemeData().textTheme;
    final country = ref.watch(regionProvider).country;

    return ScopedBrandTheme(
      theme: theme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleBack(theme);
        },
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: WizardAppBar(
            title: 'My Profile',
            onBack: () => _handleBack(theme),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            theme: theme,
                            label: 'First name',
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            isRequired: true,
                            errorText: _errors['firstName'],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextInput(
                            theme: theme,
                            label: 'Last name',
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            errorText: _errors['lastName'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      isRequired: true,
                      errorText: _errors['email'],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Mobile number',
                      placeholder: '82 123 4567',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [CountryPhone.inputFormatter(country)],
                      prefixIcon: PhonePrefix(country: country, theme: theme),
                      isRequired: true,
                      errorText: _errors['mobile'],
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Agency', theme, textTheme),
                    AgencyField(
                      agency: _agency,
                      theme: theme,
                      onTap: () => _pickAgency(theme),
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Agency registration number',
                      keyboardType: TextInputType.datetime,
                      controller: _agencyRegNoController,
                      autocorrect: false,
                      errorText: _errors['agencyRegistrationNumber'],
                    ),
                    const SizedBox(height: 16),
                    CustomTextInput(
                      theme: theme,
                      label: 'Licence / FFC number',
                      textCapitalization: TextCapitalization.characters,
                      controller: _licenceController,
                      autocorrect: false,
                      subtext:
                          'Professional registration / Fidelity Fund Certificate',
                      errorText: _errors['licenceNumber'],
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
      ),
    );
  }

  Widget _sectionLabel(
    String text,
    RealEstateTheme theme,
    TextTheme textTheme,
  ) {
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
