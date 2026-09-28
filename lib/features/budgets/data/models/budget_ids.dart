/// 022: derived ids for budgets and their allocations. A month has at most
/// one active budget and a budget at most one allocation per category, so
/// deriving the id from that natural key lets two devices that plan the same
/// month (or category) offline converge on one synced row — last write wins
/// — instead of uploading two rows that could never both exist locally.
abstract final class BudgetIds {
  static String budget(String month) => 'budget_$month';

  static String allocation(String budgetId, String categoryId) =>
      'alloc_${budgetId}_$categoryId';
}
