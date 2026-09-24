import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/presentation/widgets/balance_amount_text.dart';
import '../../../transactions/presentation/widgets/balance_status_badge.dart';
import '../../domain/entities/person.dart';
import 'relationship_tag_chip.dart';

/// One row in the active-people list: name, relationship tag, net amount +
/// [BalanceStatusBadge] (T053), and an archive action.
///
/// 018: a balance blocked on a missing exchange rate shows its per-currency
/// amounts in their own currencies plus a compact rate-needed label naming
/// the missing currencies (FR-009); the badge is shown only when the
/// status is still knowable.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    required this.person,
    required this.balance,
    super.key,
    this.onTap,
    this.onArchive,
    this.isArchiving = false,
  });

  final Person person;
  final PersonBalance balance;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;

  /// True while an `archive()` call for this row's [person] is already in
  /// flight (FR-006) — disables the archive control instead of hiding it,
  /// so a rapid double-tap can't fire a second call.
  final bool isArchiving;

  @override
  Widget build(BuildContext context) {
    final tag = person.relationshipTag;
    final status = balance.status;
    final isSettled = status == RelationshipStatus.settled;
    final financeColors = context.financeColors;
    final amountColor = switch (status) {
      RelationshipStatus.theyOweYou => financeColors.positive,
      null => Theme.of(context).colorScheme.onSurfaceVariant,
      _ => financeColors.negative,
    };
    final locale = Localizations.localeOf(context).languageCode;
    final net = balance.net;
    final amountText = net != null
        ? EgpFormatter(locale: locale).formatWithSymbol(net.abs())
        : formatNativeNets(balance.nativeNets, locale: locale);
    return ListTile(
      onTap: onTap,
      title: Text(person.name),
      subtitle: tag != null && tag.trim().isNotEmpty
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: RelationshipTagChip(tag: tag),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Settled rows already read as "settled" from the badge
              // alone; a "0.00 EGP" amount above it would only add noise.
              if (!isSettled) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A blocked balance is never settled, so the compact
                    // rate-needed label always lands on this line.
                    if (balance.isBlocked) ...[
                      _RateNeededLabel(
                        missingRatesFor: balance.missingRatesFor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      amountText,
                      style: AppTypography.body.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
              if (status != null)
                BalanceStatusBadge(status: status, dense: true),
            ],
          ),
          if (onArchive != null)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              onPressed: isArchiving ? null : onArchive,
            ),
        ],
      ),
    );
  }
}

/// Compact list-row stand-in for `RateNeededBanner`: an exchange icon plus
/// the missing currency codes, with the full "rate needed" title exposed as
/// a tooltip and to screen readers.
class _RateNeededLabel extends StatelessWidget {
  const _RateNeededLabel({required this.missingRatesFor});

  final List<Currency> missingRatesFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme.tertiary;
    final codes = missingRatesFor.map((c) => c.code).join(', ');
    return Tooltip(
      key: const Key('person_rate_needed_label'),
      message: l10n.rateNeededTitle,
      child: Semantics(
        label: l10n.rateNeededMessage(codes),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_exchange, size: 14, color: color),
            const SizedBox(width: 2),
            Text(codes, style: AppTypography.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
