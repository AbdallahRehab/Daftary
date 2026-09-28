import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/occasion.dart';
import '../../domain/entities/occasion_filter.dart';

enum OccasionsListStatus { loading, success, failure }

/// Immutable state for [OccasionsListCubit] (constitution Principle IV).
class OccasionsListState extends Equatable {
  const OccasionsListState({
    this.status = OccasionsListStatus.loading,
    this.occasions = const [],
    this.filter = const OccasionFilter(),
    this.hasAnyOccasion = false,
    this.failure,
  });

  final OccasionsListStatus status;

  /// Reverse-chronological by date (FR-015) — the repository orders them, so
  /// this list is rendered as received and never re-sorted in the widget.
  final List<Occasion> occasions;
  final OccasionFilter filter;

  /// Whether the user has any active occasion at all, irrespective of
  /// [filter]. Kept separately because "you haven't created one yet" and
  /// "nothing matches this search" need different empty states, and an
  /// empty [occasions] alone cannot tell them apart (FR-020).
  final bool hasAnyOccasion;
  final Failure? failure;

  bool get isLoading => status == OccasionsListStatus.loading;

  /// The friendly first-run empty state with a "create your first occasion"
  /// action.
  bool get isEmptyOverall =>
      status == OccasionsListStatus.success && !hasAnyOccasion;

  /// The narrower "no occasions match your search or filters" state.
  bool get isEmptyForFilter =>
      status == OccasionsListStatus.success &&
      hasAnyOccasion &&
      occasions.isEmpty;

  OccasionsListState copyWith({
    OccasionsListStatus? status,
    List<Occasion>? occasions,
    OccasionFilter? filter,
    bool? hasAnyOccasion,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return OccasionsListState(
      status: status ?? this.status,
      occasions: occasions ?? this.occasions,
      filter: filter ?? this.filter,
      hasAnyOccasion: hasAnyOccasion ?? this.hasAnyOccasion,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    occasions,
    filter,
    hasAnyOccasion,
    failure,
  ];
}
