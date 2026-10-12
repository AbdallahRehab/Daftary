import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/sms_key_store.dart';
import 'sms_crypto_exception.dart';

/// The two random 32-byte SMS keys (`sms_import.enc_key.v1` for AES-GCM,
/// `sms_import.mac_key.v1` for HMAC), base64 in a **dedicated** secure
/// storage instance (research Decision 6, analysis M7).
///
/// - Lazy: a key is created on first use, then written and read back to
///   verify before it is used.
/// - Single flight: every load, generation and purge runs one at a time, so
///   concurrent first use yields one key.
/// - Cached per process, to keep secure-storage reads to a minimum. Callers
///   get a copy of the bytes.
/// - Any storage error, or a key that cannot be verified, throws
///   [SmsCryptoException] with [SmsCryptoError.keyUnavailable] and is never
///   cached or logged. Callers treat it as purged (FR-074a).
/// - Key loss: the call that first fails to read an existing key never
///   overwrites it, so a transient error loses nothing. When the next use
///   in this process still cannot read it, the key is lost: that one entry
///   is replaced by a fresh key ("the new key is generated on next use").
///   Old blobs then stay unreadable and old tombstones stop matching, the
///   accepted outcome (FR-062). No other secure-storage entry is touched.
@LazySingleton(as: SmsKeyStore)
class SecureStorageSmsKeyStore implements SmsKeyStore {
  /// [storage] is for tests. The app uses [defaultStorage]; DI never
  /// injects the app's shared instance here (`@ignoreParam`).
  SecureStorageSmsKeyStore({@ignoreParam FlutterSecureStorage? storage})
    : _storage = storage ?? defaultStorage;

  static const String encKeyName = 'sms_import.enc_key.v1';
  static const String macKeyName = 'sms_import.mac_key.v1';
  static const int keyLength = 32;

  /// Its own instance, not the app's shared one (`register_module.dart`):
  ///
  /// - `resetOnError: false`: an SMS key error never makes the plugin wipe
  ///   the store. The shared instance keeps the default `true`.
  /// - `storageNamespace`: on Android its data preferences, KeyStore alias
  ///   and wrapped key are separate from the shared instance's, so a reset
  ///   triggered by the shared instance cannot erase the SMS keys either,
  ///   and nothing here can erase the PIN hash, cloud session or AI key.
  /// - iOS: the same `first_unlock_this_device` accessibility as the shared
  ///   instance, so no backup restores a usable key. Keychain items are per
  ///   key, so no namespace is needed there.
  static const FlutterSecureStorage defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      storageNamespace: 'daftary_sms_import',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;
  final Random _random = Random.secure();
  final _KeySlot _enc = _KeySlot(encKeyName);
  final _KeySlot _mac = _KeySlot(macKeyName);

  /// The tail of the operation queue (single flight).
  Future<void> _tail = Future<void>.value();

  @override
  Future<Uint8List> encKey() => _key(_enc);

  @override
  Future<Uint8List> macKey() => _key(_mac);

  /// Deletes both keys and forgets the cached copies (Delete all data).
  /// Waits for any load in flight, so no key outlives the purge. Both
  /// deletes are attempted even if one fails; a failure then throws
  /// [SmsCryptoError.keyUnavailable].
  @override
  Future<void> purge() => _serialized(() async {
    var failed = false;
    for (final slot in [_enc, _mac]) {
      slot
        ..cached = null
        ..readFailed = false;
      try {
        await _storage.delete(key: slot.name);
      } catch (_) {
        failed = true;
      }
    }
    if (failed) throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
  });

  Future<Uint8List> _key(_KeySlot slot) async {
    final cached = slot.cached;
    if (cached != null) return Uint8List.fromList(cached);
    // Callers that arrive while a load is in flight join it and share its
    // result or its failure: one burst of calls is one "use".
    final flight = slot.inflight ??= _serialized(() async {
      try {
        return slot.cached ??= await _loadOrCreate(slot);
      } finally {
        slot.inflight = null;
      }
    });
    return Uint8List.fromList(await flight);
  }

  Future<Uint8List> _loadOrCreate(_KeySlot slot) async {
    String? stored;
    try {
      stored = await _storage.read(key: slot.name);
    } catch (_) {
      if (!slot.readFailed) {
        // First failure: report it, keep the entry, retry on next use.
        slot.readFailed = true;
        throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
      }
      // Still unreadable on the next use: the key is lost.
      return _create(slot, replaceUnreadable: true);
    }
    slot.readFailed = false;
    final existing = _decode(stored);
    if (existing != null) return existing;
    // Absent, or present but malformed (unusable either way).
    return _create(slot, replaceUnreadable: false);
  }

  Future<Uint8List> _create(
    _KeySlot slot, {
    required bool replaceUnreadable,
  }) async {
    final fresh = Uint8List.fromList(
      List.generate(keyLength, (_) => _random.nextInt(256)),
    );
    final encoded = base64.encode(fresh);
    try {
      if (replaceUnreadable) {
        // Only this one entry, in this store's own namespace.
        await _storage.delete(key: slot.name);
      }
      await _storage.write(key: slot.name, value: encoded);
      final readBack = await _storage.read(key: slot.name);
      if (readBack != encoded) {
        throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
      }
    } catch (_) {
      throw const SmsCryptoException(SmsCryptoError.keyUnavailable);
    }
    slot.readFailed = false;
    return fresh;
  }

  static Uint8List? _decode(String? stored) {
    if (stored == null) return null;
    try {
      final bytes = base64.decode(stored);
      return bytes.length == keyLength ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  /// Runs [body] after every operation queued before it.
  Future<T> _serialized<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

class _KeySlot {
  _KeySlot(this.name);

  final String name;
  Uint8List? cached;
  Future<Uint8List>? inflight;

  /// Set after a read error, cleared by any successful read or creation.
  bool readFailed = false;
}
