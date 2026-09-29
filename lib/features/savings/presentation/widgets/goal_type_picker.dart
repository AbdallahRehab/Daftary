import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/savings_goal_type.dart';
import 'savings_format.dart';

/// Picks a goal type from the standard set, or "No type" for a plain
/// custom-named goal (FR-001, US1 AS-5). The type only chooses an icon and
/// label; it never changes a calculation.
class GoalTypePicker extends StatelessWidget {
  const GoalTypePicker({
    required this.selectedType,
    required this.onTypeSelected,
    super.key,
  });

  final String? selectedType;
  final ValueChanged<String?> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.savingsGoalTypeLabel,
          style: AppTypography.label.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in <String?>[
              null,
              ...SavingsGoalType.standardValues,
            ])
              ChoiceChip(
                avatar: Icon(savingsGoalTypeIcon(type)),
                label: Text(savingsGoalTypeLabel(l10n, type)),
                selected: selectedType == type,
                onSelected: (_) => onTypeSelected(type),
              ),
          ],
        ),
      ],
    );
  }
}
