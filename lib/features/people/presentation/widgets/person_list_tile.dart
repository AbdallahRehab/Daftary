import 'package:flutter/material.dart';

import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/presentation/widgets/balance_status_badge.dart';
import '../../domain/entities/person.dart';
import 'relationship_tag_chip.dart';

/// One row in the active-people list: name, relationship tag,
/// [BalanceStatusBadge] (T053), and an archive action.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    required this.person,
    required this.balance,
    super.key,
    this.onTap,
    this.onArchive,
  });

  final Person person;
  final PersonBalance balance;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final tag = person.relationshipTag;
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
          BalanceStatusBadge(status: balance.status, dense: true),
          if (onArchive != null)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              onPressed: onArchive,
            ),
        ],
      ),
    );
  }
}
