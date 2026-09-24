import 'package:flutter/material.dart';

import 'tokens.dart';

/// The app's single primary-action button style. Shows a loading spinner in
/// place of the label and disables itself while [isLoading] is true, so
/// callers get double-tap/duplicate-submission protection for free
/// (constitution: duplicate action protection).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  // Long localized labels (or large text) next to an icon
                  // must shrink rather than overflow the button.
                  Flexible(
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A lower-emphasis, outlined variant used for secondary actions
/// (e.g. "Archive instead", "Cancel").
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
