import 'package:injectable/injectable.dart';

import '../../domain/services/review_lease_registry.dart';

/// Which pending items are open in review, in memory (research Decision
/// 7): a re-parse skips a leased item so it never replaces fields under
/// the user. Leases are counted per item, so two open reviews of one item
/// keep it leased until both are released.
@LazySingleton(as: ReviewLeaseRegistry)
class InMemoryReviewLeaseRegistry implements ReviewLeaseRegistry {
  final Map<String, int> _counts = {};

  @override
  ReviewLease acquire(String importId) {
    _counts[importId] = (_counts[importId] ?? 0) + 1;
    return _Lease(importId, this);
  }

  @override
  bool isLeased(String importId) => _counts.containsKey(importId);

  void _release(String importId) {
    final count = (_counts[importId] ?? 0) - 1;
    if (count <= 0) {
      _counts.remove(importId);
    } else {
      _counts[importId] = count;
    }
  }
}

class _Lease implements ReviewLease {
  _Lease(this.importId, this._registry);

  @override
  final String importId;
  final InMemoryReviewLeaseRegistry _registry;
  bool _released = false;

  @override
  void release() {
    if (_released) return;
    _released = true;
    _registry._release(importId);
  }

  @override
  String toString() => '_Lease(released: $_released)';
}
