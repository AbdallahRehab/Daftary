import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The local table each synced type lives in. The switch is exhaustive, so
/// a new [SyncEntityType] does not compile here until it names its table.
TableInfo<Table, Object?> _tableOf(AppDatabase db, SyncEntityType type) =>
    switch (type) {
      SyncEntityType.person => db.people,
      SyncEntityType.moneyTransaction => db.moneyTransactions,
      SyncEntityType.transactionAudit => db.transactionAuditEntries,
      SyncEntityType.financeCategory => db.financeCategories,
      SyncEntityType.financeEntry => db.financeEntries,
      SyncEntityType.exchangeRate => db.exchangeRates,
      SyncEntityType.primaryCurrency => db.primaryCurrencySettings,
      SyncEntityType.conflictResolution => db.conflictResolutions,
      SyncEntityType.occasion => db.occasions,
      SyncEntityType.budget => db.budgets,
      SyncEntityType.budgetAllocation => db.budgetCategoryAllocations,
      SyncEntityType.savingsGoal => db.savingsGoals,
      SyncEntityType.savingsContribution => db.savingsContributions,
      SyncEntityType.savingsContributionAudit => db.savingsContributionAudits,
    };

/// Whether [mapper] maps the rows of [table] (its row type is the table's
/// data class). [D] is inferred from the static type of [table].
bool _mapsRowsOf<D>(TableInfo<Table, D> table, SyncMapper<Object?> mapper) =>
    mapper is SyncMapper<D>;

/// 021 T092 (spec FR-006): every local table is classified as either
/// synced or local-only, so a table added by a future feature fails here
/// until someone decides whether it syncs.
void main() {
  late AppDatabase db;
  late SyncMapperRegistry registry;

  setUp(() {
    // The registry exactly as the app assembles it (register_module.dart).
    configureDependencies();
    registry = getIt<SyncMapperRegistry>();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  /// SQL name of every table with a registered mapper.
  Set<String> syncedTables() => {
    for (final type in registry.types) _tableOf(db, type).actualTableName,
  };

  test('each synced type maps the table it is classified under', () {
    // Guards the switch above against a wrong table, per row type.
    final checks = <SyncEntityType, bool>{
      SyncEntityType.person: _mapsRowsOf(
        db.people,
        registry.mapperFor(SyncEntityType.person),
      ),
      SyncEntityType.moneyTransaction: _mapsRowsOf(
        db.moneyTransactions,
        registry.mapperFor(SyncEntityType.moneyTransaction),
      ),
      SyncEntityType.transactionAudit: _mapsRowsOf(
        db.transactionAuditEntries,
        registry.mapperFor(SyncEntityType.transactionAudit),
      ),
      SyncEntityType.financeCategory: _mapsRowsOf(
        db.financeCategories,
        registry.mapperFor(SyncEntityType.financeCategory),
      ),
      SyncEntityType.financeEntry: _mapsRowsOf(
        db.financeEntries,
        registry.mapperFor(SyncEntityType.financeEntry),
      ),
      SyncEntityType.exchangeRate: _mapsRowsOf(
        db.exchangeRates,
        registry.mapperFor(SyncEntityType.exchangeRate),
      ),
      SyncEntityType.primaryCurrency: _mapsRowsOf(
        db.primaryCurrencySettings,
        registry.mapperFor(SyncEntityType.primaryCurrency),
      ),
      SyncEntityType.conflictResolution: _mapsRowsOf(
        db.conflictResolutions,
        registry.mapperFor(SyncEntityType.conflictResolution),
      ),
      SyncEntityType.occasion: _mapsRowsOf(
        db.occasions,
        registry.mapperFor(SyncEntityType.occasion),
      ),
      SyncEntityType.budget: _mapsRowsOf(
        db.budgets,
        registry.mapperFor(SyncEntityType.budget),
      ),
      SyncEntityType.budgetAllocation: _mapsRowsOf(
        db.budgetCategoryAllocations,
        registry.mapperFor(SyncEntityType.budgetAllocation),
      ),
      SyncEntityType.savingsGoal: _mapsRowsOf(
        db.savingsGoals,
        registry.mapperFor(SyncEntityType.savingsGoal),
      ),
      SyncEntityType.savingsContribution: _mapsRowsOf(
        db.savingsContributions,
        registry.mapperFor(SyncEntityType.savingsContribution),
      ),
      SyncEntityType.savingsContributionAudit: _mapsRowsOf(
        db.savingsContributionAudits,
        registry.mapperFor(SyncEntityType.savingsContributionAudit),
      ),
    };
    expect(checks.keys.toSet(), SyncEntityType.values.toSet());
    for (final MapEntry(key: type, value: maps) in checks.entries) {
      expect(maps, isTrue, reason: '${type.wire} mapper vs its table');
    }
  });

  test('every table is synced or local-only, and never both', () {
    final synced = syncedTables();
    final unclassified = <String>[];
    final both = <String>[];
    for (final table in db.allTables) {
      final name = table.actualTableName;
      final isSynced = synced.contains(name);
      final isLocal = localOnlyTables.contains(name);
      if (!isSynced && !isLocal) unclassified.add(name);
      if (isSynced && isLocal) both.add(name);
    }
    expect(
      unclassified,
      isEmpty,
      reason:
          'Classify each new table (spec FR-006): register a SyncMapper for '
          'it, or add it to localOnlyTables in sync_entity_type.dart.',
    );
    expect(both, isEmpty, reason: 'A table cannot be both synced and local');
  });

  test('both lists name only tables that exist', () {
    final existing = {for (final t in db.allTables) t.actualTableName};
    expect(localOnlyTables.difference(existing), isEmpty);
    expect(syncedTables().difference(existing), isEmpty);
  });

  test('the local-only list is the device settings, the device-file and AI '
      'tables, and the sync tables', () {
    expect(localOnlyTables, {
      'app_settings',
      'onboarding_status',
      'notification_preferences',
      'notification_history',
      'occasion_attachments',
      'ocr_scans',
      'candidate_entries',
      'ai_conversations',
      'ai_messages',
      'ai_settings',
      'sync_outbox',
      'sync_record_meta',
      'sync_conflicts',
      'sync_state',
    });
    expect(syncedTables(), contains('conflict_resolutions'));
  });
}
