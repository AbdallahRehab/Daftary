import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

/// 021: whether [a] and [b] carry the same side and deeply equal values —
/// what the `watch*` streams use to drop a re-read that changed nothing.
/// Lists and maps are compared element by element (entities are
/// `Equatable`, collections are not).
bool sameResult<T>(Either<Failure, T> a, Either<Failure, T> b) => a.match(
  (failureA) => b.match((failureB) => failureA == failureB, (_) => false),
  (valueA) => b.match((_) => false, (valueB) => _deepEquals(valueA, valueB)),
);

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}
