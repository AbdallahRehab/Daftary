import 'package:flutter/material.dart';

import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../cubit/finance_history_state.dart';

/// The period control behind FR-016: this month, last month, or a custom
/// `[start, end]` range.
///
/// The two fixed presets carry no dates of their own — they are resolved by
/// `DateRange.thisMonth()`/`lastMonth()` in the Cubit (research.md
/// Decision 6), so this widget only ever reports *which* preset was chosen.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.preset,
    required this.period,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
    super.key,
  });

  final FinancePeriodPreset preset;
  final DateRange period;
  final ValueChanged<FinancePeriodPreset> onPresetSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<FinancePeriodPreset>(
          segments: [
            ButtonSegment(
              value: FinancePeriodPreset.thisMonth,
              label: Text(l10n.financePeriodThisMonth),
            ),
            ButtonSegment(
              value: FinancePeriodPreset.lastMonth,
              label: Text(l10n.financePeriodLastMonth),
            ),
            ButtonSegment(
              value: FinancePeriodPreset.custom,
              label: Text(l10n.financePeriodCustom),
            ),
          ],
          selected: {preset},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onPresetSelected(selection.first),
        ),
        if (preset == FinancePeriodPreset.custom) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppDateField(
                  label: l10n.financePeriodStartLabel,
                  date: period.start,
                  // A start after the current end would describe an empty
                  // span, so the end is pushed along with it rather than
                  // silently producing zero results.
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onDateChanged: (start) => onCustomRangeSelected(
                    start,
                    start.isAfter(period.end) ? start : period.end,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppDateField(
                  label: l10n.financePeriodEndLabel,
                  date: period.end,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onDateChanged: (end) => onCustomRangeSelected(
                    end.isBefore(period.start) ? end : period.start,
                    end,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
