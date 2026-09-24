import 'package:flutter/material.dart';

import '../money/currency.dart';
import 'tokens.dart';

/// A compact pill showing a record's own ISO currency code (FR-010), placed
/// next to an amount. Codes are Latin and read left-to-right in both RTL and
/// LTR, so the chip wraps them in an explicit LTR [Directionality].
class CurrencyIndicatorChip extends StatelessWidget {
  const CurrencyIndicatorChip({required this.currency, super.key});

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: Key('currency_chip_${currency.code}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          currency.code,
          style: AppTypography.bodyMuted.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
