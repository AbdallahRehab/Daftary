import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/presentation/widgets/balance_status_badge.dart';
import '../../domain/entities/occasion_participant_row.dart';

/// One row of an occasion's participant list (FR-016).
///
/// The status badge shows the person's **whole-history** standing, not an
/// occasion-scoped one, so this screen and the person's own profile can
/// never give two different answers to "does this person owe me" (FR-009) —
/// which is why it reuses 001's [BalanceStatusBadge] rather than rendering
/// its own variant.
class ParticipantRow extends StatelessWidget {
  const ParticipantRow({
    required this.row,
    super.key,
    this.onTap,
    this.onRemove,
  });

  final OccasionParticipantRow row;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeColors = context.financeColors;
    final isReceived = row.direction == TransactionDirection.received;
    final amountColor = isReceived
        ? financeColors.positive
        : financeColors.negative;
    final amount = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    ).formatWithSymbol(row.amount);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.personName, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.xs),
                  BalanceStatusBadge(
                    status: row.personOverallStatus,
                    dense: true,
                  ),
                  if (row.note != null && row.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      row.note!,
                      style: AppTypography.bodyMuted.copyWith(
                        color: financeColors.neutral,
                      ),
                    ),
                  ],
                  if (!row.countsTowardBalance) ...[
                    const SizedBox(height: AppSpacing.xs),
                    // Said out loud rather than left as a silent absence:
                    // without it, a condolence contribution missing from
                    // someone's balance looks like a bug rather than the
                    // deliberate choice it is (FR-018).
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: financeColors.neutral,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.occasionParticipantCountsTowardBalanceLabel,
                            style: AppTypography.label.copyWith(
                              color: financeColors.neutral,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTypography.amount.copyWith(color: amountColor),
                ),
                Text(
                  isReceived
                      ? l10n.occasionParticipantDirectionReceived
                      : l10n.occasionParticipantDirectionGiven,
                  style: AppTypography.label.copyWith(
                    color: financeColors.neutral,
                  ),
                ),
              ],
            ),
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.occasionRemoveParticipantAction,
              ),
          ],
        ),
      ),
    );
  }
}
