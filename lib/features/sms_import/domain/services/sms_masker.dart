/// Masks long digit runs and mobile numbers in the original text before it
/// is sealed (FR-031a, parser-contract §3). Pure.
abstract class SmsMasker {
  /// Digit groups of at least [threshold] digits keep only their last four;
  /// Egyptian mobile numbers keep only their last four. Grouped amounts and
  /// already-masked tokens are untouched.
  String mask(String original, {int threshold = 12});
}
