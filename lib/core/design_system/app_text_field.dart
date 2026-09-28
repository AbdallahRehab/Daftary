import 'package:flutter/material.dart';

/// The app's single text-input style. Always shows its own label and
/// (optionally) an inline validation error, never relying on placeholder
/// text alone to convey what's required.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.onChanged,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
    this.autofocus = false,
    this.suffixIcon,
    this.textDirection,
    this.maxLength,
    this.obscureText = false,
    this.enabled,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final Widget? suffixIcon;
  final TextDirection? textDirection;

  /// Caps input length so an unbounded paste can't produce a record no
  /// list row or headline can lay out. The counter only appears once the
  /// text is within 20% of the limit, so everyday typing stays uncluttered.
  final int? maxLength;

  /// Masks the input (e.g. a secret such as an API key). Also turns off
  /// autocorrect and suggestions, so the value is never learned by the
  /// keyboard.
  final bool obscureText;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction,
      autofocus: autofocus,
      textDirection: textDirection,
      maxLength: maxLength,
      buildCounter: maxLength == null
          ? null
          : (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => maxLength != null && currentLength >= maxLength * 0.8
                ? Text('$currentLength/$maxLength')
                : null,
      obscureText: obscureText,
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
