import '../app_database.dart';

/// The v11 -> v12 step (022):
///
/// - D2: the append-only `finance_entry_audits` table and its index, empty;
/// - B1 repair (research R7): `sync_state.b1_repull_done`, default false, so
///   the first sync of the fixed app re-pulls the server rows once.
///
/// Purely additive: no existing row is read, moved or rewritten. Every
/// addition is guarded by an existence check, because an older install that
/// reaches this step through the earlier `createTable` calls of the same
/// upgrade already gets today's shape of `sync_state`.
///
/// One transaction, so a failure leaves the file at v11 and the next open
/// retries cleanly.
Future<void> migrateToFinanceEntryAudits(AppDatabase db, Migrator m) {
  return db.transaction(() async {
    if (!await _exists(db, 'table', db.financeEntryAudits.actualTableName)) {
      await m.createTable(db.financeEntryAudits);
    }
    if (!await _exists(db, 'index', db.idxFinanceAuditEntryId.entityName)) {
      await m.createIndex(db.idxFinanceAuditEntryId);
    }
    final columns = await db
        .customSelect('PRAGMA table_info("${db.syncState.actualTableName}")')
        .get();
    if (!columns.any(
      (row) => row.read<String>('name') == db.syncState.b1RepullDone.name,
    )) {
      await m.addColumn(db.syncState, db.syncState.b1RepullDone);
    }
  });
}

Future<bool> _exists(AppDatabase db, String type, String name) async {
  final rows = await db
      .customSelect(
        'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?',
        variables: [Variable.withString(type), Variable.withString(name)],
      )
      .get();
  return rows.isNotEmpty;
}
