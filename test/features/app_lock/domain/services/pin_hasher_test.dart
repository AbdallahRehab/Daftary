import 'dart:convert';
import 'dart:io';

import 'package:daftary/features/app_lock/domain/entities/pin_credential.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

/// T009 — release-blocking correctness anchor for SC-008/Principle XII.
void main() {
  // Small iteration count so the suite stays fast; the KDF itself is
  // iteration-count agnostic (checked against an RFC vector below).
  final hasher = Pbkdf2PinHasher(iterations: 10);

  group('validate (FR-003)', () {
    for (final pin in ['0000', '12345', '987654']) {
      test(
        'accepts "$pin"',
        () => expect(() => hasher.validate(pin), returnsNormally),
      );
    }

    for (final pin in [
      '',
      '1',
      '123',
      '1234567',
      '12a4',
      'abcd',
      '12 34',
      ' 1234',
      '1234\n',
      '-123',
      '12.3',
      '١٢٣٤', // Arabic-Indic digits are not ASCII digits
    ]) {
      test('rejects ${jsonEncode(pin)}', () {
        expect(() => hasher.validate(pin), throwsArgumentError);
      });
    }

    test('the error never echoes the rejected value (FR-016)', () {
      try {
        hasher.validate('12a45');
        fail('expected ArgumentError');
      } on ArgumentError catch (e) {
        expect(e.toString(), isNot(contains('12a45')));
      }
    });

    test('hash() validates too', () {
      expect(() => hasher.hash('12'), throwsArgumentError);
    });
  });

  group('hash', () {
    test('records the configured iteration count and a 16-byte salt', () {
      final c = hasher.hash('1234');
      expect(c.iterations, 10);
      expect(base64Decode(c.salt), hasLength(Pbkdf2PinHasher.saltLength));
      expect(base64Decode(c.hash), hasLength(Pbkdf2PinHasher.keyLength));
    });

    test('never contains the raw PIN', () {
      final c = hasher.hash('482913');
      expect(c.hash, isNot(contains('482913')));
      expect(c.salt, isNot(contains('482913')));
      expect(c.toString(), isNot(contains('482913')));
      expect(c.toString(), isNot(contains(c.hash)));
    });

    test('two hashes of the same PIN use different salts and hashes', () {
      final a = hasher.hash('1234');
      final b = hasher.hash('1234');
      expect(a.salt, isNot(b.salt));
      expect(a.hash, isNot(b.hash));
    });

    test('defaults to at least 100k iterations in production', () {
      expect(Pbkdf2PinHasher.defaultIterations, greaterThanOrEqualTo(100000));
    });
  });

  group('verify', () {
    final credential = hasher.hash('2468');

    test('true for the exact original PIN', () {
      expect(hasher.verify('2468', credential), isTrue);
    });

    for (final wrong in ['2467', '24680', '246', '8642', '02468', 'abcd', '']) {
      test('false for ${jsonEncode(wrong)}', () {
        expect(hasher.verify(wrong, credential), isFalse);
      });
    }

    test('uses the credential\'s own iteration count, not the default', () {
      final other = Pbkdf2PinHasher(iterations: 3);
      expect(other.verify('2468', credential), isTrue);
    });

    test('false against a tampered salt or hash', () {
      final tamperedSalt = PinCredential(
        hash: credential.hash,
        salt: base64Encode(List<int>.filled(16, 7)),
        iterations: credential.iterations,
      );
      final tamperedIterations = PinCredential(
        hash: credential.hash,
        salt: credential.salt,
        iterations: credential.iterations + 1,
      );
      expect(hasher.verify('2468', tamperedSalt), isFalse);
      expect(hasher.verify('2468', tamperedIterations), isFalse);
    });

    test('false (never throws) for a corrupted credential', () {
      const corrupted = PinCredential(hash: '%%%', salt: '%%%', iterations: 10);
      const zeroIterations = PinCredential(
        hash: 'AA==',
        salt: 'AA==',
        iterations: 0,
      );
      expect(hasher.verify('2468', corrupted), isFalse);
      expect(hasher.verify('2468', zeroIterations), isFalse);
    });
  });

  group('PBKDF2-HMAC-SHA256 derivation', () {
    // RFC 7914 §11 test vector: P="passwd", S="salt", c=1, dkLen=64 —
    // the first 32 bytes are the single block this implementation derives.
    test('matches the RFC 7914 PBKDF2-HMAC-SHA256 vector (c=1)', () {
      final dk = Pbkdf2PinHasher.derive('passwd', utf8.encode('salt'), 1);
      expect(
        _hex(dk),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    // Widely published vector: P="password", S="salt", c=2, dkLen=32.
    test('matches the published PBKDF2-HMAC-SHA256 vector (c=2)', () {
      final dk = Pbkdf2PinHasher.derive('password', utf8.encode('salt'), 2);
      expect(
        _hex(dk),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });
  });

  group('constant-time comparison', () {
    test('equal inputs', () {
      expect(Pbkdf2PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('differs at first, last, or in length', () {
      expect(Pbkdf2PinHasher.constantTimeEquals([9, 2, 3], [1, 2, 3]), isFalse);
      expect(Pbkdf2PinHasher.constantTimeEquals([1, 2, 9], [1, 2, 3]), isFalse);
      expect(Pbkdf2PinHasher.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
      expect(Pbkdf2PinHasher.constantTimeEquals(<int>[], [0]), isFalse);
    });

    // Structural review (T009): the comparison must accumulate differences
    // over every byte rather than exit early, and verify must not fall back
    // to String equality on the encoded hashes.
    test('is structurally non-short-circuiting', () {
      final source = File(
        'lib/features/app_lock/domain/services/pin_hasher.dart',
      ).readAsStringSync();
      final body = source.substring(
        source.indexOf('static bool constantTimeEquals'),
      );
      final fn = body.substring(0, body.indexOf('\n  }\n'));
      expect(fn, contains('diff |='));
      expect(fn, isNot(contains('return false')));
      expect(fn, isNot(contains('break')));
      expect(source, isNot(contains('== credential.hash')));
    });
  });
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
