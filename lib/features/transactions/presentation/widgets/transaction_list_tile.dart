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
/// (User Story 3, Acceptance Scenario 1), and an occasion contribution
/// distinct from both, carrying the occasion's name (008 US2 AC4).
///
/// 018: the amount always renders in the record's own currency (FR-010);
/// a record whose currency differs from [primaryCurrency] also gets a
/// [CurrencyIndicatorChip], so an EGP-only history looks exactly as before.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    required this.transaction,
    super.key,
    this.occasionName,
    this.onTap,
    this.onDelete,
    this.onEditedTap,
    this.primaryCurrency = Currency.egp,
    this.conflictBadge,
  });

  final MoneyTransaction transaction;
  final Currency primaryCurrency;

  /// 021: a sync-conflict marker, set only while the record is in conflict
  /// — null leaves the row exactly as before.
  final Widget? conflictBadge;

  /// The linked occasion's name, resolved once per screen by
  /// `PersonDetailCubit` rather than per row (008). Ignored unless the row
  /// really is a contribution, so a stale name can never mislabel an
  /// ordinary transaction.
  final String? occasionName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  /// 022 C3: tapping the "Edited" marker opens the change history. Null
  /// leaves the marker as plain text.
  final VoidCallback? onEditedTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGiven = transaction.direction == TransactionDirection.given;
    final isRepayment = transaction.kind == TransactionKind.repayment;
    final occasionName = this.occasionName;
    final showOccasion =
        transaction.kind == TransactionKind.occasionContribution &&
        occasionName != null &&
        occasionName.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final financeColors = context.financeColors;
    final amountColor = isGiven
        ? financeColors.negative
        : financeColors.positive;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
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
          if (showOccasion)
            Semantics(
              // The visible text is the occasion's own name, so the kind it
              // stands for is announced rather than left implicit.
              label: '${l10n.occasionContributionBadge}: $occasionName',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  occasionName,
                  style: AppTypography.label.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (transaction.isEdited)
            _EditedMarker(
              label: '(${l10n.editedLabel})',
              semanticLabel: l10n.editedLabel,
              tooltip: l10n.changeHistoryTitle,
              color: onSurfaceVariant,
              onTap: onEditedTap,
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

/// The "Edited" marker; a 48dp-tall button when [onTap] is set (022 C3).
class _EditedMarker extends StatelessWidget {
  const _EditedMarker({
    required this.label,
    required this.semanticLabel,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTypography.bodyMuted.copyWith(color: color),
    );
    if (onTap == null) return text;
    return Semantics(
      button: true,
      label: '$semanticLabel, $tooltip',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('edited-marker'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(widthFactor: 1, child: text),
        ),
      ),
    );
  }
}
