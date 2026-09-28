import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/field_confidence.dart';

/// How much the app trusts one field, rendered honestly (FR-013).
///
/// Three things about this widget are requirements rather than styling
/// choices:
///
/// * **An inferred value never wears a read's clothes.** A derived or
///   defaulted field gets its own shape — an outlined pill with a question
///   glyph — not a quieter shade of the same badge. FR-013's explicit
///   anti-goal is showing the user a false sense of certainty about
///   something the app guessed rather than read.
/// * **No number is invented.** The recognizer exposes no meaningful
///   per-token score, so nothing here prints a percentage; a fabricated
///   "82%" would be a more confident lie than "low".
/// * **Colour is never the only channel.** Each variant carries a distinct
///   icon and a text label as well, so the signal survives colourblindness,
///   greyscale, and a dark theme (constitution: accessibility).
class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({required this.confidence, super.key});

  final FieldConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    if (confidence.isInferred) {
      return _InferredBadge(label: l10n.ocrConfidenceInferred);
    }

    final (
      IconData icon,
      Color foreground,
      Color background,
      String label,
    ) = switch (confidence.level) {
      FieldConfidenceLevel.low => (
        Icons.signal_cellular_alt_1_bar,
        finance.negative,
        finance.negativeSurface,
        l10n.ocrConfidenceLow,
      ),
      FieldConfidenceLevel.medium => (
        Icons.signal_cellular_alt_2_bar,
        finance.warning,
        finance.warningSurface,
        l10n.ocrConfidenceMedium,
      ),
      FieldConfidenceLevel.high => (
        Icons.signal_cellular_alt,
        finance.positive,
        finance.positiveSurface,
        l10n.ocrConfidenceHigh,
      ),
      // Unreachable by construction — `FieldConfidence.read` refuses
      // `none` — but rendered as the neutral inferred badge rather than
      // as a confident read if it ever were.
      FieldConfidenceLevel.none => (
        Icons.help_outline,
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
        l10n.ocrConfidenceInferred,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.sm,
          2,
          AppSpacing.sm,
          2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTypography.label.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

/// Deliberately a different *shape*, not a different shade: an outlined,
/// unfilled pill with a dedicated glyph, so an inferred field cannot be
/// mistaken for a low-but-real read at a glance (FR-013 Acceptance
/// Scenario 2).
class _InferredBadge extends StatelessWidget {
  const _InferredBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.sm,
          2,
          AppSpacing.sm,
          2,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
