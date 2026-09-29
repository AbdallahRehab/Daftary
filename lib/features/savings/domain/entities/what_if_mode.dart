/// The two directions of a what-if exploration (FR-013/FR-014), and so what
/// applying its `WhatIfResult` changes (FR-015).
enum WhatIfMode {
  /// "What if I save X per month?" — X is the input, the completion date
  /// the answer. Applying sets only the goal's monthly contribution.
  monthlyContribution,

  /// "What do I need to save to finish by Y?" — Y is the input, the
  /// required monthly contribution the answer. Applying sets both the
  /// target date and that required contribution.
  targetDate,
}
