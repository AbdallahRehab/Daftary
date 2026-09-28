import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/budget_month.dart';
import 'budget_month_format.dart';

/// Previous / next month control for the budget month view (US4), showing
/// the selected month as a localized "Month Year" label.
///
/// Laid out in a direction-aware [Row], so "previous" always sits at the
/// reading start (the right in Arabic) and "next" at the reading end. The
/// chevrons are `matchTextDirection` icons, so they mirror with it — the
/// arrow always points away from the label, toward the month it moves to.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    required this.month,
    required this.onChanged,
    this.firstMonth,
    this.lastMonth,
    super.key,
  });

  /// The selected month, `'YYYY-MM'`.
  final String month;

  /// Called with the new `'YYYY-MM'` month after a previous/next tap.
  final ValueChanged<String> onChanged;

  /// Optional inclusive bounds (`'YYYY-MM'`); the matching button is
  /// disabled at the bound. `null` means unbounded in that direction.
  final String? firstMonth;
  final String? lastMonth;

  // 'YYYY-MM' keys order correctly as plain strings.
  bool get _canGoBack => firstMonth == null || month.compareTo(firstMonth!) > 0;
  bool get _canGoForward =>
      lastMonth == null || month.compareTo(lastMonth!) < 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = BudgetMonthFormat.long(context, month);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('monthNavigatorPrevious'),
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.budgetMonthNavPrevious,
            onPressed: _canGoBack
                ? () => onChanged(BudgetMonth.shift(month, -1))
                : null,
          ),
          Expanded(
            child: Semantics(
              label: l10n.budgetMonthNavCurrentLabel(label),
              excludeSemantics: true,
              liveRegion: true,
              child: Text(
                label,
                style: AppTypography.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('monthNavigatorNext'),
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.budgetMonthNavNext,
            onPressed: _canGoForward
                ? () => onChanged(BudgetMonth.shift(month, 1))
                : null,
          ),
        ],
      ),
    );
  }
}
