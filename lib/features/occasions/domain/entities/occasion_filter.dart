import 'package:equatable/equatable.dart';

/// The occasions list's optional narrowing criteria (FR-015). An all-`null`
/// filter is the default view: every active occasion, reverse-chronological.
class OccasionFilter extends Equatable {
  const OccasionFilter({this.nameQuery, this.type, this.fromDate, this.toDate});

  /// Case-insensitive substring match against `Occasion.name`.
  final String? nameQuery;

  /// Exact match against `Occasion.type` (standard or custom).
  final String? type;

  /// Inclusive lower bound on `Occasion.date`.
  final DateTime? fromDate;

  /// Inclusive upper bound on `Occasion.date`.
  final DateTime? toDate;

  bool get isEmpty =>
      (nameQuery == null || nameQuery!.trim().isEmpty) &&
      type == null &&
      fromDate == null &&
      toDate == null;

  OccasionFilter copyWith({
    String? nameQuery,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearNameQuery = false,
    bool clearType = false,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) => OccasionFilter(
    nameQuery: clearNameQuery ? null : (nameQuery ?? this.nameQuery),
    type: clearType ? null : (type ?? this.type),
    fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
    toDate: clearToDate ? null : (toDate ?? this.toDate),
  );

  @override
  List<Object?> get props => [nameQuery, type, fromDate, toDate];
}
