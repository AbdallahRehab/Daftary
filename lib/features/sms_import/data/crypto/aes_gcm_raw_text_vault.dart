import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

import '../../domain/services/raw_text_vault.dart';
import '../../domain/services/sms_key_store.dart';
import 'sms_crypto_exception.dart';

/// AES-256-GCM sealing of the masked original (research Decision 6).
///
/// Blob: `0x01 (format version) | nonce(12) | ciphertext | tag(16)`. The AAD
/// is the pending item's id (UTF-8), which binds a blob to its row, so a
/// blob copied to another row never opens. A fresh random nonce is drawn
/// for every seal.
///
/// [open] returns `null` for every unreadable case (missing or wrong key,
/// tag failure, wrong version, truncated blob, non-UTF-8 plaintext) and
/// never says which; the repository then purges the blob (FR-074a). Nothing
/// is logged, and no exception text from the cipher is ever kept.
///
/// The only importer of `pointycastle` (research Decision 15).
@LazySingleton(as: RawTextVault)
class AesGcmRawTextVault implements RawTextVault {
  /// [nonceForTesting] replaces the random nonce with a fixed one, for
  /// fixed-vector tests only. Production code never passes it.
  AesGcmRawTextVault(
    this._keys, {
    @ignoreParam Uint8List Function()? nonceForTesting,
  }) : _nonceSource = nonceForTesting;

  final SmsKeyStore _keys;
  final Uint8List Function()? _nonceSource;
  final Random _random = Random.secure();

  static const int formatVersion = 0x01;
  static const int nonceLength = 12;
  static const int tagLength = 16;
  static const int keyLength = 32;
  static const int _headerLength = 1 + nonceLength;

  @override
  Future<Uint8List> seal(String masked, {required String aad}) async {
    if (aad.isEmpty) {
      throw const SmsCryptoException(SmsCryptoError.sealFailed);
    }
    final key = await _encKeyOrThrow();
    final nonce = _nonceSource?.call() ?? _randomNonce();
    if (nonce.length != nonceLength) {
      throw const SmsCryptoException(SmsCryptoError.sealFailed);
    }
    final Uint8List sealed;
    try {
      sealed = _gcm(
        encrypt: true,
        key: key,
        nonce: nonce,
        aad: _utf8(aad),
        input: _utf8(masked),
      );
    } catch (_) {
      // The cipher's own message is dropped on purpose.
      throw const SmsCryptoException(SmsCryptoError.sealFailed);
    }
    return Uint8List(_headerLength + sealed.length)
      ..[0] = formatVersion
      ..setRange(1, _headerLength, nonce)
      ..setRange(_headerLength, _headerLength + sealed.length, sealed);
  }

  @override
  Future<String?> open(Uint8List blob, {required String aad}) async {
    if (blob.length < _headerLength + tagLength) return null;
    if (blob[0] != formatVersion) return null;
    final Uint8List key;
    try {
      key = await _keys.encKey();
    } catch (_) {
      return null;
    }
    if (key.length != keyLength) return null;
    try {
      final plain = _gcm(
        encrypt: false,
        key: key,
        nonce: Uint8List.sublistView(blob, 1, _headerLength),
        aad: _utf8(aad),
        input: Uint8List.sublistView(blob, _headerLength),
      );
      return utf8.decode(plain);
    } catch (_) {
      // Tag failure (InvalidCipherTextException) or malformed UTF-8: both
      // mean "unreadable", and neither reason is surfaced.
      return null;
    }
  }

  Future<Uint8List> _encKeyOrThrow() async {
    final Uint8List key;
    try {
      key = await _keys.encKey();
    } catch (_) {
      throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
    }
    if (key.length != keyLength) {
      throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
    }
    return key;
  }

  Uint8List _randomNonce() => Uint8List.fromList(
    List.generate(nonceLength, (_) => _random.nextInt(256)),
  );

  static Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

  /// The raw AES-GCM primitive (128-bit tag): ciphertext followed by the
  /// tag when encrypting, plaintext when decrypting. Throws
  /// [InvalidCipherTextException] on a tag mismatch.
  static Uint8List _gcm({
    required bool encrypt,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List input,
  }) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        encrypt,
        AEADParameters(KeyParameter(key), tagLength * 8, nonce, aad),
      );
    return cipher.process(input);
  }

  /// [_gcm] exposed for the published GCM test vectors.
  @visibleForTesting
  static Uint8List gcmForTesting({
    required bool encrypt,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List input,
  }) => _gcm(encrypt: encrypt, key: key, nonce: nonce, aad: aad, input: input);
}
