import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/balance_queries.dart';

/// Direct `drift` access to `money_transactions` and
/// `transaction_audit_entries`. Idempotent insertion, soft-delete, and
/// audit-entry writes all live here; the balance/overview aggregates
/// delegate to the shared [BalanceQueries] extension (core/database) so
/// the formula is defined exactly once.
@injectable
class TransactionsDao {
  TransactionsDao(this._db);

  final db.AppDatabase _db;

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-020/SC-006), the unique-constraint violation
  /// is swallowed and the already-persisted row is returned instead of
  /// erroring.
  Future<db.MoneyTransaction> insertTransactionIdempotent(
    db.MoneyTransactionsCompanion companion,
  ) async {
    final idempotencyKey = companion.idempotencyKey.value;
    try {
      await _db.into(_db.moneyTransactions).insert(companion);
    } catch (_) {
      final existing = await getByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      rethrow;
    }
    return (await getByIdempotencyKey(idempotencyKey))!;
  }

  Future<db.MoneyTransaction?> getByIdempotencyKey(String key) => (_db.select(
    _db.moneyTransactions,
  )..where((t) => t.idempotencyKey.equals(key))).getSingleOrNull();

  Future<db.MoneyTransaction?> getById(String id) => (_db.select(
    _db.moneyTransactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Non-deleted rows for [personId], oldest first (FR-010).
  Future<List<db.MoneyTransaction>> getHistoryForPerson(String personId) {
    return (_db.select(_db.moneyTransactions)
          ..where((t) => t.personId.equals(personId) & t.deletedAt.isNull())
          ..orderBy([(t) => db.OrderingTerm(expression: t.date)]))
        .get();
  }

  Future<db.MoneyTransaction> updateTransaction(
    String id,
    db.MoneyTransactionsCompanion companion,
  ) async {
    await (_db.update(
      _db.moneyTransactions,
    )..where((t) => t.id.equals(id))).write(companion);
    return (await getById(id))!;
  }

  Future<void> softDelete(String id, DateTime deletedAt) {
    return (_db.update(
      _db.moneyTransactions,
    )..where((t) => t.id.equals(id))).write(
      db.MoneyTransactionsCompanion(
        deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> insertAuditEntry(
    db.TransactionAuditEntriesCompanion companion,
  ) => _db.into(_db.transactionAuditEntries).insert(companion);

  Future<int> netBalanceMinorUnits(String personId) =>
      _db.netBalanceMinorUnitsForPerson(personId);

  Future<Map<String, int>> netBalanceMinorUnitsForAllPeople() =>
      _db.netBalanceMinorUnitsForAllPeople();
}
