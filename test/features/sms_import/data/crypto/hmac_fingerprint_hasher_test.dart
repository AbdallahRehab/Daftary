import 'dart:typed_data';

import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

// 023 T041: HMAC-SHA256 fingerprints and reference hashes (research
// Decision 6). The vectors below were computed independently (Python
// `hmac`/`hashlib`) with the fake key store's MAC key (32 bytes of 0x02),
// so they pin the exact input layout of every hash.
void main() {
  late FakeSmsKeyStore keys;
  late HmacFingerprintHasher hasher;

  setUp(() {
    keys = FakeSmsKeyStore();
    hasher = HmacFingerprintHasher(keys);
  });

  group('known vectors', () {
    test('fingerprint = HMAC(mac, "fp1|" + input)', () async {
      expect(
        await hasher.fingerprint('Purchase EGP 125.50 at Example Cafe'),
        '67b0643e7fef871878027ca78ff8aaefab30054eb7832e52b62c866d0487b44c',
      );
      expect(
        await hasher.fingerprint(''),
        '9575eb7cabeb561679fb26facc0bd181e5a7a433ba381c13a2cae39d5933e83a',
      );
    });

    test('feeFingerprint = HMAC(mac, "fp1|fee|" + input)', () async {
      expect(
        await hasher.feeFingerprint('Purchase EGP 125.50 at Example Cafe'),
        '9b89c7abc4b48f5c72eef2feb3540dcc23db5e74f06ced67a2775cc7085b5f48',
      );
    });

    test('refHash = HMAC(mac, "ref|" + bank + "|" + ref)', () async {
      expect(
        await hasher.refHash('nbe', 'REF0001'),
        '9faa6e8bb01681e4380013f5ca8cc1440c20353148f07b2fce7a1c29ada72d68',
      );
    });

    test(
      'refAmountHash = HMAC(mac, "ra|bank|ref|currency|minor|dir")',
      () async {
        expect(
          await hasher.refAmountHash(
            bank: 'nbe',
            ref: 'REF0001',
            currency: 'EGP',
            amountMinor: 12550,
            direction: 'debit',
          ),
          '8bd9c5f388134c6fc41f423c5ecfb5867f2158bf11b4328c65152521a1d1bd3a',
        );
      },
    );

    test('UTF-8 input with another key', () async {
      final custom = HmacFingerprintHasher(
        _FixedMacKeyStore(Uint8List.fromList(List.generate(32, (i) => i))),
      );
      expect(
        await custom.fingerprint('تم خصم 150.00 جنيه'),
        '89cb31d64fc3d8f93cf676359f100ffc2babc88c78ea77811d43aba94dad6634',
      );
    });
  });

  group('properties', () {
    test('deterministic: same input, same output', () async {
      final a = await hasher.fingerprint('body');
      final b = await hasher.fingerprint('body');
      expect(a, b);
      expect(a, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('the fee fingerprint differs from the message fingerprint', () async {
      expect(
        await hasher.feeFingerprint('body'),
        isNot(await hasher.fingerprint('body')),
      );
    });

    test('independent of sender and received time: the body is the only '
        'input', () async {
      // Two inbox copies of one message from different senders and times
      // normalize to the same body, so they share a fingerprint.
      const normalizer = FingerprintNormalizerV1();
      final fromScan = normalizer.normalize(
        'Purchase EGP 125.50\nat Example Cafe',
      );
      final fromPaste = normalizer.normalize(
        '\u{200F}Purchase  EGP ١٢٥٫٥٠ at Example Cafe ',
      );
      expect(
        await hasher.fingerprint(fromScan),
        await hasher.fingerprint(fromPaste),
      );
    });

    test('a different key gives a different fingerprint', () async {
      final before = await hasher.fingerprint('body');
      await keys.purge();
      expect(await hasher.fingerprint('body'), isNot(before));
    });

    test('ref hashes depend on the bank', () async {
      expect(
        await hasher.refHash('nbe', 'R1'),
        isNot(await hasher.refHash('cib', 'R1')),
      );
    });

    test('a key-store failure propagates without content', () async {
      keys.throwOnAccess = true;
      await expectLater(
        hasher.fingerprint('Example Cafe 987654.32'),
        throwsA(
          predicate(
            (Object e) =>
                !e.toString().contains('987654') &&
                !e.toString().contains('Cafe'),
          ),
        ),
      );
    });
  });
}

class _FixedMacKeyStore extends FakeSmsKeyStore {
  _FixedMacKeyStore(this.key);

  final Uint8List key;

  @override
  Future<Uint8List> macKey() async => key;
}
