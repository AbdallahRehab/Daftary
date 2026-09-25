import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_overview.dart';
import 'overview_state.dart';

/// Loads the consolidated owed-to-me / I-owe overview (US4). Call [load]
/// again from any screen that just mutated a transaction so totals refresh
/// immediately (FR-014).
@injectable
class OverviewCubit extends Cubit<OverviewState> {
  OverviewCubit(this._getOverview) : super(const OverviewState());

  final GetOverview _getOverview;

  Future<void> load() async {
    emit(state.copyWith(status: OverviewStatus.loading));
    final result = await _getOverview();
    result.match(
      (failure) => emit(
        state.copyWith(status: OverviewStatus.failure, failure: failure),
      ),
      (summary) => emit(
        state.copyWith(status: OverviewStatus.success, summary: summary),
      ),
    );
  }
}
