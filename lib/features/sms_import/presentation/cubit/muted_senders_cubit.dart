import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/usecases/unmute_sender.dart';
import '../../domain/usecases/watch_muted_senders.dart';

/// The Muted senders screen's phases (ui-contract §3.9).
enum MutedSendersStatus { initial, loading, ready, empty, error }

/// Immutable state of [MutedSendersCubit]: canonical sender ids only.
class MutedSendersState extends Equatable {
  MutedSendersState({
    this.status = MutedSendersStatus.initial,
    List<String> senders = const [],
    this.unmuting,
    this.unmuted = false,
    this.failure,
    this.unmuteFailure,
  }) : senders = List.unmodifiable(senders);

  final MutedSendersStatus status;

  /// Sorted, canonical upper-case sender ids.
  final List<String> senders;

  /// The sender whose Unmute runs.
  final String? unmuting;

  /// One-shot: an Unmute succeeded; the page announces it and calls
  /// `consumeUnmuted`.
  final bool unmuted;
  final Failure? failure;
  final Failure? unmuteFailure;

  MutedSendersState copyWith({
    MutedSendersStatus? status,
    List<String>? senders,
    String? unmuting,
    bool clearUnmuting = false,
    bool? unmuted,
    Failure? failure,
    bool clearFailure = false,
    Failure? unmuteFailure,
    bool clearUnmuteFailure = false,
  }) => MutedSendersState(
    status: status ?? this.status,
    senders: senders ?? this.senders,
    unmuting: clearUnmuting ? null : (unmuting ?? this.unmuting),
    unmuted: unmuted ?? this.unmuted,
    failure: clearFailure ? null : (failure ?? this.failure),
    unmuteFailure: clearUnmuteFailure
        ? null
        : (unmuteFailure ?? this.unmuteFailure),
  );

  @override
  List<Object?> get props => [
    status,
    senders,
    unmuting,
    unmuted,
    failure,
    unmuteFailure,
  ];

  /// Redacted: counts and codes only.
  @override
  String toString() =>
      'MutedSendersState(status: ${status.name}, senders: ${senders.length}, '
      'unmuting: ${unmuting != null}, unmuted: $unmuted, '
      'failure: ${failure.runtimeType}, '
      'unmuteFailure: ${unmuteFailure.runtimeType})';
}

/// Muted senders (T134, FR-056, FR-065, ui-contract §3.9): follows
/// `WatchMutedSenders` and unmutes one sender at a time. Unmuting
/// re-creates nothing; the sender's messages come back on the next scan.
@injectable
class MutedSendersCubit extends Cubit<MutedSendersState> {
  MutedSendersCubit(this._watch, this._unmute) : super(MutedSendersState());

  final WatchMutedSenders _watch;
  final UnmuteSender _unmute;

  StreamSubscription<void>? _subscription;

  Future<void> open() {
    _cancelSubscription();
    emit(
      state.copyWith(status: MutedSendersStatus.loading, clearFailure: true),
    );
    final first = Completer<void>();
    _subscription = _watch().listen((result) {
      if (isClosed) return;
      emit(
        result.match(
          (failure) => state.copyWith(
            status: MutedSendersStatus.error,
            failure: failure,
          ),
          (senders) => state.copyWith(
            status: senders.isEmpty
                ? MutedSendersStatus.empty
                : MutedSendersStatus.ready,
            senders: senders.toList()..sort(),
            clearFailure: true,
          ),
        ),
      );
      if (!first.isCompleted) first.complete();
    });
    return first.future;
  }

  Future<void> retry() => open();

  /// Unmutes [senderId]. Single-flight.
  Future<void> unmute(String senderId) async {
    if (state.unmuting != null) return;
    emit(
      state.copyWith(
        unmuting: senderId,
        unmuted: false,
        clearUnmuteFailure: true,
      ),
    );
    final result = await _unmute(senderId);
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(clearUnmuting: true, unmuteFailure: failure),
        (_) => state.copyWith(clearUnmuting: true, unmuted: true),
      ),
    );
  }

  void consumeUnmuted() => emit(state.copyWith(unmuted: false));

  void consumeUnmuteFailure() => emit(state.copyWith(clearUnmuteFailure: true));

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
