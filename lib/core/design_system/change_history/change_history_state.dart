import 'package:equatable/equatable.dart';

import '../../error/failure.dart';
import 'change_history_row.dart';

enum ChangeHistoryStatus { loading, success, empty, failure }

/// Immutable state of `ChangeHistoryCubit`.
class ChangeHistoryState extends Equatable {
  const ChangeHistoryState._(this.status, this.rows, this.failure);

  const ChangeHistoryState.loading()
    : this._(ChangeHistoryStatus.loading, const [], null);

  const ChangeHistoryState.empty()
    : this._(ChangeHistoryStatus.empty, const [], null);

  const ChangeHistoryState.success(List<ChangeHistoryRow> rows)
    : this._(ChangeHistoryStatus.success, rows, null);

  const ChangeHistoryState.failure(Failure failure)
    : this._(ChangeHistoryStatus.failure, const [], failure);

  final ChangeHistoryStatus status;
  final List<ChangeHistoryRow> rows;
  final Failure? failure;

  @override
  List<Object?> get props => [status, rows, failure];
}
