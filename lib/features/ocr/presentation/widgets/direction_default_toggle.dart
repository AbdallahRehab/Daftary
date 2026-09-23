import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../transactions/domain/entities/money_transaction.dart';

/// The batch-level default direction control (FR-005).
///
/// A plain "Name — Amount" line carries no direction at all, so this is the
/// control that saves the user from setting the same thing on every row.
/// It starts unset rather than guessing: an unchosen default is visible on
/// the review screen as an incomplete entry, whereas a silently assumed one
/// would look like something the app had read off the paper.
class DirectionDefaultToggle extends StatelessWidget {
  const DirectionDefaultToggle({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });

  final TransactionDirection? value;
  final ValueChanged<TransactionDirection> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ocrPrepDefaultDirectionLabel, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.ocrPrepDefaultDirectionHint,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<TransactionDirection>(
            segments: [
              ButtonSegment(
                value: TransactionDirection.received,
                label: Text(l10n.ocrPrepDirectionReceived),
                icon: const Icon(Icons.south_west),
              ),
              ButtonSegment(
                value: TransactionDirection.given,
                label: Text(l10n.ocrPrepDirectionGiven),
                icon: const Icon(Icons.north_east),
              ),
            ],
            // An empty selection is a real state here — "the user has not
            // chosen yet" — not a bug to be defaulted away.
            selected: value == null ? const {} : {value!},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isEmpty) return;
                    onChanged(selection.first);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
