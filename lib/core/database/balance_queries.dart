import 'app_database.dart';

/// Shared net-balance aggregation over `money_transactions`, reused by both
/// the `people` (status filtering) and `transactions` (balance/overview)
/// features — a genuine cross-feature concern per constitution Principle II.
/// Formula: `SUM(given) - SUM(received)` over non-deleted rows (FR-008).
/// Positive ⇒ they owe you, negative ⇒ you owe them, zero ⇒ settled.
///
/// 018: amounts in different currencies are never summed together here.
/// Every aggregate is grouped by `currency_code`, returning one native net
/// per currency; converting those into the primary currency is the job of
/// `CurrencyConverter` in the Domain layer (FR-008/FR-009/FR-017), which
/// never falls back to a 1:1 rate.
extension BalanceQueries on AppDatabase {
  /// Net balance for [personId] per currency code, e.g.
  /// `{'EGP': 150000, 'USD': -2000}`. A currency absent from the map has a
  /// zero net (no matching rows); the map is empty for a person with no
  /// non-deleted transactions.
  Future<Map<String, int>> netBalanceMinorUnitsByCurrencyForPerson(
    String personId,
  ) async {
    final rows = await customSelect(
      '''
      SELECT
        currency_code,
        COALESCE(SUM(CASE WHEN direction = 'given' THEN amount_minor_units ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN direction = 'received' THEN amount_minor_units ELSE 0 END), 0)
        AS net
      FROM money_transactions
      WHERE person_id = ? AND deleted_at IS NULL
      GROUP BY currency_code
      ORDER BY currency_code
      ''',
      variables: [Variable<String>(personId)],
      readsFrom: {moneyTransactions},
    ).get();
    return {
      for (final row in rows)
        row.read<String>('currency_code'): row.read<int>('net'),
    };
  }

  /// Per-currency net balance for every person with at least one
  /// non-deleted transaction, keyed by person id then currency code. A
  /// person absent from this map has a zero balance (no matching rows to
  /// aggregate).
  Future<Map<String, Map<String, int>>>
  netBalanceMinorUnitsByCurrencyForAllPeople() async {
    final rows = await customSelect(
      '''
      SELECT
        person_id,
        currency_code,
        COALESCE(SUM(CASE WHEN direction = 'given' THEN amount_minor_units ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN direction = 'received' THEN amount_minor_units ELSE 0 END), 0)
        AS net
      FROM money_transactions
      WHERE deleted_at IS NULL
      GROUP BY person_id, currency_code
      ORDER BY person_id, currency_code
      ''',
      readsFrom: {moneyTransactions},
    ).get();
    final result = <String, Map<String, int>>{};
    for (final row in rows) {
      result.putIfAbsent(row.read<String>('person_id'), () => {})[row
          .read<String>('currency_code')] = row.read<int>(
        'net',
      );
    }
    return result;
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
