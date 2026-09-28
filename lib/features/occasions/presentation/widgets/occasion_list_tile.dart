import 'package:flutter/material.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/occasion.dart';
import 'occasion_type_chip.dart';

/// One row of the occasions list: name, date, type, and — for an occasion
/// whose date has not arrived yet — an "upcoming" marker, since a
/// pre-planned occasion with no contributions is expected rather than
/// incomplete (spec Edge Cases).
class OccasionListTile extends StatelessWidget {
  const OccasionListTile({required this.occasion, super.key, this.onTap});

  final Occasion occasion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeColors = context.financeColors;
    final formattedDate = AppDateFormatter(
      locale: Localizations.localeOf(context).languageCode,
    ).format(occasion.date);
    final today = DateTime.now();
    final isUpcoming = occasion.date.isAfter(
      DateTime(today.year, today.month, today.day),
    );

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(occasion.name, style: AppTypography.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formattedDate,
              style: AppTypography.bodyMuted.copyWith(
                color: financeColors.neutral,
              ),
            ),
            OccasionTypeChip(type: occasion.type),
            if (isUpcoming)
              Text(
                l10n.occasionUpcomingLabel,
                style: AppTypography.label.copyWith(
                  color: financeColors.warning,
                ),
              ),
            if (occasion.isArchived)
              Text(
                l10n.occasionArchivedLabel,
                style: AppTypography.label.copyWith(
                  color: financeColors.neutral,
                ),
              ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
