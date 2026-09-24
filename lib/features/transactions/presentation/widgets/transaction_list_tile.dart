import 'package:flutter/material.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/currency_indicator_chip.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/money_transaction.dart';

/// One row in a person's transaction history: type, amount, direction,
/// date, note, and an "edited" marker when `editedAt != null` (FR-010,
/// FR-015). A repayment renders visibly distinct from a regular exchange
/// (User Story 3, Acceptance Scenario 1).
///
/// 018: the amount always renders in the record's own currency (FR-010);
/// a record whose currency differs from [primaryCurrency] also gets a
/// [CurrencyIndicatorChip], so an EGP-only history looks exactly as before.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    required this.transaction,
    super.key,
    this.onTap,
    this.onDelete,
    this.primaryCurrency = Currency.egp,
  });

  final MoneyTransaction transaction;
  final Currency primaryCurrency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGiven = transaction.direction == TransactionDirection.given;
    final isRepayment = transaction.kind == TransactionKind.repayment;
    final financeColors = context.financeColors;
    final amountColor = isGiven
        ? financeColors.negative
        : financeColors.positive;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = EgpFormatter(locale: locale);
    final dateLabel = AppDateFormatter(locale: locale).format(transaction.date);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: amountColor.withValues(alpha: 0.12),
        child: Icon(
          isGiven ? Icons.arrow_upward : Icons.arrow_downward,
          color: amountColor,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              isGiven ? l10n.directionGiven : l10n.directionReceived,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isRepayment) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: financeColors.neutralSurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(l10n.repaymentLabel, style: AppTypography.label),
            ),
          ],
          if (transaction.isEdited) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '(${l10n.editedLabel})',
              style: AppTypography.bodyMuted.copyWith(color: onSurfaceVariant),
            ),
          ],
        ],
      ),
      subtitle: Text(
        transaction.note?.isNotEmpty == true
            ? '$dateLabel · ${transaction.note}'
            : dateLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (transaction.amount.currency != primaryCurrency) ...[
            CurrencyIndicatorChip(currency: transaction.amount.currency),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            formatter.formatWithSymbol(transaction.amount),
            style: AppTypography.body.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
