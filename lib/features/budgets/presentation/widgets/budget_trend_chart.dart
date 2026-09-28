import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/budget_trend_point.dart';
import 'budget_month_format.dart';

/// Grouped planned-vs-actual bars, one group per month (FR-014,
/// research.md Decision 4).
///
/// Direction-aware: in RTL the months run from the right (oldest) to the
/// left (newest), each group's "planned" bar sits on its reading-start
/// side, and the amount axis moves to the right edge — the whole chart
/// mirrors, not just its labels.
///
/// Planned and actual never differ by color alone: planned is an outlined,
/// lightly filled bar and actual a solid one, and a month whose actual
/// exceeds its plan also gets a warning glyph under its month label.
///
/// The bar geometry is the only place figures become `double`s; every
/// number shown as text (tooltip, accessibility label) is formatted from
/// the exact minor-unit integers (FR-015).
///
/// 018 FR-009: a figure that needs a missing exchange rate (`null` on its
/// [BudgetTrendPoint]) gets no bar — a gap, never a guessed height — and
/// its month is marked with a rate-needed glyph under the label; tooltip
/// and accessibility text say "Rate needed" in its place. The screen names
/// the currencies in its `RateNeededBanner`.
class BudgetTrendChart extends StatelessWidget {
  const BudgetTrendChart({
    required this.points,
    this.height = 260,
    this.animationDuration = const Duration(milliseconds: 150),
    super.key,
  });

  /// Oldest month first, as `GetBudgetTrend` returns them.
  final List<BudgetTrendPoint> points;
  final double height;
  final Duration animationDuration;

  static const double _rodWidth = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final financeColors = context.financeColors;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final languageCode = Localizations.localeOf(context).languageCode;
    final egp = EgpFormatter(locale: languageCode);
    final compact = NumberFormat.compact(
      locale: numeralLocaleFor(languageCode),
    );

    // Display order: reading order, i.e. chronological from the reading
    // start. The data list itself is never reordered.
    final ordered = isRtl ? points.reversed.toList() : points;

    final plannedColor = colorScheme.primary;
    final plannedFill = colorScheme.primary.withValues(alpha: 0.18);
    final actualColor = colorScheme.tertiary;
    final overPlanColor = financeColors.negative;

    var maxMinor = 0;
    for (final point in points) {
      for (final figure in [point.plannedMinorUnits, point.actualMinorUnits]) {
        if (figure != null && figure > maxMinor) maxMinor = figure;
      }
    }
    final maxY = maxMinor == 0 ? 1.0 : _toMajor(maxMinor) * 1.15;

