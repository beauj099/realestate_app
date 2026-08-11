import 'package:flutter/material.dart';

import '../theme/themes.dart';

enum InputStyle { bottomBorder, cardBorder }

class CustomTextInput extends StatefulWidget {
  final String label;
  final String? placeholder;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final InputStyle style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isRequired;
  final int maxLines;
  final String? subtext;
  final RealEstateTheme? theme;

  const CustomTextInput({
    super.key,
    required this.label,
    this.placeholder,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.style = InputStyle.cardBorder,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.maxLines = 1,
    this.subtext,
    this.theme,
  });

  @override
  State<CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<CustomTextInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? RealEstateTheme.crimson();
    final textTheme = theme.toThemeData().textTheme;

    final resolvedBorderColor = _isFocused
        ? theme.primaryColor
        : theme.borderLight;

    Widget textField = TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      style: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: theme.textSecondary.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: widget.prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        suffixIcon: widget.suffixIcon,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );

    Widget inputContainer;

    if (widget.style == InputStyle.bottomBorder) {
      inputContainer = Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: resolvedBorderColor,
              width: _isFocused ? 2.0 : 1.0,
            ),
          ),
        ),
        child: textField,
      );
    } else {
      // Card border design
      inputContainer = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: resolvedBorderColor,
            width: _isFocused ? 1.5 : 1.0,
          ),
        ),
        child: textField,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: textTheme.labelLarge?.copyWith(
                color: theme.textLabel,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.errorBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'REQUIRED',
                  style: textTheme.labelMedium?.copyWith(
                    color: theme.error,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        inputContainer,
        if (widget.subtext != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtext!,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 11,
              color: theme.textSecondary.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
