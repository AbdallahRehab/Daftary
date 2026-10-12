import 'dart:typed_data';

/// Seals the masked original with AES-GCM (research Decision 6).
///
/// Blob format: `0x01 | nonce(12) | ciphertext | tag(16)`; the AAD is the
/// pending item's id.
abstract class RawTextVault {
  Future<Uint8List> seal(String masked, {required String aad});

  /// `null` when the blob cannot be opened (wrong key, tag failure, bad
  /// format). Never throws for those cases and never reveals why.
  Future<String?> open(Uint8List blob, {required String aad});
}
