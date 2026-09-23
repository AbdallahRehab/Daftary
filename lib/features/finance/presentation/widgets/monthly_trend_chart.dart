import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/spending_trend_point.dart';

/// Paired income/expense bars, one pair per month (FR-001), hand-built
/// rather than via a charting package (013 research.md Decision 7).
///
/// Direction-aware with no separate RTL code path: the months, the amount
/// axis, and the legend are laid out by ordinary `Row`/`Wrap`s, which
/// already follow the ambient [Directionality], and each month's
/// [TrendBarsPainter] is handed that same direction to put income on the
/// reading-start side. Under RTL the whole chart mirrors — oldest month and
/// axis at the right — not just its text (FR-006).
///
/// Income and expense never differ by color alone: income is a solid bar,
/// expense an outlined, lightly filled one, and the legend pairs each with
/// a direction icon and a label. Colors come from the theme's chart tokens
/// (constitution Principle XV).
class MonthlyTrendChart extends StatelessWidget {
  const MonthlyTrendChart({required this.points, this.height = 200, super.key});

  /// Oldest month first, as `GetSpendingTrend` returns them.
  final List<SpendingTrendPoint> points;

  /// The bar area's height, month labels excluded.
  final double height;

  static const String monthKeyPrefix = 'reportsTrendMonth-';
  static const Key axisKey = ValueKey('reportsTrendAxis');
  static const Key incomeLegendKey = ValueKey('reportsTrendLegendIncome');
  static const Key expenseLegendKey = ValueKey('reportsTrendLegendExpense');

  /// The key of the month group starting at [monthStart], e.g.
  /// `reportsTrendMonth-2026-09`.
  static String monthKey(DateTime monthStart) =>
      '$monthKeyPrefix${monthStart.year}-'
      '${monthStart.month.toString().padLeft(2, '0')}';

  static const IconData incomeIcon = Icons.arrow_downward;
  static const IconData expenseIcon = Icons.arrow_upward;

  static const double _labelHeight = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final financeColors = context.financeColors;
    final direction = Directionality.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final numeralLocale = numeralLocaleFor(languageCode);
    final egp = EgpFormatter(locale: languageCode);

    final incomeColor = financeColors.chartPositive;
    final expenseColor = financeColors.chartNegative;
    final expenseFill = expenseColor.withValues(alpha: 0.25);

    var maxMinor = 0;
    for (final point in points) {
      maxMinor = math.max(
        maxMinor,
        math.max(point.totalIncomeMinorUnits, point.totalExpenseMinorUnits),
      );
    }

    final axisStyle = AppTypography.label.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final compact = NumberFormat.compact(locale: numeralLocale);
    String axisLabel(int minorUnits) => NumeralParser.toWesternDigits(
      compact.format(minorUnits ~/ Money.minorUnitsPerMajorUnit),
    );

