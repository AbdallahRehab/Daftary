import 'app_database.dart';

/// Shared net-balance aggregation over `money_transactions`, reused by both
/// the `people` (status filtering) and `transactions` (balance/overview)
/// features — a genuine cross-feature concern per constitution Principle II.
/// Formula: `SUM(given) - SUM(received)` over non-deleted rows (FR-008).
/// Positive ⇒ they owe you, negative ⇒ you owe them, zero ⇒ settled.
///
/// The aggregates additionally skip occasion contributions flagged as
/// non-counting (008 FR-018): condolence money is a social gesture, not a
/// reciprocal debt, so recording it must never make someone look like they
/// owe you. The flag is stored per row, so the predicate is a pure filter —
/// every other row is summed by the identical 001 formula, which is the
/// 008 FR-023 no-regression guarantee.
extension BalanceQueries on AppDatabase {
  Future<int> netBalanceMinorUnitsForPerson(String personId) async {
    final result = await customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN direction = 'given' THEN amount_minor_units ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN direction = 'received' THEN amount_minor_units ELSE 0 END), 0)
        AS net
      FROM money_transactions
      WHERE person_id = ? AND deleted_at IS NULL
        AND (kind != 'occasionContribution' OR counts_toward_balance = 1)
      ''',
      variables: [Variable<String>(personId)],
      readsFrom: {moneyTransactions},
    ).getSingle();
    return result.read<int>('net');
  }

  /// Net balance for every person with at least one non-deleted
  /// transaction, keyed by person id. A person absent from this map has a
  /// zero balance (no matching rows to aggregate).
  Future<Map<String, int>> netBalanceMinorUnitsForAllPeople() async {
    final rows = await customSelect(
      '''
      SELECT
        person_id,
        COALESCE(SUM(CASE WHEN direction = 'given' THEN amount_minor_units ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN direction = 'received' THEN amount_minor_units ELSE 0 END), 0)
        AS net
      FROM money_transactions
      WHERE deleted_at IS NULL
        AND (kind != 'occasionContribution' OR counts_toward_balance = 1)
      GROUP BY person_id
      ''',
      readsFrom: {moneyTransactions},
    ).get();
    return {
      for (final row in rows)
        row.read<String>('person_id'): row.read<int>('net'),
    };
  }

  /// Most-recent activity (edit time if edited, else creation time) per
  /// person, in epoch millis, over non-deleted rows — used to order the
  /// overview's grouped lists most-recent-first.
  Future<Map<String, int>> lastActivityMillisForAllPeople() async {
    final rows = await customSelect(
      '''
      SELECT person_id, MAX(COALESCE(edited_at, created_at)) AS last_activity
      FROM money_transactions
      WHERE deleted_at IS NULL
      GROUP BY person_id
      ''',
      readsFrom: {moneyTransactions},
    ).get();
    return {
      for (final row in rows)
        row.read<String>('person_id'): row.read<int>('last_activity'),
    };
  }
}
