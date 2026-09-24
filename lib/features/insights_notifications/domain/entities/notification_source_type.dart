/// Which external feature's data a notification is about. Discriminates the
/// [ThresholdBand] vocabulary that applies to a history row and the screen a
/// tapped notification opens (data-model.md).
enum NotificationSourceType {
  /// A budgeted expense category for one month (010 Household Budgets).
  budgetCategory,

  /// A savings goal (011 Savings Goals). Not month-scoped.
  savingsGoal,
}
