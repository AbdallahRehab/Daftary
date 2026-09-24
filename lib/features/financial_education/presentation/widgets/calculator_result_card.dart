import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/numeral_parser.dart';

/// One labeled figure in a [CalculatorResultCard]'s breakdown.
class CalculatorResultLine {
  const CalculatorResultLine({required this.label, required this.value});

  final String label;
  final String value;
}

/// The shared result presentation for the three calculators (FR-009,
/// FR-010, FR-011): one prominent headline figure, an optional breakdown
/// (e.g. contributed vs growth), the illustrative-only note, and — when the
/// entered rate is unusually high — an extra cautionary note.
///
/// Values arrive pre-formatted; this widget only lays them out, using
/// directional padding/alignment so it reads correctly in RTL and LTR.
class CalculatorResultCard extends StatelessWidget {
  const CalculatorResultCard({
    required this.headline,
    super.key,
    this.breakdown = const [],
    this.showIllustrativeNote = true,
    this.showHighRateNote = false,
    this.notes = const [],
  });

  /// Stable key on the illustrative note, for tests.
  static const Key illustrativeNoteKey = Key('calculator_illustrative_note');

  /// Stable key on the high-rate note, for tests.
  static const Key highRateNoteKey = Key('calculator_high_rate_note');

  final CalculatorResultLine headline;
  final List<CalculatorResultLine> breakdown;

  /// "Illustrative only — assumes a constant rate…" (FR-009). On for every
  /// rate-based projection.
  final bool showIllustrativeNote;

  /// The FR-010 note for rates above the sanity-check threshold.
  final bool showHighRateNote;

  /// Any further calculator-specific notes (e.g. "rule of 72
  /// approximation"), shown muted below the figures.
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final financeColors = context.financeColors;
    final mutedStyle = AppTypography.bodyMuted.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              headline.label,
              style: AppTypography.label.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              headline.value,
              style: AppTypography.amount.copyWith(color: colorScheme.primary),
            ),
            if (breakdown.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              for (final line in breakdown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(line.label, style: AppTypography.body),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        line.value,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (showHighRateNote) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                key: highRateNoteKey,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: financeColors.warningSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: financeColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.finEduCalcHighRateNote,
                        style: AppTypography.bodyMuted.copyWith(
                          color: financeColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showIllustrativeNote) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.finEduCalcIllustrativeNote,
                key: illustrativeNoteKey,
                style: mutedStyle,
              ),
            ],
            for (final note in notes) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(note, style: mutedStyle),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats a plain decimal (years, percent) for display in the active
/// locale with at most [maxFractionDigits] decimals — always Western digits,
/// matching `EgpFormatter` (FR-011 of the app's numeral rule).
String formatCalculatorDecimal(
  BuildContext context,
  double value, {
  int maxFractionDigits = 1,
}) {
  final locale = numeralLocaleFor(Localizations.localeOf(context).languageCode);
  final format = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = maxFractionDigits;
  return NumeralParser.toWesternDigits(format.format(value));
}
