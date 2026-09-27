import 'dart:async';

import 'package:fpdart/fpdart.dart';

/// 021: records every value of a `watch*` stream so a test can wait for the
/// emission it expects after a write (the streams debounce writes by 50 ms,
/// so a real-time wait is needed).
class StreamRecorder<T> {
  StreamRecorder(Stream<T> stream) {
    _subscription = stream.listen((value) {
      values.add(value);
      for (final waiter in [..._waiters]) {
        if (waiter.test(value)) {
          _waiters.remove(waiter);
          waiter.completer.complete(value);
        }
      }
    });
  }

  final values = <T>[];
  final _waiters = <_Waiter<T>>[];
  late final StreamSubscription<T> _subscription;

  T get last => values.last;

  /// The first value, recorded or future, satisfying [test].
  Future<T> waitFor(
    bool Function(T value) test, {
    Duration timeout = const Duration(seconds: 2),
  }) {
    for (final value in values) {
      if (test(value)) return Future.value(value);
    }
    final waiter = _Waiter<T>(test);
    _waiters.add(waiter);
    return waiter.completer.future.timeout(timeout);
  }

  /// The first value recorded **after** this call satisfying [test].
  Future<T> waitForNext(
    bool Function(T value) test, {
    Duration timeout = const Duration(seconds: 2),
  }) {
    final waiter = _Waiter<T>(test);
    _waiters.add(waiter);
    return waiter.completer.future.timeout(timeout);
  }

  /// Lets any pending debounced event arrive.
  static Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  Future<void> cancel() => _subscription.cancel();
}

class _Waiter<T> {
  _Waiter(this.test);

  final bool Function(T value) test;
  final completer = Completer<T>();
}

/// The right value of [result]; fails the test on a Left.
R rightOf<L, R>(Either<L, R> result) =>
    result.getOrElse((failure) => throw StateError('Expected Right: $failure'));
