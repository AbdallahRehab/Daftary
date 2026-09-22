import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/presentation/widgets/balance_status_badge.dart';
import '../../domain/entities/person.dart';
import 'relationship_tag_chip.dart';

/// One row in the active-people list: name, relationship tag, net amount +
/// [BalanceStatusBadge] (T053), and an archive action.
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
    final isSettled = balance.status == RelationshipStatus.settled;
    final financeColors = context.financeColors;
    final amountColor = balance.status == RelationshipStatus.theyOweYou
        ? financeColors.positive
        : financeColors.negative;
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
                Text(
                  EgpFormatter(
                    locale: Localizations.localeOf(context).languageCode,
                  ).formatWithSymbol(balance.net.abs()),
                  style: AppTypography.body.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              BalanceStatusBadge(status: balance.status, dense: true),
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
