/// Whether a [FinanceEntry] (or the [Category] it belongs to) represents
/// money coming in or money going out.
///
/// A single shared enum deliberately serves both entities (data-model.md):
/// an entry's type must always equal its category's, and giving each its own
/// two-value enum would only create a conversion point where they could
/// silently drift apart.
enum FinanceEntryType { income, expense }

/// The same two values, named for the [Category] side of the relationship.
/// An alias, not a second enum — see [FinanceEntryType].
typedef CategoryType = FinanceEntryType;

extension FinanceEntryTypeDb on FinanceEntryType {
  /// The `type` text column's stored value.
  String get dbValue => switch (this) {
    FinanceEntryType.income => 'income',
    FinanceEntryType.expense => 'expense',
  };
}

/// Parses a stored `type` column value. Throws [StateError] on an unknown
/// value rather than defaulting to one of the two — a corrupt row must not
/// quietly become an expense.
FinanceEntryType financeEntryTypeFromDb(String value) => switch (value) {
  'income' => FinanceEntryType.income,
  'expense' => FinanceEntryType.expense,
  _ => throw StateError('Unknown finance entry type: $value'),
};
