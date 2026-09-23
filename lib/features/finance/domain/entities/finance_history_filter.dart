import 'package:equatable/equatable.dart';

import 'finance_entry_type.dart';

/// An inclusive `[start, end]` span at day granularity — the unit every
/// period query is expressed in (research.md Decision 6). Both bounds are
/// normalized to date-only so a range built from `DateTime.now()` never
/// excludes entries recorded later the same day.
class DateRange extends Equatable {
  DateRange({required DateTime start, required DateTime end})
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day);

  /// First day of [reference]'s month through [reference] itself.
  factory DateRange.thisMonth([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return DateRange(start: DateTime(now.year, now.month, 1), end: now);
  }

  /// The full previous calendar month relative to [reference].
  factory DateRange.lastMonth([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final lastOfPreviousMonth = firstOfThisMonth.subtract(
      const Duration(days: 1),
    );
    return DateRange(
      start: DateTime(lastOfPreviousMonth.year, lastOfPreviousMonth.month, 1),
      end: lastOfPreviousMonth,
    );
  }

  final DateTime start;
  final DateTime end;

  int get startMillis => start.millisecondsSinceEpoch;

  /// The `end` day's last millisecond, so a `BETWEEN` bound includes every
  /// entry on the closing date rather than only ones stamped at midnight.
  int get endMillis =>
      DateTime(end.year, end.month, end.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;

  bool contains(DateTime date) {
    final dayMillis = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;
    return dayMillis >= startMillis && dayMillis <= endMillis;
  }

  @override
  List<Object?> get props => [start, end];
}

/// Narrows a history query by type, category, and/or date range (FR-012/
/// FR-013). Every field is optional — an all-`null` filter (or no filter at
/// all) means "everything that isn't soft-deleted".
class FinanceHistoryFilter extends Equatable {
  const FinanceHistoryFilter({this.type, this.categoryId, this.dateRange});

  final FinanceEntryType? type;
  final String? categoryId;
  final DateRange? dateRange;

  bool get isEmpty => type == null && categoryId == null && dateRange == null;
  bool get isNotEmpty => !isEmpty;

  FinanceHistoryFilter copyWith({
    FinanceEntryType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategoryId = false,
    DateRange? dateRange,
    bool clearDateRange = false,
  }) {
    return FinanceHistoryFilter(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }

  @override
  List<Object?> get props => [type, categoryId, dateRange];
}