    // An unknown figure keeps its slot (so tooltips stay aligned) but draws
    // nothing.
    BarChartRodData gapRod() =>
        BarChartRodData(toY: 0, width: _rodWidth, color: Colors.transparent);
    BarChartRodData plannedRod(BudgetTrendPoint point) =>
        switch (point.plannedMinorUnits) {
          final planned? => BarChartRodData(
            toY: _toMajor(planned),
            width: _rodWidth,
            color: plannedFill,
            borderSide: BorderSide(color: plannedColor, width: 1.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
          null => gapRod(),
        };
    BarChartRodData actualRod(BudgetTrendPoint point) =>
        switch (point.actualMinorUnits) {
          final actual? => BarChartRodData(
            toY: _toMajor(actual),
            width: _rodWidth,
            color: point.isOverPlan ? overPlanColor : actualColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
          null => gapRod(),
        };
    String figure(BudgetTrendPoint point, int? minorUnits) =>
        switch (minorUnits) {
          final value? => egp.formatWithSymbol(
            Money.fromMinorUnits(value, point.currency),
          ),
          null => l10n.budgetRateNeededBadge,
        };

    final groups = [
      for (var i = 0; i < ordered.length; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: isRtl
              ? [actualRod(ordered[i]), plannedRod(ordered[i])]
              : [plannedRod(ordered[i]), actualRod(ordered[i])],
        ),
    ];

    final amountTitles = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (value, meta) {
          if (value == meta.max) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(
              NumeralParser.toWesternDigits(compact.format(value)),
              style: AppTypography.label.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
    const hidden = AxisTitles();

    final summary = [
      for (final point in points)
        l10n.budgetTrendMonthSummary(
          BudgetMonthFormat.medium(context, point.month),
          point.hasBudget
              ? figure(point, point.plannedMinorUnits)
              : l10n.budgetTrendNoBudget,
          figure(point, point.actualMinorUnits),
        ),
    ].join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Legend(
          plannedColor: plannedColor,
          plannedFill: plannedFill,
          actualColor: actualColor,
          overPlanColor: overPlanColor,
          showOverPlan: points.any((point) => point.isOverPlan),
          showRateNeeded: points.any((point) => point.isBlocked),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: summary,
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            child: BarChart(
              duration: animationDuration,
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                barGroups: groups,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colorScheme.outlineVariant, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: hidden,
                  leftTitles: isRtl ? hidden : amountTitles,
                  rightTitles: isRtl ? amountTitles : hidden,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= ordered.length) {
                          return const SizedBox.shrink();
                        }
                        final point = ordered[index];
                        return SideTitleWidget(
                          meta: meta,
                          space: AppSpacing.xs,
                          child: _MonthLabel(
                            key: ValueKey(
                              'budgetTrendMonthLabel-${point.month}',
                            ),
                            label: BudgetMonthFormat.short(
                              context,
                              point.month,
                            ),
                            hasBudget: point.hasBudget,
                            isOverPlan: point.isOverPlan,
                            isBlocked: point.isBlocked,
                            overPlanColor: overPlanColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    maxContentWidth: 180,
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = ordered[group.x];
                      final isPlanned = isRtl ? rodIndex == 1 : rodIndex == 0;
                      final style = AppTypography.label.copyWith(
                        color: colorScheme.onInverseSurface,
                      );
                      final value = isPlanned
                          ? (point.hasBudget
                                ? figure(point, point.plannedMinorUnits)
                                : l10n.budgetTrendNoBudget)
                          : figure(point, point.actualMinorUnits);
                      final kind = isPlanned
                          ? l10n.budgetTrendPlanned
                          : l10n.budgetTrendActual;
                      return BarTooltipItem(
                        '${BudgetMonthFormat.medium(context, point.month)}\n',
                        style.copyWith(fontWeight: FontWeight.w700),
                        textDirection: Directionality.of(context),
                        children: [
                          TextSpan(text: '$kind: $value', style: style),
                          if (!isPlanned && point.isOverPlan)
                            TextSpan(
                              text: '\n${l10n.budgetTrendOverPlan}',
                              style: style,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Chart geometry only — never used for any displayed figure.
  static double _toMajor(int minorUnits) =>
      minorUnits / Money.minorUnitsPerMajorUnit;
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({
    required this.label,
    super.key,
    required this.hasBudget,
    required this.isOverPlan,
    required this.isBlocked,
    required this.overPlanColor,
  });

  final String label;
  final bool hasBudget;
  final bool isOverPlan;

  /// A figure of this month needs a missing rate (018 FR-009).
  final bool isBlocked;
  final Color overPlanColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            // A month with no budget has nothing to compare; it stays on the
            // axis (so the window is continuous) but reads as secondary.
            color: hasBudget
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        if (isOverPlan)
          Icon(Icons.warning_amber_rounded, size: 14, color: overPlanColor)
        else if (isBlocked)
          Icon(
            Icons.currency_exchange,
            key: const ValueKey('budgetTrendRateNeededGlyph'),
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.plannedColor,
    required this.plannedFill,
    required this.actualColor,
    required this.overPlanColor,
    required this.showOverPlan,
    required this.showRateNeeded,
  });

  final Color plannedColor;
  final Color plannedFill;
  final Color actualColor;
  final Color overPlanColor;
  final bool showOverPlan;
  final bool showRateNeeded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _LegendItem(
          label: l10n.budgetTrendPlanned,
          swatch: _Swatch(fill: plannedFill, border: plannedColor),
        ),
        _LegendItem(
          label: l10n.budgetTrendActual,
          swatch: _Swatch(fill: actualColor),
        ),
        if (showOverPlan)
          _LegendItem(
            label: l10n.budgetTrendOverPlan,
            swatch: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: overPlanColor,
            ),
          ),
        if (showRateNeeded)
          _LegendItem(
            label: l10n.budgetRateNeededBadge,
            swatch: Icon(
              Icons.currency_exchange,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.swatch});

  final String label;
  final Widget swatch;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.fill, this.border});

  final Color fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: border == null ? null : Border.all(color: border!, width: 1.5),
      ),
    );
  }
}
