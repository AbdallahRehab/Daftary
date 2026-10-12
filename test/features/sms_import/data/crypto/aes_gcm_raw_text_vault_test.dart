import 'dart:convert';
import 'dart:typed_data';

import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/sms_crypto_exception.dart';
import 'package:daftary/features/sms_import/domain/services/sms_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// A key store that hands out fixed key bytes, or throws like a lost key.
class _FixedKeyStore implements SmsKeyStore {
  _FixedKeyStore(this.key);

  Uint8List key;
  bool throwOnAccess = false;

  @override
  Future<Uint8List> encKey() async {
    if (throwOnAccess) {
      throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
    }
    return Uint8List.fromList(key);
  }

  @override
  Future<Uint8List> macKey() => throw UnimplementedError();

  @override
  Future<void> purge() async {}
}

Uint8List _unhex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// 023 T040 (written before the implementation): AES-256-GCM sealing of the
/// masked original, blob `0x01 | nonce(12) | ciphertext | tag(16)`, AAD = the
/// pending id (research Decision 6). Every message here is synthetic.
void main() {
  final key = Uint8List.fromList(List.generate(32, (i) => i));
  final nonce = Uint8List.fromList(List.generate(12, (i) => 0xa0 + i));
  const pendingId = '3f2c9a1e-0000-4000-8000-000000000001';
  const message = 'خصم 1,500.00 EGP بطاقة ****1234 CARREFOUR';

  late _FixedKeyStore keys;
  setUp(() => keys = _FixedKeyStore(Uint8List.fromList(key)));

  AesGcmRawTextVault fixedNonceVault() => AesGcmRawTextVault(
    keys,
    nonceForTesting: () => Uint8List.fromList(nonce),
  );

  group('round trip', () {
    test(
      'seal then open returns the exact text (Arabic, English, emoji)',
      () async {
        final vault = AesGcmRawTextVault(keys);
        for (final text in [
          message,
          'Purchase EGP 250.00 card **5678 at SHOP',
          'تم تحويل ٢٥٠ جنيه 🙂',
          '',
        ]) {
          final blob = await vault.seal(text, aad: pendingId);
          expect(await vault.open(blob, aad: pendingId), text);
        }
      },
    );

    test('the blob is 0x01 | nonce(12) | ciphertext | tag(16)', () async {
      final blob = await fixedNonceVault().seal(message, aad: pendingId);
      expect(blob.first, 0x01);
      expect(blob.sublist(1, 13), nonce);
      expect(blob.length, 1 + 12 + utf8.encode(message).length + 16);
      expect(AesGcmRawTextVault.formatVersion, 0x01);
      expect(AesGcmRawTextVault.nonceLength, 12);
      expect(AesGcmRawTextVault.tagLength, 16);
    });

    test('the ciphertext does not contain the plaintext bytes', () async {
      final blob = await AesGcmRawTextVault(keys).seal(message, aad: pendingId);
      expect(_hex(blob), isNot(contains(_hex(utf8.encode('CARREFOUR')))));
    });

    test('a fresh random nonce per seal', () async {
      final vault = AesGcmRawTextVault(keys);
      final nonces = <String>{};
      for (var i = 0; i < 50; i++) {
        final blob = await vault.seal(message, aad: pendingId);
        nonces.add(_hex(blob.sublist(1, 13)));
      }
      expect(nonces, hasLength(50));
    });
  });

  group('fixed vectors', () {
    test('matches an independent AES-GCM implementation (CryptoKit) for a '
        'fixed key, nonce, text and AAD', () async {
      // Produced with Apple CryptoKit `AES.GCM.seal` over the same key
      // (0x00..0x1f), nonce (0xa0..0xab), UTF-8 text and UTF-8 AAD, then
      // framed as 0x01 | nonce | ct | tag.
      const golden =
          '01a0a1a2a3a4a5a6a7a8a9aaab3eb6a4989c4e228e4e50b7e3294af0fe35eb0930'
          '4a1f9adb44a9ff04a702552bf85c6dce9d11671d1cdd569a4c3cccac15030d0e18'
          'f4b25f3506edd48821d2f50a';
      final blob = await fixedNonceVault().seal(message, aad: pendingId);
      expect(_hex(blob), golden);
      expect(
        await AesGcmRawTextVault(keys).open(_unhex(golden), aad: pendingId),
        message,
      );
    });

    test('the AES-256-GCM primitive matches the GCM spec test case 16', () {
      // McGrew & Viega, "The Galois/Counter Mode of Operation", test case
      // 16 (256-bit key, 96-bit IV, 20-byte AAD, 60-byte plaintext).
      final out = AesGcmRawTextVault.gcmForTesting(
        encrypt: true,
        key: _unhex(
          'feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308',
        ),
        nonce: _unhex('cafebabefacedbaddecaf888'),
        aad: _unhex('feedfacedeadbeeffeedfacedeadbeefabaddad2'),
        input: _unhex(
          'd9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72'
          '1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39',
        ),
      );
      expect(
        _hex(out),
        '522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa'
        '8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662'
        '76fc6ece0f4e1768cddf8853bb2d551b',
      );
    });
  });

  group('unreadable (null, never a throw)', () {
    late Uint8List blob;
    setUp(() async {
      blob = await fixedNonceVault().seal(message, aad: pendingId);
    });

    Uint8List flipped(int index) =>
        Uint8List.fromList(blob)..[index] = blob[index] ^ 0x01;

    test('a tampered ciphertext byte', () async {
      expect(await fixedNonceVault().open(flipped(13), aad: pendingId), isNull);
    });

    test('a tampered tag byte', () async {
      expect(
        await fixedNonceVault().open(flipped(blob.length - 1), aad: pendingId),
        isNull,
      );
    });

    test('a tampered nonce byte', () async {
      expect(await fixedNonceVault().open(flipped(1), aad: pendingId), isNull);
    });

    test('an AAD mismatch: a blob copied to another row never opens', () async {
      expect(
        await fixedNonceVault().open(
          blob,
          aad: '3f2c9a1e-0000-4000-8000-000000000002',
        ),
        isNull,
      );
      expect(await fixedNonceVault().open(blob, aad: ''), isNull);
    });

    test('a wrong version byte', () async {
      for (final version in [0x00, 0x02, 0xff]) {
        final other = Uint8List.fromList(blob)..[0] = version;
        expect(
          await fixedNonceVault().open(other, aad: pendingId),
          isNull,
          reason: 'version $version',
        );
      }
    });

    test('a truncated or empty blob', () async {
      for (final length in [0, 1, 13, 1 + 12 + 15, blob.length - 1]) {
        expect(
          await fixedNonceVault().open(
            Uint8List.sublistView(blob, 0, length),
            aad: pendingId,
          ),
          isNull,
          reason: 'length $length',
        );
      }
    });

    test('key loss: the key store throws', () async {
      keys.throwOnAccess = true;
      expect(await fixedNonceVault().open(blob, aad: pendingId), isNull);
    });

    test('key loss: a regenerated key cannot open old blobs', () async {
      keys.key = Uint8List.fromList(List.generate(32, (i) => 255 - i));
      expect(await fixedNonceVault().open(blob, aad: pendingId), isNull);
    });

    test('a key of the wrong length', () async {
      keys.key = Uint8List(16);
      expect(await fixedNonceVault().open(blob, aad: pendingId), isNull);
    });

    test('a plaintext that is not valid UTF-8', () async {
      final raw = AesGcmRawTextVault.gcmForTesting(
        encrypt: true,
        key: key,
        nonce: nonce,
        aad: Uint8List.fromList(utf8.encode(pendingId)),
        input: Uint8List.fromList([0xff, 0xfe, 0xfd]),
      );
      final bad = Uint8List.fromList([0x01, ...nonce, ...raw]);
      expect(await fixedNonceVault().open(bad, aad: pendingId), isNull);
    });
  });

  group('sealing failures', () {
    test('a lost key throws a content-free SmsCryptoException', () async {
      keys.throwOnAccess = true;
      Object? error;
      try {
        await AesGcmRawTextVault(keys).seal(message, aad: pendingId);
      } catch (e) {
        error = e;
      }
      expect(error, isA<SmsCryptoException>());
      expect(
        (error! as SmsCryptoException).error,
        SmsCryptoError.keyUnavailable,
      );
      expect(error.toString(), isNot(contains('CARREFOUR')));
      expect(error.toString(), isNot(contains('1234')));
      expect(error.toString(), isNot(contains(pendingId)));
    });

    test('a key store failure of any type maps to keyUnavailable', () async {
      final vault = AesGcmRawTextVault(_ThrowingKeyStore());
      await expectLater(
        vault.seal(message, aad: pendingId),
        throwsA(
          isA<SmsCryptoException>().having(
            (e) => e.error,
            'error',
            SmsCryptoError.keyUnavailable,
          ),
        ),
      );
    });

    test('a key of the wrong length refuses to seal', () async {
      keys.key = Uint8List(16);
      await expectLater(
        AesGcmRawTextVault(keys).seal(message, aad: pendingId),
        throwsA(isA<SmsCryptoException>()),
      );
    });

    test('an empty AAD is refused, so every blob is bound to a row', () async {
      await expectLater(
        AesGcmRawTextVault(keys).seal(message, aad: ''),
        throwsA(
          isA<SmsCryptoException>().having(
            (e) => e.error,
            'error',
            SmsCryptoError.sealFailed,
          ),
        ),
      );
    });

    test('a nonce hook of the wrong length refuses to seal', () async {
      await expectLater(
        AesGcmRawTextVault(
          keys,
          nonceForTesting: () => Uint8List(8),
        ).seal(message, aad: pendingId),
        throwsA(isA<SmsCryptoException>()),
      );
    });
  });
}

class _ThrowingKeyStore implements SmsKeyStore {
  @override
  Future<Uint8List> encKey() async => throw StateError('storage');

  @override
  Future<Uint8List> macKey() async => throw StateError('storage');

  @override
  Future<void> purge() async {}
}
