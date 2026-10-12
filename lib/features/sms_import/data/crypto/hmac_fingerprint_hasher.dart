import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/fingerprint_hasher.dart';
import '../../domain/services/sms_key_store.dart';

/// HMAC-SHA256 fingerprints and reference hashes with the per-install MAC
/// key (research Decision 6, `crypto` package). Outputs are lower-case hex.
///
/// - `fingerprint(input)` = `HMAC(mac, "fp1|" + input)`, where the input is
///   the output of the frozen `FingerprintNormalizerV1`, never
///   `SmsTextNormalizer` (FR-023);
/// - `feeFingerprint(input)` = `HMAC(mac, "fp1|fee|" + input)` (FR-030a);
/// - `refHash` = `HMAC(mac, "ref|" + bank + "|" + ref)`;
/// - `refAmountHash` = `HMAC(mac, "ra|" + bank + "|" + ref + "|" +
///   currency + "|" + amountMinor + "|" + direction)`.
///
/// Inputs are never logged or kept. A key-store failure propagates as the
/// key store's own content-free error.
@LazySingleton(as: FingerprintHasher)
class HmacFingerprintHasher implements FingerprintHasher {
  const HmacFingerprintHasher(this._keys);

  final SmsKeyStore _keys;

  static const String _fingerprintPrefix = 'fp1|';
  static const String _feePrefix = 'fp1|fee|';

  @override
  Future<String> fingerprint(String normalizedBody) =>
      _hmac('$_fingerprintPrefix$normalizedBody');

  @override
  Future<String> feeFingerprint(String normalizedBody) =>
      _hmac('$_feePrefix$normalizedBody');

  @override
  Future<String> refHash(String bank, String ref) => _hmac('ref|$bank|$ref');

  @override
  Future<String> refAmountHash({
    required String bank,
    required String ref,
    required String currency,
    required int amountMinor,
    required String direction,
  }) => _hmac('ra|$bank|$ref|$currency|$amountMinor|$direction');

  Future<String> _hmac(String input) async {
    final key = await _keys.macKey();
    return Hmac(sha256, key).convert(utf8.encode(input)).toString();
  }
}
