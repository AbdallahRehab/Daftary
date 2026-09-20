import 'package:flutter/material.dart';

import 'tokens.dart';

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
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}
