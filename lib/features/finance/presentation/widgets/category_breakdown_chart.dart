import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/category_breakdown_item.dart';
import 'category_display_name.dart';
import 'category_icon_registry.dart';

/// The Reports screen's expense breakdown for one period (FR-002): each
/// category's total and share, largest first.
///
/// Deliberately the same visual language as 007's `CategoryBreakdownBar` —
/// icon, name, amount, then a proportional bar with its percentage — so
/// the breakdown reads the same wherever it appears. Glyph and color both
/// resolve through [CategoryIconRegistry] from the theme.
class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({required this.items, super.key});

  /// Expense categories only, as `GetCategoryBreakdown` returned them.
  /// Already ordered by the repository; sorted again here so a caller that
  /// reorders cannot break FR-002.
  final List<CategoryBreakdownItem> items;

  static const String rowKeyPrefix = 'reportsBreakdownRow-';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          l10n.reportsBreakdownEmpty,
          style: AppTypography.bodyMuted.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final ordered = [...items]
      ..sort((a, b) => b.total.minorUnits.compareTo(a.total.minorUnits));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in ordered)
          _BreakdownRow(
            key: ValueKey('$rowKeyPrefix${item.categoryId}'),
            item: item,
          ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, super.key});

  final CategoryBreakdownItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = CategoryIconRegistry.colorFor(context, CategoryType.expense);
    final trackColor = CategoryIconRegistry.surfaceColorFor(
      context,
      CategoryType.expense,
    );
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final name = categoryDisplayNameFor(
      l10n,
      iconKey: item.icon,
      name: item.categoryName,
    );
    final percent = (item.shareOfPeriod * 100).round().toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                CategoryIconRegistry.iconFor(item.icon),
                size: 18,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(name, style: AppTypography.body)),
              Text(
                formatter.formatWithSymbol(item.total),
                style: AppTypography.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  // Fills from the reading-start edge, so it mirrors under
                  // RTL with no extra handling.
                  child: LinearProgressIndicator(
                    value: item.shareOfPeriod.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.reportsCategoryShare(percent),
                style: AppTypography.bodyMuted.copyWith(
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
