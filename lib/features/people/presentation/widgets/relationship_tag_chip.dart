import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The predefined relationship-tag values a person's profile can hold; any
/// other non-empty string is accepted as a free-text custom tag (FR-001,
/// data-model.md).
const List<String> predefinedRelationshipTags = [
  'family',
  'friend',
  'colleague',
  'customer',
  'supplier',
  'other',
];

String relationshipTagLabel(AppLocalizations l10n, String tag) {
  return switch (tag) {
    'family' => l10n.relationshipFamily,
    'friend' => l10n.relationshipFriend,
    'colleague' => l10n.relationshipColleague,
    'customer' => l10n.relationshipCustomer,
    'supplier' => l10n.relationshipSupplier,
    'other' => l10n.relationshipOther,
    _ => tag,
  };
}

/// A small pill rendering a person's `relationshipTag` — one of the
/// predefined values (translated) or a free-text custom tag verbatim.
class RelationshipTagChip extends StatelessWidget {
  const RelationshipTagChip({required this.tag, super.key});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(relationshipTagLabel(l10n, tag), style: AppTypography.label),
    );
  }
}
