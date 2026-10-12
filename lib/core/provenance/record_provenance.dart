/// How a saved record arrived, as one value (023 data-model §3.6, analysis
/// M8).
///
/// `MoneyTransaction.source` is the legacy capture method (`manual` covers
/// both typed and SMS-confirmed rows, FR-086) and `importSource` is the SMS
/// origin. Code that needs "how did this record arrive" reads the derived
/// `MoneyTransaction.provenance` getter, which combines the two into this
/// enum, and never tests `source == manual` alone.
enum RecordProvenance {
  /// Typed in by the user.
  manual,

  /// Confirmed from a paper scan (009).
  ocr,

  /// Confirmed from a bank message (023).
  sms,
}