    // One line per month for screen readers, since the bars themselves
    // carry no text.
    final summary = [
      for (final point in points)
        '${_monthLabel(DateFormat.yMMM(numeralLocale), point)}: '
            '${l10n.reportsIncome} '
            '${egp.formatWithSymbol(Money.fromMinorUnits(point.totalIncomeMinorUnits))}, '
            '${l10n.reportsExpenses} '
            '${egp.formatWithSymbol(Money.fromMinorUnits(point.totalExpenseMinorUnits))}, '
            '${l10n.reportsNet} '
            '${egp.formatWithSymbol(Money.fromMinorUnits(point.netMinorUnits))}',
    ].join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendItem(
              key: incomeLegendKey,
              icon: incomeIcon,
              label: l10n.reportsIncome,
              swatch: _Swatch(fill: incomeColor),
              color: incomeColor,
            ),
            _LegendItem(
              key: expenseLegendKey,
              icon: expenseIcon,
              label: l10n.reportsExpenses,
              swatch: _Swatch(fill: expenseFill, border: expenseColor),
              color: expenseColor,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          container: true,
          label: summary,
          excludeSemantics: true,
          child: SizedBox(
            height: height + _labelHeight + AppSpacing.xs,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The amount axis sits on the reading-start edge: first in
                // the row, so a `Row` under RTL moves it to the right.
                Column(
                  key: axisKey,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(axisLabel(maxMinor), style: axisStyle),
                          Text(axisLabel(0), style: axisStyle),
                        ],
                      ),
                    ),
                    const SizedBox(height: _labelHeight + AppSpacing.xs),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final point in points)
                        Expanded(
                          child: Column(
                            key: ValueKey(monthKey(point.period.start)),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  painter: TrendBarsPainter(
                                    incomeMinorUnits:
                                        point.totalIncomeMinorUnits,
                                    expenseMinorUnits:
                                        point.totalExpenseMinorUnits,
                                    maxMinorUnits: maxMinor,
                                    incomeColor: incomeColor,
                                    expenseColor: expenseColor,
                                    expenseFillColor: expenseFill,
                                    baselineColor: colorScheme.outlineVariant,
                                    textDirection: direction,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SizedBox(
                                height: _labelHeight,
                                child: Text(
                                  _monthLabel(
                                    DateFormat.MMM(numeralLocale),
                                    point,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Always Western digits (FR-011 of 001), like every other date label.
  static String _monthLabel(DateFormat format, SpendingTrendPoint point) =>
      NumeralParser.toWesternDigits(format.format(point.period.start));
}

/// One month's income/expense bar pair, bottom-aligned on a shared scale.
///
/// [textDirection] decides which bar sits on the reading-start side, so the
/// pair mirrors along with the rest of the chart. Bar geometry is the only
/// place amounts are treated as proportions; no displayed figure is derived
/// here.
class TrendBarsPainter extends CustomPainter {
  const TrendBarsPainter({
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
    required this.maxMinorUnits,
    required this.incomeColor,
    required this.expenseColor,
    required this.expenseFillColor,
    required this.textDirection,
    this.baselineColor,
  });

  final int incomeMinorUnits;
  final int expenseMinorUnits;

  /// The shared scale's top — the largest bar across every month.
  final int maxMinorUnits;

  final Color incomeColor;
  final Color expenseColor;
  final Color expenseFillColor;
  final Color? baselineColor;
  final TextDirection textDirection;

  static const double _maxBarWidth = 16;
  static const double _barGap = 4;

  /// The two bars' rectangles within [size]: centered as a pair, income on
  /// the reading-start side.
  ({Rect income, Rect expense}) barRects(Size size) {
    final barWidth = math.min(_maxBarWidth, (size.width - _barGap) / 2 * 0.8);
    final pairLeft = (size.width - (barWidth * 2 + _barGap)) / 2;
    final startLeft = pairLeft;
    final endLeft = pairLeft + barWidth + _barGap;
    final isRtl = textDirection == TextDirection.rtl;

    Rect bar(double left, int minorUnits) {
      final ratio = maxMinorUnits <= 0 ? 0.0 : minorUnits / maxMinorUnits;
      final barHeight = size.height * ratio.clamp(0.0, 1.0);
      return Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight);
    }

    return (
      income: bar(isRtl ? endLeft : startLeft, incomeMinorUnits),
      expense: bar(isRtl ? startLeft : endLeft, expenseMinorUnits),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rects = barRects(size);
    const radius = Radius.circular(3);

    final baseline = baselineColor;
    if (baseline != null) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        Paint()
          ..color = baseline
          ..strokeWidth = 1,
      );
    }

    if (!rects.income.isEmpty) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rects.income,
          topLeft: radius,
          topRight: radius,
        ),
        Paint()..color = incomeColor,
      );
    }
    if (!rects.expense.isEmpty) {
      final expense = RRect.fromRectAndCorners(
        rects.expense,
        topLeft: radius,
        topRight: radius,
      );
      canvas
        ..drawRRect(expense, Paint()..color = expenseFillColor)
        ..drawRRect(
          expense.deflate(0.75),
          Paint()
            ..color = expenseColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
    }
  }

  @override
  bool shouldRepaint(TrendBarsPainter oldDelegate) =>
      oldDelegate.incomeMinorUnits != incomeMinorUnits ||
      oldDelegate.expenseMinorUnits != expenseMinorUnits ||
      oldDelegate.maxMinorUnits != maxMinorUnits ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor ||
      oldDelegate.expenseFillColor != expenseFillColor ||
      oldDelegate.baselineColor != baselineColor ||
      oldDelegate.textDirection != textDirection;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.label,
    required this.swatch,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Widget swatch;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Icon(icon, size: 14, color: color),
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
