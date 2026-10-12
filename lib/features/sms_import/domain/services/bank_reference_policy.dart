/// Whether a bank's reference IDs are unique per transaction (FR-059b), a
/// property of its rule set. When they are not, the exact reference tier
/// also needs a date within one day; a reference alone never collapses two
/// messages.
abstract class BankReferencePolicy {
  /// `false` for the generic profile and for an unknown bank.
  bool refIsUnique(String bankId);
}
