import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/themes.dart';

class CustomTextInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final bool obscureText;
  final bool isRequired;
  final int maxLines;
  final String? subtext;
  final String? errorText;
  final List<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final RealEstateTheme? theme;

  /// Off for emails, usernames and codes, where a keyboard "correction"
  /// silently changes what the agent typed.
  final bool autocorrect;
  final bool enableSuggestions;

  /// Defaults by field kind (see [_capitalization]) so the keyboard starts
  /// with a capital where one is expected; pass a value to override.
  final TextCapitalization? textCapitalization;

  const CustomTextInput({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.isRequired = false,
    this.maxLines = 1,
    this.subtext,
    this.errorText,
    this.autofillHints,
    this.inputFormatters,
    this.theme,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization,
  });

  /// Plain text starts with a capital (the agent can still switch to lower
  /// case); names capitalise each word; emails, numbers, phone numbers and
  /// passwords never capitalise.
  TextCapitalization get _capitalization {
    final explicit = textCapitalization;
    if (explicit != null) return explicit;
    if (obscureText) return TextCapitalization.none;
    if (keyboardType == TextInputType.name) return TextCapitalization.words;
    if (keyboardType == TextInputType.text ||
        keyboardType == TextInputType.multiline ||
        keyboardType == TextInputType.streetAddress) {
      return TextCapitalization.sentences;
    }
    return TextCapitalization.none;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? RealEstateTheme.crimson();
    final textTheme = resolvedTheme.toThemeData().textTheme;

    final hasError = errorText != null;
    final borderRadius = BorderRadius.circular(12.0);

    OutlineInputBorder buildBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      textCapitalization: _capitalization,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: resolvedTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: placeholder,
        helperText: subtext,
        errorText: errorText,
        filled: true,
        fillColor: resolvedTheme.cardBackgroundColor,
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: resolvedTheme.textSecondary,
          fontWeight: FontWeight.normal,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: hasError ? resolvedTheme.error : resolvedTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: resolvedTheme.textSecondary.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
        helperStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 11,
          color: resolvedTheme.textSecondary.withValues(alpha: 0.8),
        ),
        errorStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 11,
          color: resolvedTheme.error,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIconConstraints,
        border: buildBorder(resolvedTheme.borderLight, 1.0),
        enabledBorder: buildBorder(
          hasError ? resolvedTheme.error : resolvedTheme.borderLight,
          1.0,
        ),
        focusedBorder: buildBorder(
          hasError ? resolvedTheme.error : resolvedTheme.primaryColor,
          1.5,
        ),
        errorBorder: buildBorder(resolvedTheme.error, 1.0),
        focusedErrorBorder: buildBorder(resolvedTheme.error, 1.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
      ),
    );
  }
}
