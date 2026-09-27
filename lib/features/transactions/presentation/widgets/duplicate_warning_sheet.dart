import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../people/domain/entities/person.dart';

/// Shown when the cubit surfaces a possible-duplicate name match (FR-003).
/// Lets the user pick the existing person or explicitly confirm creating a
/// new one — never a silent auto-merge (Edge Cases).
class DuplicateWarningSheet extends StatelessWidget {
  const DuplicateWarningSheet({
    required this.matches,
    required this.onPickExisting,
    required this.onCreateNewAnyway,
    super.key,
  });

  final List<Person> matches;
  final ValueChanged<Person> onPickExisting;
  final VoidCallback onCreateNewAnyway;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Scrollable so several matches plus both actions stay reachable on a
    // landscape phone, where the sheet can be only ~300dp tall.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.duplicateWarningTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.duplicateWarningMessage,
              style: AppTypography.bodyMuted.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...matches.map(
              (person) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(person.name, style: AppTypography.body),
                            if (person.phoneNumber != null)
                              Text(
                                person.phoneNumber!,
                                style: AppTypography.bodyMuted.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPickExisting(person);
                        },
                        child: Text(l10n.duplicateUseExisting),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: l10n.duplicateCreateNew,
              onPressed: () {
                Navigator.of(context).pop();
                onCreateNewAnyway();
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showDuplicateWarningSheet(
  BuildContext context, {
  required List<Person> matches,
  required ValueChanged<Person> onPickExisting,
  required VoidCallback onCreateNewAnyway,
}) {
  return showAppModalSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DuplicateWarningSheet(
      matches: matches,
      onPickExisting: onPickExisting,
      onCreateNewAnyway: onCreateNewAnyway,
    ),
  );
}
