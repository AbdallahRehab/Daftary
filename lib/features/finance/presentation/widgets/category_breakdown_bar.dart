import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../currency/presentation/widgets/rate_needed_banner.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_breakdown_item.dart';
import '../../domain/entities/finance_entry_type.dart';
import 'category_display_name.dart';
import 'category_icon_registry.dart';

/// The per-category breakdown for the selected period (FR-015): each
/// category's total and its share, largest first.
///
/// The share is rendered twice on purpose — as a proportional bar and as a
/// percentage label — so the ordering is readable at a glance and still
/// exact for anyone who needs the number. Icon glyph and color both resolve
/// through [CategoryIconRegistry] from the theme, never from a persisted
/// color (constitution Principle XV).
///
/// 018: totals are in the primary currency. A blocked breakdown (FR-009)
/// shows a [RateNeededBanner] naming the missing currencies; rows keep any
/// total that is still fully convertible, but no row shows a share, since
/// every share would be of an incomplete period total.
class CategoryBreakdownBar extends StatelessWidget {
  const CategoryBreakdownBar({
    required this.breakdown,
    required this.categoriesById,
    super.key,
  });

  /// Already ordered largest-first (blocked rows last) by
  /// `GetCategoryBreakdown`.
  final CategoryBreakdown breakdown;

  /// Resolves each row's direction, which is what decides its color.
  final Map<String, Category> categoriesById;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(l10n.financeBreakdownTitle, style: AppTypography.title),
        ),
        if (breakdown.isBlocked) ...[
          RateNeededBanner(
            missingRatesFor: breakdown.missingRatesFor,
            onSetRate: () => context.push('/settings/currency/rates'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final item in breakdown.items)
          _BreakdownRow(
            item: item,
            type: categoriesById[item.categoryId]?.type ?? CategoryType.expense,
          ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.type});

  final CategoryBreakdownItem item;
  final CategoryType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = CategoryIconRegistry.colorFor(context, type);
    final trackColor = CategoryIconRegistry.surfaceColorFor(context, type);
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final name = categoryDisplayNameFor(
      l10n,
      iconKey: item.icon,
      name: item.categoryName,
    );
    final total = item.total;
    final share = item.shareOfPeriod;

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
                // A blocked category total is shown as a dash — never a
                // partial sum (018 FR-009).
                total == null ? '—' : formatter.formatWithSymbol(total),
                style: AppTypography.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (share != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.financeBreakdownShare((share * 100).round().toString()),
                  style: AppTypography.bodyMuted.copyWith(
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
