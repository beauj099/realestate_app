import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/agency.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/searchable_picker.dart';
import '../../data/models/agent_profile.dart';
import '../../providers/agent_profile_provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _agencyRegNoController = TextEditingController();
  final _licenceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  /// Listed agency the agent picked, or null when they typed a name that is
  /// not in the registry.
  Agency? _selectedAgency;

  // Inline errors driven by CustomTextInput.errorText
  String? _fullNameError;
  String? _emailError;
  String? _mobileError;
  String? _agencyNameError;
  String? _agencyRegNoError;
  String? _licenceError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _agencyNameController.dispose();
    _agencyRegNoController.dispose();
    _licenceController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final agencyName = _agencyNameController.text.trim();
    final agencyRegNo = _agencyRegNoController.text.trim();
    final licence = _licenceController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phoneRegex = RegExp(r'^[\d\+\-\s\(\)]{7,20}$');

    setState(() {
      _fullNameError = fullName.isEmpty ? 'Full name is required' : null;
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
      _agencyNameError = agencyName.isEmpty
          ? 'Agency/company name is required'
          : null;
      _agencyRegNoError = agencyRegNo.isEmpty
          ? 'Agency registration number is required'
          : null;
      _licenceError = licence.isEmpty
          ? 'Licence / FFC number is required'
          : null;
      if (password.isEmpty) {
        _passwordError = 'Password is required';
      } else if (password.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Please confirm your password';
      } else if (confirmPassword != password) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });

    return _fullNameError == null &&
        _emailError == null &&
        _mobileError == null &&
        _agencyNameError == null &&
        _agencyRegNoError == null &&
        _licenceError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  /// Opens the agency picker and applies the chosen brand straight away.
  ///
  /// An agency that is not on the list is kept as free text, and the app stays
  /// on the house palette rather than guessing an unknown brand's colours.
  Future<void> _pickAgency() async {
    final theme = ref.read(themeConfigProvider);
    final result = await showSearchablePicker<Agency>(
      context: context,
      theme: theme,
      title: 'Your Agency',
      searchHint: 'Search agencies…',
      selectedValue: _selectedAgency,
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
      if (result.isCustom) {
        _selectedAgency = null;
        _agencyNameController.text = result.customLabel!;
      } else {
        _selectedAgency = result.option!.value;
        _agencyNameController.text = _selectedAgency!.name;
      }
      _agencyNameError = null;
    });

    if (_selectedAgency != null) {
      await ref.read(agencyProvider.notifier).setAgency(_selectedAgency!);
    }
  }

  Future<void> _handleRegister() async {
    if (!_validateFields()) return;

    final theme = ref.read(themeConfigProvider);

    setState(() => _isLoading = true);

    await ref
        .read(authProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          mobile: _mobileController.text.trim(),
          agencyName: _agencyNameController.text.trim(),
          agencyRegistrationNumber: _agencyRegNoController.text.trim(),
          licenceNumber: _licenceController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);
    final authState = ref.read(authProvider);
    if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: theme.error,
        ),
      );
      return;
    }

    // The API returns only a display name and role, so keep the rest of what
    // was entered — it is the only copy the profile screen has to show.
    await ref
        .read(agentProfileProvider.notifier)
        .save(
          AgentProfile(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            mobile: _mobileController.text.trim(),
            agencyName: _agencyNameController.text.trim(),
            agencySlug: _selectedAgency?.slug,
            agencyRegistrationNumber: _agencyRegNoController.text.trim(),
            licenceNumber: _licenceController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 220,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create Account',
                    style: textTheme.titleLarge?.copyWith(
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register as an agent',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextInput(
                    label: 'Full name',
                    placeholder: 'e.g. Jane Doe',
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    autofillHints: const ['name'],
                    isRequired: true,
                    errorText: _fullNameError,

                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    label: 'Email address',
                    placeholder: 'e.g. jane@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const ['email'],
                    isRequired: true,
                    errorText: _emailError,

                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    label: 'Mobile / contact number',
                    placeholder: 'e.g. 082 123 4567',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const ['tel'],
                    isRequired: true,
                    errorText: _mobileError,

                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  // Picking a listed agency re-brands the app immediately, so
                  // the agent sees their own colours before they even sign in.
                  InkWell(
                    onTap: _pickAgency,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Agency / company name *',
                        errorText: _agencyNameError,
                        filled: true,
                        fillColor: theme.cardBackgroundColor,
                        labelStyle: textTheme.bodyLarge?.copyWith(
                          color: theme.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.borderLight),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _agencyNameController.text.isEmpty
                                  ? 'Select your agency'
                                  : _agencyNameController.text,
                              style: textTheme.bodyLarge?.copyWith(
                                color: _agencyNameController.text.isEmpty
                                    ? theme.textSecondary.withValues(alpha: 0.6)
                                    : theme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    label: 'Agency registration number',
                    placeholder: 'e.g. 2021/123456/07',
                    controller: _agencyRegNoController,
                    keyboardType: TextInputType.text,
                    isRequired: true,
                    errorText: _agencyRegNoError,

                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    label: 'Licence / FFC number',
                    placeholder: 'e.g. FFC123456',
                    controller: _licenceController,
                    keyboardType: TextInputType.text,
                    isRequired: true,
                    errorText: _licenceError,
                    subtext:
                        'Professional registration / Fidelity Fund Certificate',

                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    label: 'Password',
                    placeholder: 'Create a password (min 6 characters)',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    isRequired: true,
                    errorText: _passwordError,

                    theme: theme,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: theme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 20,
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      maxWidth: 32,
                      minHeight: 20,
                      maxHeight: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    label: 'Confirm password',
                    placeholder: 'Re-enter your password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    isRequired: true,
                    errorText: _confirmPasswordError,

                    theme: theme,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: theme.textSecondary,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 20,
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      maxWidth: 32,
                      minHeight: 20,
                      maxHeight: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
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
      // Pinned: the form is long enough that an inline button sat below the
      // fold and looked cut off.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          border: Border(top: BorderSide(color: theme.borderLight)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: SizedBox(
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
                      text: 'Create Account',
                      fullWidth: true,
                      onTap: _handleRegister,
                      theme: theme,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
