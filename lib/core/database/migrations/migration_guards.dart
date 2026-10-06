import '../app_database.dart';

/// Creates [table] unless it already exists, so a step interrupted after
/// creating some objects (but before the version advanced) can run again.
Future<void> ensureTable(
  AppDatabase db,
  Migrator m,
  TableInfo<Table, dynamic> table,
) async {
  if (!await _exists(db, 'table', table.actualTableName)) {
    await m.createTable(table);
  }
}

/// Creates [index] unless it already exists.
Future<void> ensureIndex(AppDatabase db, Migrator m, Index index) async {
  if (!await _exists(db, 'index', index.entityName)) {
    await m.createIndex(index);
  }
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
