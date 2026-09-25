import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/scoped_brand_theme.dart';
import '../../../../core/widgets/wizard_app_bar.dart';

/// Password reset by emailed code.
///
/// Step one asks for the account email and has the API send a 6-digit code;
/// step two takes the code and the new password. The API answers step one the
/// same way whether or not the email is registered, so the copy never claims
/// an account exists.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscure = true;

  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    // Clear each field's error as soon as it is edited.
    _emailController.addListener(() => _clear(() => _emailError = null));
    _codeController.addListener(() => _clear(() => _codeError = null));
    _passwordController.addListener(() => _clear(() => _passwordError = null));
    _confirmController.addListener(() => _clear(() => _confirmError = null));
  }

  void _clear(VoidCallback reset) {
    if (_emailError == null &&
        _codeError == null &&
        _passwordError == null &&
        _confirmError == null) {
      return;
    }
    setState(reset);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim().toLowerCase();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ref.read(houseThemeProvider).error,
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_emailRegex.hasMatch(_email)) {
      setState(() => _emailError = 'Enter the email you registered with');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authApiServiceProvider).forgotPassword(_email);
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      if (!mounted) return;
      final fields = mapFieldErrors(e);
      if (fields['email'] != null) {
        setState(() => _emailError = fields['email']);
      } else {
        _showError(mapFailure(e).message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _codeError = RegExp(r'^\d{6}$').hasMatch(code)
          ? null
          : 'Enter the 6-digit code from the email';
      _passwordError = password.length < 6
          ? 'Password must be at least 6 characters'
          : null;
      _confirmError = _confirmController.text != password
          ? 'Passwords do not match'
          : null;
    });
    if (_codeError != null || _passwordError != null || _confirmError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authApiServiceProvider)
          .resetPassword(email: _email, code: code, newPassword: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Password updated — sign in with your new password.',
          ),
          backgroundColor: ref.read(houseThemeProvider).primaryColor,
        ),
      );
      context.go(AppRoutes.loginPath);
    } catch (e) {
      if (!mounted) return;
      final fields = mapFieldErrors(e);
      if (fields.isEmpty) {
        _showError(mapFailure(e).message);
      } else {
        setState(() {
          _codeError = fields['code'];
          _passwordError = fields['newPassword'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.loginPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(houseThemeProvider);
    final textTheme = theme.toThemeData().textTheme;

    Widget passwordToggle() => IconButton(
      icon: Icon(
        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: theme.textSecondary,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );

    return ScopedBrandTheme(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: WizardAppBar(
          title: 'Reset Password',
          onBack: _back,
          theme: theme,
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _codeSent
                      ? 'If an account exists for $_email, we have emailed it '
                            'a 6-digit code. It expires in 15 minutes.'
                      : 'Enter the email you registered with and we will '
                            'send you a code to reset your password.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextInput(
                  theme: theme,
                  label: 'Email address',
                  placeholder: 'e.g. jane@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  errorText: _emailError,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Reset code',
                    placeholder: '6-digit code',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    errorText: _codeError,
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'New password',
                    placeholder: 'At least 6 characters',
                    controller: _passwordController,
                    obscureText: _obscure,
                    isPassword: true,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: _passwordError,
                    suffixIcon: passwordToggle(),
                  ),
                  const SizedBox(height: 16),
                  CustomTextInput(
                    theme: theme,
                    label: 'Confirm new password',
                    controller: _confirmController,
                    obscureText: _obscure,
                    isPassword: true,
                    errorText: _confirmError,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: Text(
                      "Didn't get it? Send a new code",
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
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
                        text: _codeSent ? 'Reset Password' : 'Send Reset Code',
                        fullWidth: true,
                        theme: theme,
                        onTap: _codeSent ? _resetPassword : _sendCode,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
