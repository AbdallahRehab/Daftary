/// Marks pending items that are open in review, so a re-parse never
/// replaces fields under the user (research Decision 7). In memory.
abstract class ReviewLeaseRegistry {
  ReviewLease acquire(String importId);

  bool isLeased(String importId);
}

/// One open review of one pending item.
abstract class ReviewLease {
  String get importId;

  /// Idempotent.
  void release();
}
