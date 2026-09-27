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
    this.conflictBadge,
  });

  final MoneyTransaction transaction;
  final Currency primaryCurrency;

  /// 021: a sync-conflict marker, set only while the record is in conflict
  /// — null leaves the row exactly as before.
  final Widget? conflictBadge;
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
      // Wraps rather than overflowing when the direction, the repayment tag,
      // and the edited marker don't fit on one line (narrow screen, long
      // translation, or a large system font).
      title: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(isGiven ? l10n.directionGiven : l10n.directionReceived),
          if (isRepayment)
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
          if (transaction.isEdited)
            Text(
              '(${l10n.editedLabel})',
              style: AppTypography.bodyMuted.copyWith(color: onSurfaceVariant),
            ),
          ?conflictBadge,
        ],
      ),
      subtitle: Text(
        transaction.note?.isNotEmpty == true
            ? '$dateLabel · ${transaction.note}'
            : dateLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      // Capped so a large amount or a large system font never squeezes the
      // direction/date out of the row; the amount scales down to fit rather
      // than truncating digits.
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.45,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (transaction.amount.currency != primaryCurrency) ...[
              CurrencyIndicatorChip(currency: transaction.amount.currency),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  formatter.formatWithSymbol(transaction.amount),
                  style: AppTypography.figure.copyWith(color: amountColor),
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.deleteTransactionTooltip,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
