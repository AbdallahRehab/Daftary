import 'dart:convert';
import 'dart:typed_data';

import 'package:daftary/features/sms_import/data/crypto/secure_storage_sms_key_store.dart';
import 'package:daftary/features/sms_import/data/crypto/sms_crypto_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

const _encName = 'sms_import.enc_key.v1';
const _macName = 'sms_import.mac_key.v1';

/// Fails only the operations and keys it is told to; every other entry
/// behaves like [InMemorySecureStorage].
class _ScriptedStorage extends InMemorySecureStorage {
  final Set<String> failingReads = {};

  /// Stored values that cannot be decrypted any more (for example after a
  /// backup restore lost the wrapping key). A rewritten entry reads fine.
  final Set<String> unreadableValues = {};
  final Set<String> failingWrites = {};
  final Set<String> failingDeletes = {};

  /// Writes report success but store nothing (a broken backend), so the
  /// read-back verification fails.
  bool dropWrites = false;

  /// When set, every read returns this value instead (a corrupted backend).
  String? readOverride;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failingReads.contains(key)) throw StateError('decrypt failed');
    final value = await super.read(key: key);
    if (unreadableValues.contains(value)) throw StateError('decrypt failed');
    return readOverride ?? value;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failingWrites.contains(key)) throw StateError('write failed');
    if (dropWrites) {
      writes++;
      return;
    }
    await super.write(key: key, value: value);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failingDeletes.contains(key)) throw StateError('delete failed');
    await super.delete(key: key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    fail('the SMS key store must never call deleteAll');
  }
}

Matcher _unavailable() => isA<SmsCryptoException>().having(
  (e) => e.error,
  'error',
  SmsCryptoError.keyUnavailable,
);

