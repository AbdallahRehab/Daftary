import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../error/failure.dart';
import 'change_history_row.dart';
import 'change_history_state.dart';

/// The one cubit behind every change-history sheet (022 C3). It is given
/// the history stream to show, so transactions, savings contributions and
/// finance entries share it. Read-only; the subscription is cancelled on
/// [close].
class ChangeHistoryCubit extends Cubit<ChangeHistoryState> {
  ChangeHistoryCubit(Stream<Either<Failure, List<ChangeHistoryRow>>> history)
    : super(const ChangeHistoryState.loading()) {
    _subscription = history.listen(
      (result) {
        if (isClosed) return;
        emit(
          result.match(
            ChangeHistoryState.failure,
            (rows) => rows.isEmpty
                ? const ChangeHistoryState.empty()
                : ChangeHistoryState.success(List.unmodifiable(rows)),
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(ChangeHistoryState.failure(UnknownFailure('$error')));
      },
    );
  }

  late final StreamSubscription<void> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
