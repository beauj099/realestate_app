import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../providers/auth_provider.dart';

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
    final theme = ref.read(themeConfigProvider);
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
            backgroundColor: theme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'K',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      'W',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 48,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Real Estate App',
                  style: textTheme.titleLarge?.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                CustomTextInput(
                  label: 'Username',
                  placeholder: 'Enter your username',
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  style: InputStyle.cardBorder,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                CustomTextInput(
                  label: 'Password',
                  placeholder: 'Enter your password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: InputStyle.cardBorder,
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
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: 'Sign In',
                        fullWidth: true,
                        onTap: _handleLogin,
                        theme: theme,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
