import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';
import '../utils/either_equality.dart';
import 'app_database.dart';

/// 021: the reactive-read primitive (research.md Decision 14). Repositories
/// re-run their existing `get*` query on every event, so a screen updates
/// from local data whenever a relevant table is written — by the user, or
/// by a download applied by the sync engine.
extension WatchTables on AppDatabase {
  /// Emits once immediately, then once per burst of writes to any of
  /// [tables]: writes closer together than [debounce] (50 ms by default)
  /// collapse into a single event. Built on drift's `tableUpdates`, with no
  /// rxdart.
  Stream<void> changesOf(
    Set<TableInfo<Table, Object?>> tables, {
    Duration debounce = const Duration(milliseconds: 50),
  }) {
    late final StreamController<void> controller;
    StreamSubscription<Set<TableUpdate>>? subscription;
    Timer? pending;

    controller = StreamController<void>(
      onListen: () {
        controller.add(null);
        subscription = tableUpdates(TableUpdateQuery.onAllTables(tables))
            .listen(
              (_) {
                pending?.cancel();
                pending = Timer(debounce, () {
                  if (!controller.isClosed) controller.add(null);
                });
              },
              onError: controller.addError,
              onDone: () {
                pending?.cancel();
                controller.close();
              },
            );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        pending?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}

/// 021: the repository-side `watch*` building block (contracts/
/// dart-interfaces.md §3).
extension WatchQuery on AppDatabase {
  /// Re-runs [query] — an existing `get*` read, unchanged — once now and
  /// again after every burst of writes to [tables], and emits only results
  /// that differ from the previous one. Results are compared deeply, so a
  /// re-read that returns an equal list or map is swallowed. Queries never
  /// overlap: a burst during a slow read waits for it.
  Stream<Either<Failure, T>> watchEither<T>(
    Set<TableInfo<Table, Object?>> tables,
    Future<Either<Failure, T>> Function() query, {
    Duration debounce = const Duration(milliseconds: 50),
  }) => changesOf(tables, debounce: debounce).reRead(query);
}

/// 021: turns a change signal (such as [WatchTables.changesOf]) into the
/// result of re-running a read.
extension ReReadOnChange on Stream<void> {
  /// Runs [query] on every event and emits its result when it differs from
  /// the previous one (compared deeply, see [sameResult]). Queries never
  /// overlap.
  Stream<Either<Failure, T>> reRead<T>(
    Future<Either<Failure, T>> Function() query,
  ) => asyncMap((_) => query()).distinct(sameResult);
}
