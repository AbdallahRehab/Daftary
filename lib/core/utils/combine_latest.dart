import 'dart:async';

/// 021: emits [combine] of the latest value of [a] and [b] once both have
/// emitted, and again whenever either emits (rxdart's `combineLatest2`,
/// without the dependency). Errors from either stream are forwarded; the
/// result closes once both sources are done. Cancelling the result cancels
/// both sources.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;
  var doneCount = 0;

  void emitIfReady() {
    if (hasA && hasB) controller.add(combine(latestA as A, latestB as B));
  }

  void onDone() {
    if (++doneCount == 2) controller.close();
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen(
        (value) {
          latestA = value;
          hasA = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: onDone,
      );
      subB = b.listen(
        (value) {
          latestB = value;
          hasB = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: onDone,
      );
    },
    onPause: () {
      subA?.pause();
      subB?.pause();
    },
    onResume: () {
      subA?.resume();
      subB?.resume();
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}
