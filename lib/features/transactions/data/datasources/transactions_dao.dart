import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/balance_queries.dart';
import '../../../../core/sync/local/sync_outbox.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../sync/money_transaction_sync_mapper.dart';
import '../sync/transaction_audit_sync_mapper.dart';

/// Direct `drift` access to `money_transactions` and
/// `transaction_audit_entries`. Idempotent insertion, soft-delete, and
/// audit-entry writes all live here; the balance/overview aggregates
/// delegate to the shared [BalanceQueries] extension (core/database) so
/// the formula is defined exactly once.
///
/// 021: every write records its change to the [SyncOutbox] inside a
/// `_db.transaction`; when the repository already runs one (edit or delete
/// plus its audit entry), these join it (plan.md §7).
@injectable
class TransactionsDao {
  TransactionsDao(
    this._db,
    this._outbox,
    this._transactionMapper,
    this._auditMapper,
  );

  final db.AppDatabase _db;
  final SyncOutbox _outbox;
  final MoneyTransactionSyncMapper _transactionMapper;
  final TransactionAuditSyncMapper _auditMapper;

  /// Queues an upsert of transaction [id]'s current row. Must run inside a
  /// transaction.
  Future<db.MoneyTransaction> _recordUpsert(String id) async {
    final row = (await getById(id))!;
    await _outbox.recordUpsert(
      SyncEntityType.moneyTransaction,
      id,
      _transactionMapper.toWire(row),
    );
    return row;
  }

  /// Inserts [companion]; if a row with the same `idempotency_key` already
  /// exists (unique index — FR-020/SC-006), the already-persisted row is
  /// returned instead of erroring, and nothing is queued for upload (the
  /// original insert already was).
  Future<db.MoneyTransaction> insertTransactionIdempotent(
    db.MoneyTransactionsCompanion companion,
  ) {
    final idempotencyKey = companion.idempotencyKey.value;
    return _db.transaction(() async {
      final existing = await getByIdempotencyKey(idempotencyKey);
      if (existing != null) return existing;
      await _db.into(_db.moneyTransactions).insert(companion);
      final inserted = (await getByIdempotencyKey(idempotencyKey))!;
      await _outbox.recordUpsert(
        SyncEntityType.moneyTransaction,
        inserted.id,
        _transactionMapper.toWire(inserted),
      );
      return inserted;
    });
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
  ) {
    return _db.transaction(() async {
      await (_db.update(
        _db.moneyTransactions,
      )..where((t) => t.id.equals(id))).write(companion);
      return _recordUpsert(id);
    });
  }

  /// A soft delete uploads as an upsert carrying `deleted_at`.
  Future<void> softDelete(String id, DateTime deletedAt) {
    return _db.transaction(() async {
      final updated =
          await (_db.update(
            _db.moneyTransactions,
          )..where((t) => t.id.equals(id))).write(
            db.MoneyTransactionsCompanion(
              deletedAt: db.Value(deletedAt.millisecondsSinceEpoch),
            ),
          );
      if (updated > 0) await _recordUpsert(id);
    });
  }

  Future<void> insertAuditEntry(db.TransactionAuditEntriesCompanion companion) {
    return _db.transaction(() async {
      await _db.into(_db.transactionAuditEntries).insert(companion);
      final id = companion.id.value;
      final row = await (_db.select(
        _db.transactionAuditEntries,
      )..where((a) => a.id.equals(id))).getSingle();
      await _outbox.recordUpsert(
        SyncEntityType.transactionAudit,
        id,
        _auditMapper.toWire(row),
      );
    });
  }

  /// Per-currency native nets for [personId] (currency code → minor
  /// units); conversion into the primary currency happens in the Domain.
  Future<Map<String, int>> netBalanceMinorUnitsByCurrency(String personId) =>
      _db.netBalanceMinorUnitsByCurrencyForPerson(personId);

  Future<Map<String, Map<String, int>>>
  netBalanceMinorUnitsByCurrencyForAllPeople() =>
      _db.netBalanceMinorUnitsByCurrencyForAllPeople();

  /// FR-010a: whether at least one `MoneyTransaction` row exists at all —
  /// including soft-deleted rows (`deletedAt IS NOT NULL`). A cheap
  /// `LIMIT 1` existence check, never a full list fetch.
  Future<bool> hasAnyTransaction() async {
    final row = await (_db.select(
      _db.moneyTransactions,
    )..limit(1)).getSingleOrNull();
    return row != null;
  }
}
