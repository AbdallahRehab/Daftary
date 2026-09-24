import 'package:flutter/material.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/currency_indicator_chip.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/finance_entry.dart';
import 'category_icon_registry.dart';

/// One history row: category, amount, direction, date, note, and an
/// "edited" marker when the entry carries an `editedAt` (FR-012, FR-019).
///
/// Income and expense are distinguished by color *and* by a direction icon
/// plus a signed amount — never by color alone (constitution Accessibility
/// standard, FR-005) — and every color is a design token read from
/// `context.financeColors`, never a hardcoded value (Principle XV).
class FinanceEntryListTile extends StatelessWidget {
  const FinanceEntryListTile({
    required this.entry,
    required this.categoryName,
    required this.categoryIconKey,
    this.primaryCurrency = Currency.egp,
    super.key,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final FinanceEntry entry;

  /// Resolved by the caller (via `categoryDisplayName`), so this row never
  /// has to look a category up itself while scrolling.
  final String categoryName;
  final String categoryIconKey;

  /// The user's primary currency (018 FR-005). An entry in any other
  /// currency carries a [CurrencyIndicatorChip] next to its amount
  /// (FR-010); primary-currency rows render exactly as before 018.
  final Currency primaryCurrency;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncome = entry.isIncome;
    final amountColor = CategoryIconRegistry.colorFor(context, entry.type);
    final surfaceColor = CategoryIconRegistry.surfaceColorFor(
      context,
      entry.type,
    );
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = AppDateFormatter(locale: locale).format(entry.date);
    final amountLabel = EgpFormatter(
      locale: locale,
    ).formatWithSymbol(entry.amount);
    final note = entry.note;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: surfaceColor,
        child: Icon(
          CategoryIconRegistry.iconFor(categoryIconKey),
          color: amountColor,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(categoryName, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.xs),
          // The direction is carried redundantly by an icon and a label, so
          // the income/expense distinction survives for a user who cannot
          // separate the two accent colors.
          Icon(
            isIncome ? Icons.south_west : Icons.north_east,
            size: 16,
            color: amountColor,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              isIncome ? l10n.financeTypeIncome : l10n.financeTypeExpense,
              style: AppTypography.label.copyWith(color: amountColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (entry.isEdited) ...[
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '(${l10n.editedLabel})',
                style: AppTypography.bodyMuted.copyWith(
                  color: onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        note != null && note.isNotEmpty ? '$dateLabel · $note' : dateLabel,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      // Amount plus, at most, one overflow button. Two inline icon buttons
      // made `trailing` wide enough to squeeze the title to ~70px, which
      // overflowed the row and left the category name unreadable anyway.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.amount.currency != primaryCurrency) ...[
            CurrencyIndicatorChip(currency: entry.amount.currency),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            isIncome ? '+$amountLabel' : '-$amountLabel',
            style: AppTypography.body.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<_EntryAction>(
              tooltip: l10n.commonEdit,
              onSelected: (action) => switch (action) {
                _EntryAction.edit => onEdit?.call(),
                _EntryAction.delete => onDelete?.call(),
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  PopupMenuItem(
                    value: _EntryAction.edit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.commonEdit),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  PopupMenuItem(
                    value: _EntryAction.delete,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.commonDelete),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _EntryAction { edit, delete }
