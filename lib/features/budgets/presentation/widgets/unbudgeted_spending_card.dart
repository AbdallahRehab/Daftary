import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/presentation/widgets/category_display_name.dart';
import '../../../finance/presentation/widgets/category_icon_registry.dart';
import '../../domain/entities/budget_summary.dart';

/// Spending this month in categories the budget does not cover (FR-007) —
/// listed on its own, never folded into a budgeted line and never dropped,
/// so every expense in the month is accounted for somewhere (SC-005).
///
/// 018 FR-009: an item whose spend needs a missing exchange rate is still
/// listed, with its amount shown as "—" beside a rate-needed icon, and the
/// total reads "—" too — it would otherwise leave that item out.
class UnbudgetedSpendingCard extends StatelessWidget {
  const UnbudgetedSpendingCard({required this.items, super.key});

  final List<UnbudgetedCategorySpend> items;

  /// What an unknown amount reads as — never a guessed number.
  static const String _unknown = '—';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final total = items.any((item) => item.isBlocked)
        ? null
        : Money.fromMinorUnits(
            items.fold(0, (sum, item) => sum + item.amountMinorUnits!),
            items.firstOrNull?.currency ?? Currency.egp,
          );
    final muted = AppTypography.bodyMuted.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.playlist_add_check_circle_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.budgetUnbudgetedTitle,
                  style: AppTypography.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.budgetUnbudgetedMessage, style: muted),
          const SizedBox(height: AppSpacing.sm),
          for (final item in items)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.xs + 2,
              ),
              child: Row(
                children: [
                  Icon(
                    CategoryIconRegistry.iconFor(item.categoryIcon),
                    size: 18,
                    color: CategoryIconRegistry.colorFor(
                      context,
                      CategoryType.expense,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      categoryDisplayNameFor(
                        l10n,
                        iconKey: item.categoryIcon,
                        name: item.categoryName,
                      ),
                      style: AppTypography.body,
                    ),
                  ),
                  if (item.amount case final amount?)
                    Text(
                      formatter.formatWithSymbol(amount),
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Semantics(
                      key: ValueKey(
                        'budgetUnbudgetedRateNeeded-${item.categoryId}',
                      ),
                      label: l10n.budgetRateNeededBadge,
                      excludeSemantics: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.currency_exchange,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _unknown,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Divider(
            height: AppSpacing.md,
            color: theme.colorScheme.outlineVariant,
          ),
          Row(
            children: [
              Expanded(
                child: Text(l10n.budgetUnbudgetedTotalLabel, style: muted),
              ),
              Text(
                total == null ? _unknown : formatter.formatWithSymbol(total),
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
