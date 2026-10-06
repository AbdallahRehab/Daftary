import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/change_history/change_history_cubit.dart';
import 'package:daftary/core/design_system/change_history/change_history_row.dart';
import 'package:daftary/core/design_system/change_history/change_history_state.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  final row = ChangeHistoryRow(label: 'Edited', timestamp: DateTime(2026));
  late StreamController<Either<Failure, List<ChangeHistoryRow>>> controller;

  setUp(() => controller = StreamController(sync: true));
  tearDown(() => controller.close());

  test('starts loading', () async {
    final cubit = ChangeHistoryCubit(controller.stream);
    expect(cubit.state, const ChangeHistoryState.loading());
    await cubit.close();
  });

  blocTest<ChangeHistoryCubit, ChangeHistoryState>(
    'rows -> success, then live update re-emits',
    build: () => ChangeHistoryCubit(controller.stream),
    act: (_) {
      controller.add(Right([row]));
      controller.add(Right([row, row]));
    },
    expect: () => [
      ChangeHistoryState.success([row]),
      ChangeHistoryState.success([row, row]),
    ],
  );

  blocTest<ChangeHistoryCubit, ChangeHistoryState>(
    'no rows -> empty',
    build: () => ChangeHistoryCubit(controller.stream),
    act: (_) => controller.add(const Right([])),
    expect: () => [const ChangeHistoryState.empty()],
  );

  blocTest<ChangeHistoryCubit, ChangeHistoryState>(
    'Left and stream errors -> failure; recovers on next value',
    build: () => ChangeHistoryCubit(controller.stream),
    act: (_) {
      controller.add(const Left(CacheFailure('x')));
      controller.add(Right([row]));
    },
    expect: () => [
      const ChangeHistoryState.failure(CacheFailure('x')),
      ChangeHistoryState.success([row]),
    ],
  );

  test('success rows are unmodifiable', () async {
    final cubit = ChangeHistoryCubit(controller.stream);
    controller.add(Right([row]));
    expect(() => cubit.state.rows.add(row), throwsUnsupportedError);
    await cubit.close();
  });

  test('close cancels the subscription', () async {
    final cubit = ChangeHistoryCubit(controller.stream);
    expect(controller.hasListener, isTrue);
    await cubit.close();
    expect(controller.hasListener, isFalse);
  });
}
