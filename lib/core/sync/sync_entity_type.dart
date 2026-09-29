/// 021: every record type that syncs to the cloud (data-model.md §1).
///
/// [wire] is the `entity_type` string on the wire and in `sync_outbox`;
/// [rank] is the outbox `depends_on_rank`, which orders an upload so a
/// parent always reaches the server before its children.
enum SyncEntityType {
  person('person', 0),
  moneyTransaction('money_transaction', 1),
  transactionAudit('transaction_audit', 2),
  financeCategory('finance_category', 0),
  financeEntry('finance_entry', 1),
  exchangeRate('exchange_rate', 3),
  primaryCurrency('primary_currency', 3),
  conflictResolution('conflict_resolution', 2),
  // 022: the features merged from the 008-015 line.
  occasion('occasion', 0),
  budget('budget', 0),
  budgetAllocation('budget_allocation', 1),
  // 011 Savings Goals (migration 023).
  savingsGoal('savings_goal', 0),
  savingsContribution('savings_contribution', 1),
  savingsContributionAudit('savings_contribution_audit', 2);

  const SyncEntityType(this.wire, this.rank);

  /// The `entity_type` value used on the wire and in the local sync tables.
  final String wire;

  /// The outbox `depends_on_rank`: 0 = person, category, occasion, budget
  /// or savings goal, 1 = transaction, entry, budget allocation or savings
  /// contribution, 2 = audit (transaction or savings contribution) or
  /// conflict resolution, 3 = rate or primary currency.
  final int rank;

  /// Parses a [wire] value. Throws [ArgumentError] on an unknown value, so a
  /// corrupt or future entity type is never silently mis-applied.
  static SyncEntityType fromWire(String value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'Unknown sync entity type');
  }
}

/// 021 FR-006: the local SQL tables that never sync. Every table in
/// `AppDatabase.allTables` is either synced (a [SyncEntityType] with a
/// registered `SyncMapper`) or listed here. This is enforced by
/// `test/core/sync/table_classification_guard_test.dart`, so a table added
/// by a future feature fails that test until it is classified.
///
/// `conflict_resolutions` is not here: it syncs, as
/// [SyncEntityType.conflictResolution].
const Set<String> localOnlyTables = {
  // Device preferences and state.
  'app_settings',
  'onboarding_status',
  'notification_preferences',
  'notification_history',
  // Device files that are never uploaded: occasion photos (008 FR-017) and
  // scanned pages with their review state (009 FR-019). A transaction keeps
  // its `ocr_scan_id` as a plain, unresolved reference on other devices.
  'occasion_attachments',
  'ocr_scans',
  'candidate_entries',
  // The AI assistant (014): its provider, consent and conversation belong
  // to the device whose secure storage holds the API key.
  'ai_conversations',
  'ai_messages',
  'ai_settings',
  // The sync machinery itself (sync_tables.dart).
  'sync_outbox',
  'sync_record_meta',
  'sync_conflicts',
  'sync_state',
};
