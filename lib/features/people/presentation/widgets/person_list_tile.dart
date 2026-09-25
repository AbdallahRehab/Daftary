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
    final hasTag = tag != null && tag.trim().isNotEmpty;
    return ListTile(
      onTap: onTap,
      title: Text(person.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      // The status badge sits under the name (not stacked under the amount)
      // because ListTile caps the trailing slot's height: at a large system
      // font the two stacked lines would overflow the row.
      subtitle: hasTag || status != null
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (status != null)
                    BalanceStatusBadge(status: status, dense: true),
                  if (hasTag) RelationshipTagChip(tag: tag),
                ],
              ),
            )
          : null,
      // Capped so a large amount, a multi-currency blocked balance, or a
      // large system font never squeezes the person's name out of the row;
      // the amount scales down to fit rather than truncating digits.
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.45,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Settled rows already read as "settled" from the badge alone; a
            // "0.00 EGP" amount beside it would only add noise.
            if (!isSettled) ...[
              // A blocked balance is never settled, so the compact
              // rate-needed label always lands on this line.
              if (balance.isBlocked) ...[
                Flexible(
                  child: _RateNeededLabel(
                    missingRatesFor: balance.missingRatesFor,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    amountText,
                    style: AppTypography.figure.copyWith(color: amountColor),
                  ),
                ),
              ),
            ],
            if (onArchive != null)
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: AppLocalizations.of(
                  context,
                )!.archivePersonTooltip(person.name),
                onPressed: isArchiving ? null : onArchive,
              ),
          ],
        ),
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
            Flexible(
              child: Text(
                codes,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
