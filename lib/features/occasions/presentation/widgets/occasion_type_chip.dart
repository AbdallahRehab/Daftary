import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/occasion_type.dart';

/// Resolves an `Occasion.type` to its display label: one of
/// [OccasionType.standardValues] translated, or a free-text custom value
/// rendered verbatim (FR-002).
///
/// Deliberately the same shape as `relationshipTagLabel` in 001 — the
/// standard-set-plus-custom problem is solved once, in one pattern, so the
/// two never drift apart.
String occasionTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    OccasionType.wedding => l10n.occasionTypeWedding,
    OccasionType.engagement => l10n.occasionTypeEngagement,
    OccasionType.birthday => l10n.occasionTypeBirthday,
    OccasionType.newbornSebou => l10n.occasionTypeNewbornSebou,
    OccasionType.condolence => l10n.occasionTypeCondolence,
    OccasionType.celebration => l10n.occasionTypeCelebration,
    OccasionType.other => l10n.occasionTypeOther,
    _ => type,
  };
}

/// A small pill rendering an occasion's type — a standard value translated,
/// or a custom one verbatim.
class OccasionTypeChip extends StatelessWidget {
  const OccasionTypeChip({required this.type, super.key});

  final String type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: context.financeColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        occasionTypeLabel(l10n, type),
        style: AppTypography.label.copyWith(
          color: context.financeColors.neutral,
        ),
      ),
    );
  }
}
