import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/agency.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/locale/countries.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/validation/phone_format.dart';
import '../../../../core/widgets/country_picker.dart';
import '../../../../core/widgets/field_prefixes.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/scoped_brand_theme.dart';
import '../../../settings/presentation/widgets/agency_picker.dart';
import '../../data/models/agent_profile.dart';
import '../../providers/agent_profile_provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _agencyRegNoController = TextEditingController();
  final _licenceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Agency? _agency;

  /// Sets the phone prefix here, and the app's country and currency once
  /// the account exists.
  Country _country = Country.southAfrica;

  /// Inline errors keyed by field. Each clears as soon as its field is edited,
  /// rather than lingering until the next submit.
  final _errors = <String, String>{};

  late final Map<String, TextEditingController> _fields = {
    'firstName': _firstNameController,
    'lastName': _lastNameController,
    'email': _emailController,
    'mobile': _mobileController,
    'password': _passwordController,
    'confirmPassword': _confirmPasswordController,
  };

  @override
  void initState() {
    super.initState();
    _fields.forEach((key, controller) {
      controller.addListener(() {
        if (_errors.containsKey(key)) setState(() => _errors.remove(key));
      });
    });
  }

  @override
  void dispose() {
    for (final c in [
      ..._fields.values,
      _agencyRegNoController,
      _licenceController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateFields() {
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    final errors = <String, String>{
      if (_firstNameController.text.trim().isEmpty)
        'firstName': 'First name is required',
      if (_lastNameController.text.trim().isEmpty)
        'lastName': 'Last name is required',
      if (email.isEmpty)
        'email': 'Email address is required'
      else if (!emailRegex.hasMatch(email))
        'email': 'Enter a valid email address',
      if (mobile.isEmpty)
        'mobile': 'Mobile number is required'
      else
        'mobile': ?CountryPhone.validate(mobile, _country),
      if (_agency == null) 'agency': 'Select your agency',
      if (password.isEmpty)
        'password': 'Password is required'
      else if (password.length < 6)
        'password': 'At least 6 characters',
      if (_confirmPasswordController.text != password)
        'confirmPassword': 'Passwords do not match',
    };

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _pickCountry() async {
    final country = await showCountryPicker(
      context: context,
      theme: ref.read(houseThemeProvider),
      mode: CountryPickerMode.country,
      selected: _country,
    );
    if (country == null || country == _country) return;
    setState(() {
      // Re-read what was typed under the new country's rules.
      final typed = _mobileController.text;
      _country = country;
      _mobileController.text = CountryPhone.format(typed, country);
      _errors.remove('mobile');
    });
  }

  Future<void> _pickAgency() async {
    final agency = await showAgencyPicker(
      context: context,
      ref: ref,
      theme: ref.read(houseThemeProvider),
      selected: _agency,
    );
    if (agency == null) return;
    setState(() {
      _agency = agency;
      _errors.remove('agency');
    });
  }

  Future<void> _handleRegister() async {
    if (!_validateFields()) return;

    final theme = ref.read(houseThemeProvider);
    final agency = _agency!;
    final profile = AgentProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: CountryPhone.toStored(_mobileController.text, _country),
      agencyName: agency.name,
      agencySlug: agency.slug,
      agencyRegistrationNumber: _agencyRegNoController.text.trim(),
      licenceNumber: _licenceController.text.trim(),
    );

    setState(() => _isLoading = true);

    // Seed first: signing in triggers a profile fetch, and the API keeps only
    // a full name, so this is what preserves the first/last split typed here.
    await ref.read(agentProfileProvider.notifier).seed(profile);

    await ref
        .read(authProvider.notifier)
        .register(
          fullName: profile.fullName,
          email: profile.email,
          mobile: profile.mobile,
          agencyName: profile.agencyName,
          agencyRegistrationNumber: profile.agencyRegistrationNumber,
          licenceNumber: profile.licenceNumber,
          password: _passwordController.text,
        );

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      // Brand the app for the new agent; the agency's colours take over on
      // the home screen, not here.
      await ref.read(agencyProvider.notifier).setAgency(agency);
      // The country answer sets both the country and the currency.
      await ref.read(regionProvider.notifier).setBoth(_country);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: theme.error,
        ),
      );
    }
  }

  Widget _passwordToggle(bool obscured, VoidCallback onPressed) {
    final theme = ref.read(houseThemeProvider);
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: theme.textSecondary,
      ),
      onPressed: onPressed,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 20),
    );
  }

  static const _toggleConstraints = BoxConstraints(
    minWidth: 32,
    maxWidth: 32,
    minHeight: 20,
    maxHeight: 20,
  );

  @override
  Widget build(BuildContext context) {
    // Sign-up always wears the RealWorth brand; picking an agency here brands
    // the app only once the account exists.
    final theme = ref.watch(houseThemeProvider);
    final textTheme = theme.toThemeData().textTheme;
    const gap = SizedBox(height: 12);

    return ScopedBrandTheme(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: AutofillGroup(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Agent Account',
                      style: textTheme.titleLarge?.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            label: 'First name',
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.givenName],
                            isRequired: true,
                            errorText: _errors['firstName'],
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextInput(
                            label: 'Last name',
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.familyName],
                            isRequired: true,
                            errorText: _errors['lastName'],
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    gap,
                    CustomTextInput(
                      label: 'Email address',
                      placeholder: 'e.g. jane@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      enableSuggestions: false,
                      isRequired: true,
                      errorText: _errors['email'],
                      theme: theme,
                    ),
                    gap,
                    CountryField(
                      country: _country,
                      label: 'Country *',
                      theme: theme,
                      onTap: _pickCountry,
                    ),
                    gap,
                    CustomTextInput(
                      // Rebuilt per country so its formatter follows it.
                      key: ValueKey('mobile-${_country.isoCode}'),
                      label: 'Mobile number',
                      placeholder: _country.isoCode == Country.defaultIsoCode
                          ? '82 123 4567'
                          : null,
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: [CountryPhone.inputFormatter(_country)],
                      prefixIcon: PhonePrefix(country: _country, theme: theme),
                      isRequired: true,
                      errorText: _errors['mobile'],
                      theme: theme,
                    ),
                    gap,
                    AgencyField(
                      agency: _agency,
                      theme: theme,
                      label: 'Agency *',
                      errorText: _errors['agency'],
                      onTap: _pickAgency,
                    ),
                    gap,
                    // Optional: not every agent has these to hand at sign-up.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextInput(
                            label: 'Agency reg. no.',
                            keyboardType: TextInputType.datetime,
                            controller: _agencyRegNoController,
                            autocorrect: false,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextInput(
                            label: 'Licence / FFC no.',
                            textCapitalization: TextCapitalization.characters,
                            controller: _licenceController,
                            autocorrect: false,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    gap,
                    CustomTextInput(
                      label: 'Password',
                      placeholder: 'At least 6 characters',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      isRequired: true,
                      errorText: _errors['password'],
                      theme: theme,
                      suffixIcon: _passwordToggle(
                        _obscurePassword,
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      suffixIconConstraints: _toggleConstraints,
                    ),
                    gap,
                    CustomTextInput(
                      label: 'Confirm password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      isRequired: true,
                      errorText: _errors['confirmPassword'],
                      theme: theme,
                      suffixIcon: _passwordToggle(
                        _obscureConfirmPassword,
                        () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                      suffixIconConstraints: _toggleConstraints,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Pinned so the primary action never sits below the fold, with the
        // sign-in link directly beneath it.
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.cardBackgroundColor,
            border: Border(top: BorderSide(color: theme.borderLight)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: _isLoading
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
                            text: 'Create Agent Account',
                            fullWidth: true,
                            onTap: _handleRegister,
                            theme: theme,
                          ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.loginPath),
                    child: Text(
                      'Already have an account? Sign In',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
