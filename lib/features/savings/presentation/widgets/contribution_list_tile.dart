import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/savings_contribution.dart';
import 'savings_format.dart';

/// Which per-entry action the user picked.
enum ContributionTileAction { edit, delete }

/// One history row (FR-008): labelled by type in words (never colour
/// alone), with its date and optional note, and the amount as entered. When
/// that was another currency, the converted goal-currency amount — the one
/// that counts — is shown under it (FR-028).
class ContributionListTile extends StatelessWidget {
  const ContributionListTile({
    required this.entry,
    required this.goalCurrency,
    required this.onAction,
    this.onEditedTap,
    super.key,
  });

  final SavingsContribution entry;
  final Currency goalCurrency;
  final ValueChanged<ContributionTileAction> onAction;

  /// 022 C3: tapping the "Edited" marker opens the change history. Null
  /// keeps the marker inline plain text.
  final VoidCallback? onEditedTap;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final theme = Theme.of(context);
    final colors = context.financeColors;
    final isWithdrawal = entry.isWithdrawal;
    final typeLabel = isWithdrawal
        ? l10n.savingsEntryWithdrawal
        : l10n.savingsEntryContribution;
    final tint = isWithdrawal ? colors.neutral : colors.positive;
    final sign = isWithdrawal ? '−' : '+';
    final converted = entry.enteredCurrency != goalCurrency;
    final note = entry.isStartingAmount
        ? l10n.savingsEntryStartingAmount
        : entry.note;
    final muted = AppTypography.bodyMuted.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final amounts = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$sign${format.money(entry.enteredAmount)}',
          style: AppTypography.figure.copyWith(color: tint),
          textAlign: TextAlign.end,
        ),
        if (converted)
          Text(
            l10n.savingsEntryConvertedAmount(
              format.money(
                Money.fromMinorUnits(entry.amountMinorUnits, goalCurrency),
              ),
            ),
            style: muted,
            textAlign: TextAlign.end,
          ),
      ],
    );

    // A plain row rather than a `ListTile`: a ListTile's trailing slot is
    // unconstrained, so a large (or converted) amount on a 360dp phone
    // would claim the whole width. Here the amounts share the row and wrap
    // instead (T071).
    return InkWell(
      onTap: () => onAction(ContributionTileAction.edit),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              isWithdrawal ? Icons.north_east : Icons.south_west,
              color: tint,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel, style: AppTypography.body),
                  Text(
                    [
                      format.date(entry.date),
                      if (note != null && note.isNotEmpty) note,
                      if (entry.isEdited && onEditedTap == null)
                        l10n.savingsEntryEditedLabel,
                    ].join(' · '),
                    style: muted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.isEdited && onEditedTap != null)
                    Semantics(
                      button: true,
                      label:
                          '${l10n.savingsEntryEditedLabel}, '
                          '${l10n.changeHistoryTitle}',
                      excludeSemantics: true,
                      child: InkWell(
                        key: const ValueKey('edited-marker'),
                        onTap: onEditedTap,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: 1,
                            child: Text(
                              l10n.savingsEntryEditedLabel,
                              style: muted.copyWith(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(flex: 4, child: amounts),
            PopupMenuButton<ContributionTileAction>(
              tooltip: l10n.savingsEntryActionsTooltip,
              onSelected: onAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ContributionTileAction.edit,
                  child: Text(l10n.savingsEntryEditAction),
                ),
                PopupMenuItem(
                  value: ContributionTileAction.delete,
                  child: Text(l10n.savingsEntryDeleteAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
