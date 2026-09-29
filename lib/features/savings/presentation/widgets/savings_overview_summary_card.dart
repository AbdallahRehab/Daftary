import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../domain/entities/savings_overview.dart';
import 'savings_format.dart';

/// The combined total saved across the listed goals, in the primary
/// currency (FR-019).
///
/// 018 FR-009: when a goal needs a missing exchange rate the total shown
/// covers only the goals that could be converted, and is marked incomplete
/// here — naming every missing rate, with the way to add one — never
/// silently converted with a guessed rate.
class SavingsOverviewSummaryCard extends StatelessWidget {
  const SavingsOverviewSummaryCard({
    required this.overview,
    super.key,
    this.onSetRate,
  });

  final SavingsOverview overview;

  /// Opens exchange-rate settings; the action is hidden when null.
  final VoidCallback? onSetRate;

  static const Key incompleteKey = ValueKey('savingsOverviewIncomplete');

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurfaceVariant;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.savings_outlined, size: 20, color: muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.savingsOverviewTotalLabel,
                  style: AppTypography.label.copyWith(color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            format.money(overview.totalSaved),
            key: const ValueKey('savingsOverviewTotal'),
            style: AppTypography.headline,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.savingsOverviewGoalCount(overview.goals.length),
            style: AppTypography.bodyMuted.copyWith(color: muted),
          ),
          if (overview.isIncomplete) ...[
            const SizedBox(height: AppSpacing.md),
            _IncompleteMarker(
              codes: overview.missingRatesFor.map((c) => c.code).join(', '),
              onSetRate: onSetRate,
            ),
          ],
        ],
      ),
    );
  }
}

/// Same tertiary-container treatment as 018's `RateNeededBanner`, so the
/// marker reads as the app's one "rate needed" signal; the words carry the
/// meaning, never the colour alone.
class _IncompleteMarker extends StatelessWidget {
  const _IncompleteMarker({required this.codes, this.onSetRate});

  final String codes;
  final VoidCallback? onSetRate;

  @override
  Widget build(BuildContext context) {
    final l10n = SavingsFormat.of(context).l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onTertiaryContainer;
    return Container(
      key: SavingsOverviewSummaryCard.incompleteKey,
      padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.currency_exchange, size: 20, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.savingsOverviewIncompleteTitle,
                      style: AppTypography.body.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.savingsOverviewIncompleteMessage(codes),
                      style: AppTypography.bodyMuted.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onSetRate != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: foreground),
                onPressed: onSetRate,
                child: Text(l10n.rateNeededAction),
              ),
            ),
        ],
      ),
    );
  }
}
