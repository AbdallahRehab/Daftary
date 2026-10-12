import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/usecases/get_sms_capability.dart';
import '../../domain/usecases/undo_ignore.dart';
import '../../domain/usecases/watch_undo_list.dart';

/// The Ignored items screen's phases (ui-contract §3.8).
enum IgnoredImportsStatus { initial, loading, ready, empty, error }

/// Immutable state of [IgnoredImportsCubit]. Items carry only the six
/// fields kept after a decision (amount, currency, date, merchant or
/// counterparty, bank, kind); never message text.
class IgnoredImportsState extends Equatable {
  IgnoredImportsState({
    this.status = IgnoredImportsStatus.initial,
    List<PendingSmsImport> items = const [],
    this.now,
    this.scanAvailable = false,
    this.undoingId,
    this.restored = false,
    this.failure,
    this.undoFailure,
  }) : items = List.unmodifiable(items);

  final IgnoredImportsStatus status;

  /// Ignored and expired items decided in the last 30 days, newest first.
  final List<PendingSmsImport> items;

  /// When [items] was read, for "N days left".
  final DateTime? now;

  /// With bank-message scanning the Undo copy names Scan now; without it
  /// (iOS, macOS, an SMS-free build) the Scan clause is left out.
  final bool scanAvailable;

  /// The row whose Undo runs; its button is disabled.
  final String? undoingId;

  /// One-shot: an Undo succeeded; the page announces it and calls
  /// `consumeRestored`.
  final bool restored;

  /// The list could not be read.
  final Failure? failure;

  /// The last Undo failed; the item stays in the list.
  final Failure? undoFailure;

  /// Whole days until [item] leaves the Undo list (0 = less than a day).
  int? daysLeft(PendingSmsImport item) {
    final decided = item.decidedAt;
    final at = now;
    if (decided == null || at == null) return null;
    final left = decided
        .add(IgnoredImportsCubit.undoWindow)
        .difference(at)
        .inDays;
    return left < 0 ? 0 : left;
  }

  IgnoredImportsState copyWith({
    IgnoredImportsStatus? status,
    List<PendingSmsImport>? items,
    DateTime? now,
    bool? scanAvailable,
    String? undoingId,
    bool clearUndoingId = false,
    bool? restored,
    Failure? failure,
    bool clearFailure = false,
    Failure? undoFailure,
    bool clearUndoFailure = false,
  }) => IgnoredImportsState(
    status: status ?? this.status,
    items: items ?? this.items,
    now: now ?? this.now,
    scanAvailable: scanAvailable ?? this.scanAvailable,
    undoingId: clearUndoingId ? null : (undoingId ?? this.undoingId),
    restored: restored ?? this.restored,
    failure: clearFailure ? null : (failure ?? this.failure),
    undoFailure: clearUndoFailure ? null : (undoFailure ?? this.undoFailure),
  );

  @override
  List<Object?> get props => [
    status,
    items,
    now,
    scanAvailable,
    undoingId,
    restored,
    failure,
    undoFailure,
  ];

  /// Redacted: counts and codes only, never an item's content or id.
  @override
  String toString() =>
      'IgnoredImportsState(status: ${status.name}, items: ${items.length}, '
      'scanAvailable: $scanAvailable, undoing: ${undoingId != null}, '
      'restored: $restored, failure: ${failure.runtimeType}, '
      'undoFailure: ${undoFailure.runtimeType})';
}

/// The 30-day Undo list (T133, FR-067, FR-068, ui-contract §3.8). It
/// follows `WatchUndoList` and runs `UndoIgnore` on one row at a time. An
/// undone item is gone from the list; it comes back only when the user
/// scans, pastes or shares the message again (`needsRescan`), because its
/// original was purged when it was decided. Nothing here adds a record.
@injectable
class IgnoredImportsCubit extends Cubit<IgnoredImportsState> {
  IgnoredImportsCubit(this._watch, this._undo, this._capability, this._clock)
    : super(IgnoredImportsState());

  final WatchUndoList _watch;
  final UndoIgnore _undo;
  final GetSmsCapability _capability;
  final AppClock _clock;

  /// How long a decided item stays undoable (FR-067).
  static const Duration undoWindow = Duration(days: 30);

  StreamSubscription<void>? _subscription;

  Future<void> open() async {
    _cancelSubscription();
    emit(
      state.copyWith(status: IgnoredImportsStatus.loading, clearFailure: true),
    );
    final capability = await _capability();
    if (isClosed) return;
    emit(state.copyWith(scanAvailable: capability.available));
    final first = Completer<void>();
    _subscription = _watch().listen((result) {
      if (isClosed) return;
      emit(
        result.match(
          (failure) => state.copyWith(
            status: IgnoredImportsStatus.error,
            failure: failure,
          ),
          (items) => state.copyWith(
            status: items.isEmpty
                ? IgnoredImportsStatus.empty
                : IgnoredImportsStatus.ready,
            items: items,
            now: _clock.now(),
            clearFailure: true,
          ),
        ),
      );
      if (!first.isCompleted) first.complete();
    });
    return first.future;
  }

  Future<void> retry() => open();

  /// Undo one ignored or expired item (FR-068). Single-flight.
  Future<void> undo(String id) async {
    if (state.undoingId != null) return;
    emit(
      state.copyWith(undoingId: id, restored: false, clearUndoFailure: true),
    );
    final result = await _undo(id);
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(
          clearUndoingId: true,
          // Already gone (purged or undone elsewhere): the stream drops it.
          undoFailure:
              failure is ImportAlreadyDecidedFailure ||
                  failure is NotFoundFailure
              ? null
              : failure,
        ),
        (_) => state.copyWith(clearUndoingId: true, restored: true),
      ),
    );
  }

  void consumeRestored() => emit(state.copyWith(restored: false));

  void consumeUndoFailure() => emit(state.copyWith(clearUndoFailure: true));

  /// Not awaited: see `BankMessagesHomeCubit._cancelSubscription`.
  void _cancelSubscription() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
