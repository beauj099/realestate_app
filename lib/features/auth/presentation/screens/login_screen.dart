import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../../../core/widgets/scoped_brand_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final theme = ref.read(houseThemeProvider);
    // Agents register with their email, which the API stores as their
    // username; older accounts (e.g. "Dylan") have a plain username. The API
    // accepts either and matches emails case-insensitively.
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).login(username, password);

    if (mounted) {
      setState(() => _isLoading = false);
      final authState = ref.read(authProvider);
      if (authState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: theme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sign-in always wears the RealWorth brand, whichever agency the last
    // agent on this device picked.
    final theme = ref.watch(houseThemeProvider);
    final textTheme = theme.toThemeData().textTheme;

    return ScopedBrandTheme(
      theme: theme,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AutofillGroup(
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
                    const SizedBox(height: 32),
                    CustomTextInput(
                      label: 'Email or username',
                      placeholder: 'e.g. jane@example.com',
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      autocorrect: false,
                      enableSuggestions: false,
                      theme: theme,
                    ),
                    const SizedBox(height: 20),
                    CustomTextInput(
                      label: 'Password',
                      placeholder: 'Enter your password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final typed = _usernameController.text.trim();
                          context.push(
                            Uri(
                              path: AppRoutes.forgotPasswordPath,
                              queryParameters: typed.contains('@')
                                  ? {'email': typed}
                                  : null,
                            ).toString(),
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? CircularProgressIndicator(color: theme.primaryColor)
                        : CustomButton(
                            text: 'Sign In',
                            fullWidth: true,
                            onTap: _handleLogin,
                            theme: theme,
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.registerPath),
                      child: Text(
                        "Don't have an account? Create Account",
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
      ),
    );
  }
}
