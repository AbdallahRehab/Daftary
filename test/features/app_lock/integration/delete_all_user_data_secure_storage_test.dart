import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/data/datasources/secure_app_lock_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/wipe_harness.dart';

/// flutter_secure_storage's in-memory test platform, with one key's delete
/// forced to fail — a keychain error part-way through the three deletes.
class FlakyFlutterSecureStorage extends FlutterSecureStorage {
  FlakyFlutterSecureStorage();

  String? failDeleteOf;

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    if (key == failDeleteOf) throw StateError('keychain unavailable');
    return super.delete(key: key);
  }
}

/// T086 — 013's canonical `DeleteAllUserData`, run against a real
/// in-memory drift database (as 013's `data_wipe_test.dart` does) and the
/// real `SecureAppLockStorageImpl`, now also clears App Lock's three
/// `app_lock.*` secure-storage keys (T085) — and a forced failure on
/// either side leaves the database AND secure storage provably untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlakyFlutterSecureStorage raw;
  late WipeHarness harness;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    raw = FlakyFlutterSecureStorage();
    harness = WipeHarness.open(SecureAppLockStorageImpl(raw));
    await harness.populate();
    await harness.configureAppLock();
  });

  tearDown(() => harness.close());

  Future<Map<String, String>> appLockKeys() async => {
    for (final entry in (await raw.readAll()).entries)
      if (entry.key.startsWith('app_lock.')) entry.key: entry.value,
  };

  test('with App Lock configured, the fixture holds all three app_lock '
      'keys', () async {
    expect(
      (await appLockKeys()).keys.toSet(),
      SecureAppLockStorageImpl.allKeys.toSet(),
    );
  });

  test('a successful wipe removes all three app_lock keys along with every '
      'table', () async {
    expect(await harness.deleteAllUserData(), const Right<Failure, Unit>(unit));

    await harness.expectFreshInstall();
    expect(await appLockKeys(), isEmpty);
  });

  test('a forced mid-wipe database failure leaves the database AND secure '
      'storage untouched', () async {
    final tablesBefore = await harness.snapshotContents();
    final keysBefore = await appLockKeys();
    await harness.forceMidWipeDatabaseFailure();

    final result = await harness.deleteAllUserData();

    expect(result.isLeft(), isTrue);
    expect(await harness.snapshotContents(), tablesBefore);
    expect(await appLockKeys(), keysBefore);
  });

  for (final failingKey in SecureAppLockStorageImpl.allKeys) {
    test('a forced failure deleting $failingKey leaves the database AND '
        'secure storage untouched', () async {
      final tablesBefore = await harness.snapshotContents();
      final keysBefore = await appLockKeys();
      raw.failDeleteOf = failingKey;

      final result = await harness.deleteAllUserData();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
      expect(await harness.snapshotContents(), tablesBefore);
      expect(await appLockKeys(), keysBefore);
    });
  }
}
