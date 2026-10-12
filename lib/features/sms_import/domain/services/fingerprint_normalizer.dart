/// The frozen v1 normalization of a message body for its fingerprint
/// (FR-023, parser-contract §3).
///
/// Steps 1-3 only: bidi and zero-width removal, whitespace collapse, digit
/// normalization. No letter folding, no lower-casing. It never changes with
/// parser rules; a change needs a new prefix (`fp2|`) and a migration.
abstract class FingerprintNormalizer {
  String normalize(String body);
}
