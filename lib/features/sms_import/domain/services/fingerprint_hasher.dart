/// Keyed HMAC-SHA256 hashes (research Decision 6). Outputs are hex.
///
/// Inputs are computed once, from the unmasked values, before masking; the
/// hashes are immutable on the row.
abstract class FingerprintHasher {
  /// `HMAC(macKey, "fp1|" + normalizedBody)`, where the body is the output
  /// of the frozen `FingerprintNormalizer` v1 (FR-023).
  Future<String> fingerprint(String normalizedBody);

  /// `HMAC(macKey, "fp1|fee|" + normalizedBody)`: the fingerprint of a fee
  /// split from its parent message (FR-030a). Same input as [fingerprint].
  Future<String> feeFingerprint(String normalizedBody);

  /// `HMAC(macKey, "ref|" + bank + "|" + ref)`.
  Future<String> refHash(String bank, String ref);

  /// `HMAC(macKey, "ra|" + bank + "|" + ref + "|" + currency + "|" +
  /// amountMinor + "|" + direction)`.
  Future<String> refAmountHash({
    required String bank,
    required String ref,
    required String currency,
    required int amountMinor,
    required String direction,
  });
}
