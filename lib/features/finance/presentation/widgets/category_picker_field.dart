import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';
import 'category_display_name.dart';
import 'category_icon_registry.dart';

/// The entry form's category selector: a wrap of tappable chips, one per
/// active category of the entry's [type] (FR-001/FR-003).
///
/// Archived categories are filtered out here as well as in the cubit
/// (FR-011) — with one deliberate exception: the category already selected
/// on the entry being edited stays visible even when archived, so an edit
/// can be saved without silently re-categorizing the entry.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    required this.categories,
    required this.type,
    required this.onCategorySelected,
    required this.onManageCategories,
    super.key,
    this.selectedCategoryId,
    this.errorText,
    this.isLoading = false,
  });

  final List<Category> categories;
  final FinanceEntryType type;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  /// Opens category management (FR-007) without leaving the user stranded
  /// when none of the offered categories fits.
  final VoidCallback onManageCategories;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible = [
      for (final category in categories)
        if (category.type == type &&
            (!category.isArchived || category.id == selectedCategoryId))
          category,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.financeCategoryLabel,
                style: AppTypography.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onManageCategories,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(l10n.financeManageCategoriesAction),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.financeNoCategoriesTitle, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.financeNoCategoriesMessage,
                  style: AppTypography.bodyMuted.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in visible)
                _CategoryChip(
                  category: category,
                  isSelected: category.id == selectedCategoryId,
                  onSelected: () => onCategorySelected(category.id),
                ),
            ],
          ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.bodyMuted.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Color comes from the theme at render time, never from the persisted
    // category row (constitution Principle XV).
    final accent = CategoryIconRegistry.colorFor(context, category.type);
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: CategoryIconRegistry.surfaceColorFor(
        context,
        category.type,
      ),
      avatar: Icon(
        CategoryIconRegistry.iconFor(category.icon),
        size: 18,
        color: accent,
      ),
      label: Text(categoryDisplayName(l10n, category)),
    );
  }
}
