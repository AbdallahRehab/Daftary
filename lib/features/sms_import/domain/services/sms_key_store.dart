import 'dart:typed_data';

/// The encryption and MAC keys (`sms_import.enc_key.v1`,
/// `sms_import.mac_key.v1`) in secure storage.
///
/// Lazy, single-flight generation; written, then read back to verify.
/// A storage exception means "treat as purged" and is never logged.
abstract class SmsKeyStore {
  Future<Uint8List> encKey();

  Future<Uint8List> macKey();

  /// Deletes both keys (Delete all data).
  Future<void> purge();
}
