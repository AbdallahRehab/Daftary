import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency.dart';

/// The shared "blocked total" indicator (FR-009), shown in place of an
/// aggregate total whenever `SumResult.blocked` is returned. Names every
/// currency that needs a rate, and offers a path to set one. Reused by every
/// feature that shows a converted total.
class RateNeededBanner extends StatelessWidget {
  const RateNeededBanner({
    required this.missingRatesFor,
    this.onSetRate,
    super.key,
  });

  /// Stable key so tests can assert presence without the localized copy.
  static const Key rootKey = Key('rate_needed_banner');

  final List<Currency> missingRatesFor;

  /// Opens exchange-rate settings; the action is hidden when null.
  final VoidCallback? onSetRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onTertiaryContainer;
    final codes = missingRatesFor.map((c) => c.code).join(', ');
    return Container(
      key: rootKey,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      l10n.rateNeededTitle,
                      style: AppTypography.body.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.rateNeededMessage(codes),
                      style: AppTypography.bodyMuted.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onSetRate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('rate_needed_set_rate'),
                style: TextButton.styleFrom(foregroundColor: foreground),
                onPressed: onSetRate,
                child: Text(l10n.rateNeededAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
