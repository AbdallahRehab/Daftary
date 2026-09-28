import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/occasion.dart';

enum ArchivedOccasionsStatus { loading, success, failure }

/// Immutable state for [ArchivedOccasionsCubit] (constitution Principle IV),
/// mirroring `ArchivedPeopleState`.
class ArchivedOccasionsState extends Equatable {
  const ArchivedOccasionsState({
    this.status = ArchivedOccasionsStatus.loading,
    this.occasions = const [],
    this.failure,
    this.processingOccasionId,
  });

  final ArchivedOccasionsStatus status;
  final List<Occasion> occasions;
  final Failure? failure;

  /// Same re-entrancy guard as `ArchivedPeopleState.processingPersonId`,
  /// applied to `restore()`.
  final String? processingOccasionId;

  bool get isLoading => status == ArchivedOccasionsStatus.loading;
  bool get isEmpty =>
      status == ArchivedOccasionsStatus.success && occasions.isEmpty;

  ArchivedOccasionsState copyWith({
    ArchivedOccasionsStatus? status,
    List<Occasion>? occasions,
    Failure? failure,
    bool clearFailure = false,
    String? processingOccasionId,
    bool clearProcessingOccasionId = false,
  }) {
    return ArchivedOccasionsState(
      status: status ?? this.status,
      occasions: occasions ?? this.occasions,
      failure: clearFailure ? null : (failure ?? this.failure),
      processingOccasionId: clearProcessingOccasionId
          ? null
          : (processingOccasionId ?? this.processingOccasionId),
    );
  }

  @override
  List<Object?> get props => [status, occasions, failure, processingOccasionId];
}
