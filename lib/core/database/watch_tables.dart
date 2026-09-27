import 'dart:async';

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
