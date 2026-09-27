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
  conflictResolution('conflict_resolution', 2);

  const SyncEntityType(this.wire, this.rank);

  /// The `entity_type` value used on the wire and in the local sync tables.
  final String wire;

  /// The outbox `depends_on_rank`: 0 = person or category, 1 = transaction
  /// or entry, 2 = audit or conflict resolution, 3 = rate or primary
  /// currency.
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