/// 023 T039: the two SMS keys in a dedicated secure storage instance,
/// generated lazily and single-flight, verified by read-back, cached per
/// process, purged on delete-all. Any storage error means "key unavailable"
/// and never touches other entries.
void main() {
  const others = {
    // Entries owned by other features in the same backing store.
    'app_lock.pin_hash': 'pin',
    'sb-session': 'session',
    'ai_assistant.api_key': 'secret',
  };

  late _ScriptedStorage storage;
  late SecureStorageSmsKeyStore store;

  setUp(() {
    storage = _ScriptedStorage()..values.addAll(others);
    store = SecureStorageSmsKeyStore(storage: storage);
  });

  Map<String, String> otherEntries() => {
    for (final e in storage.values.entries)
      if (!e.key.startsWith('sms_import.')) e.key: e.value,
  };

  group('generation', () {
    test('first use creates two independent random 32-byte keys, stored '
        'base64 under the v1 names', () async {
      final enc = await store.encKey();
      final mac = await store.macKey();

      expect(enc, hasLength(32));
      expect(mac, hasLength(32));
      expect(enc, isNot(mac));
      expect(base64.decode(storage.values[_encName]!), enc);
      expect(base64.decode(storage.values[_macName]!), mac);
      expect(SecureStorageSmsKeyStore.encKeyName, _encName);
      expect(SecureStorageSmsKeyStore.macKeyName, _macName);
      expect(otherEntries(), others);
    });

    test('an existing key is loaded, never regenerated', () async {
      final existing = Uint8List.fromList(List.generate(32, (i) => i * 3));
      storage.values[_encName] = base64.encode(existing);

      expect(await store.encKey(), existing);
      expect(storage.writes, 0);
    });

    test(
      'a key is cached per process: later calls do not read storage',
      () async {
        final first = await store.encKey();
        final reads = storage.reads;
        for (var i = 0; i < 5; i++) {
          expect(await store.encKey(), first);
        }
        expect(storage.reads, reads);
      },
    );

    test('callers get a copy, so they cannot corrupt the cache', () async {
      final first = await store.encKey();
      final snapshot = Uint8List.fromList(first);
      first.fillRange(0, first.length, 0);
      expect(await store.encKey(), snapshot);
    });

    test(
      'concurrent first use yields one key per name (single flight)',
      () async {
        final results = await Future.wait<Uint8List>([
          for (var i = 0; i < 20; i++) store.encKey(),
          for (var i = 0; i < 20; i++) store.macKey(),
        ]);
        final encs = {for (final k in results.take(20)) base64.encode(k)};
        final macs = {for (final k in results.skip(20)) base64.encode(k)};

        expect(encs, hasLength(1));
        expect(macs, hasLength(1));
        expect(encs.single, storage.values[_encName]);
        expect(macs.single, storage.values[_macName]);
        expect(storage.writes, 2, reason: 'one write per key');
      },
    );

    test(
      'a second store instance over the same storage reads the same key',
      () async {
        final enc = await store.encKey();
        final other = SecureStorageSmsKeyStore(storage: storage);
        expect(await other.encKey(), enc);
        expect(storage.writes, 1);
      },
    );

    test('a malformed stored value (not base64, wrong length) is unusable '
        'and is replaced by a fresh verified key', () async {
      for (final bad in [
        '%%%not-base64%%%',
        base64.encode(List.filled(16, 7)),
      ]) {
        storage.values[_encName] = bad;
        final fresh = SecureStorageSmsKeyStore(storage: storage);
        final key = await fresh.encKey();
        expect(key, hasLength(32));
        expect(storage.values[_encName], base64.encode(key));
      }
      expect(otherEntries(), others);
    });
  });

  group('storage errors map to key unavailable', () {
    test('a throwing storage', () async {
      storage.throwOnAccess = true;
      await expectLater(store.encKey(), throwsA(_unavailable()));
      await expectLater(store.macKey(), throwsA(_unavailable()));
    });

    test('the exception is content-free', () async {
      storage.failingReads.add(_encName);
      Object? error;
      try {
        await store.encKey();
      } catch (e) {
        error = e;
      }
      expect(error.toString(), 'SmsCryptoException(keyUnavailable)');
    });

    test('a read error on an SMS key leaves every other secure-storage '
        'entry intact and does not overwrite the unreadable key', () async {
      storage.values[_encName] = base64.encode(List.filled(32, 9));
      final before = Map.of(storage.values);
      storage.failingReads.add(_encName);

      await expectLater(store.encKey(), throwsA(_unavailable()));

      expect(storage.values, before);
      expect(storage.deletes, 0);
      expect(storage.writes, 0);
    });

    test('a transient read error loses nothing: the next use finds the same '
        'key', () async {
      final original = Uint8List.fromList(List.filled(32, 9));
      storage.values[_encName] = base64.encode(original);
      storage.failingReads.add(_encName);
      await expectLater(store.encKey(), throwsA(_unavailable()));

      storage.failingReads.clear();
      expect(await store.encKey(), original);
    });

    test('a key still unreadable on the next use is lost: only that entry is '
        'replaced by a fresh key, every other entry stays', () async {
      final original = base64.encode(List.filled(32, 9));
      final mac = base64.encode(List.filled(32, 5));
      storage.values[_encName] = original;
      storage.values[_macName] = mac;
      storage.unreadableValues.add(original);

      // First use: reported, nothing overwritten.
      await expectLater(store.encKey(), throwsA(_unavailable()));
      expect(storage.values[_encName], original);

      // Next use, still unreadable: replaced and verified by read-back.
      final fresh = await store.encKey();
      expect(base64.encode(fresh), isNot(original));
      expect(storage.values[_encName], base64.encode(fresh));
      expect(storage.values[_macName], mac);
      expect(otherEntries(), others);
      // And it is cached from now on.
      expect(await store.encKey(), fresh);
    });

    test(
      'replacing a lost key that cannot be written stays unavailable',
      () async {
        final original = base64.encode(List.filled(32, 9));
        storage.values[_encName] = original;
        storage.unreadableValues.add(original);
        storage.failingWrites.add(_encName);

        await expectLater(store.encKey(), throwsA(_unavailable()));
        await expectLater(store.encKey(), throwsA(_unavailable()));
        expect(otherEntries(), others);
      },
    );

    test('concurrent callers of a failing first use share one failure, and '
        'nothing is overwritten', () async {
      storage.values[_encName] = base64.encode(List.filled(32, 9));
      storage.failingReads.add(_encName);
      final outcomes = await Future.wait<Object>([
        for (var i = 0; i < 5; i++)
          store.encKey().then<Object>((k) => k, onError: (Object e) => e),
      ]);
      expect(outcomes, everyElement(_unavailable()));
      expect(storage.writes, 0);
      expect(storage.deletes, 0);
    });

    test('a write that is not read back intact is unavailable and not '
        'cached', () async {
      storage.dropWrites = true;
      await expectLater(store.encKey(), throwsA(_unavailable()));

      storage.dropWrites = false;
      final key = await store.encKey();
      expect(storage.values[_encName], base64.encode(key));
    });

    test('a read-back that returns a different value is unavailable', () async {
      // Every read returns an unusable 8-byte key, so the store generates,
      // writes, and then reads back something else.
      storage.readOverride = base64.encode(List.filled(8, 1));
      await expectLater(store.encKey(), throwsA(_unavailable()));
    });

    test(
      'a write error is unavailable and leaves other entries intact',
      () async {
        storage.failingWrites.add(_macName);
        await expectLater(store.macKey(), throwsA(_unavailable()));
        expect(storage.values, others);
      },
    );
  });

  group('purge', () {
    test('deletes both keys, keeps every other entry, and clears the '
        'cache', () async {
      final enc = await store.encKey();
      final mac = await store.macKey();

      await store.purge();

      expect(storage.values, others);

      final newEnc = await store.encKey();
      final newMac = await store.macKey();
      expect(newEnc, isNot(enc));
      expect(newMac, isNot(mac));
    });

    test('purge on a store with no keys is a safe no-op', () async {
      await store.purge();
      expect(storage.values, others);
    });

    test('purge waits for an in-flight generation, so no key survives '
        'it', () async {
      final pending = store.encKey();
      await store.purge();
      final old = await pending;

      expect(storage.values.containsKey(_encName), isFalse);
      expect(await store.encKey(), isNot(old));
    });

    test('a delete error still attempts the other key, clears the cache and '
        'throws a content-free error', () async {
      final enc = await store.encKey();
      await store.macKey();
      storage.failingDeletes.add(_encName);

      await expectLater(store.purge(), throwsA(_unavailable()));
      expect(storage.values.containsKey(_macName), isFalse);

      // The cache was cleared: the next call reads storage again.
      final reads = storage.reads;
      expect(await store.encKey(), enc);
      expect(storage.reads, greaterThan(reads));
    });
  });

  group('dedicated storage instance (analysis M7)', () {
    test('the default instance never resets on error, has its own Android '
        'namespace, and keeps the shared iOS accessibility', () {
      const options = SecureStorageSmsKeyStore.defaultStorage;
      final android = options.aOptions.toMap();
      expect(android['resetOnError'], 'false');
      expect(android['storageNamespace'], 'daftary_sms_import');
      expect(
        options.iOptions.toMap()['accessibility'],
        KeychainAccessibility.first_unlock_this_device.name,
      );
    });
  });
}
