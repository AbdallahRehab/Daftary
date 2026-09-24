import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/app_lock/domain/usecases/wipe_all_local_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';
import '../../helpers/wipe_harness.dart';

/// Deletes the PIN credential, then fails — a keychain error part-way
/// through clearing the three `app_lock.*` keys.
class PartiallyFailingDeleteStorage extends FakeSecureAppLockStorage {
  bool failDeleteAll = false;

  @override
  Future<void> deleteAll() async {
    if (!failDeleteAll) return super.deleteAll();
    credential = null;
    throw StateError('keychain unavailable');
  }
}

/// T057 — `WipeAllLocalData` (FR-019) clears every `AppDatabase` table AND
/// all three `app_lock.*` secure-storage keys as one all-or-nothing
/// operation: either both are fully cleared, or neither is changed at all.
/// Failures are injected mid-wipe on each side of the boundary. The
/// release-blocking correctness anchor for FR-019's atomicity.
void main() {
  late PartiallyFailingDeleteStorage storage;
  late WipeHarness harness;
  late WipeAllLocalData wipeAllLocalData;

  setUp(() async {
    storage = PartiallyFailingDeleteStorage();
    harness = WipeHarness.open(storage);
    wipeAllLocalData = WipeAllLocalData(harness.deleteAllUserData);
    await harness.populate();
    await harness.configureAppLock();
  });

  tearDown(() => harness.close());

  test('clears every table and all three app_lock keys, returning the app '
      'to first-launch state', () async {
    expect(await wipeAllLocalData(), const Right<Failure, Unit>(unit));

    await harness.expectFreshInstall();
    expect(storage.config, isNull);
    expect(storage.credential, isNull);
    expect(storage.lockout, isNull);
  });

  test('a database failure mid-wipe leaves every table AND every app_lock '
      'key exactly as they were', () async {
    final tablesBefore = await harness.snapshotContents();
    final keysBefore = (storage.config, storage.credential, storage.lockout);
    await harness.forceMidWipeDatabaseFailure();

    final result = await wipeAllLocalData();

    expect(result.isLeft(), isTrue);
    expect(await harness.snapshotContents(), tablesBefore);
    expect((storage.config, storage.credential, storage.lockout), keysBefore);
  });

  test('a secure-storage failure mid-delete restores the keys already '
      'removed and never touches the database', () async {
    final tablesBefore = await harness.snapshotContents();
    final keysBefore = (storage.config, storage.credential, storage.lockout);
    storage.failDeleteAll = true;

    final result = await wipeAllLocalData();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
    expect(await harness.snapshotContents(), tablesBefore);
    expect((storage.config, storage.credential, storage.lockout), keysBefore);
  });

  test('a secure-storage read failure refuses to start, changing '
      'nothing', () async {
    final tablesBefore = await harness.snapshotContents();
    final keysBefore = (storage.config, storage.credential, storage.lockout);
    storage.throwOnNextCall = StateError('keychain unavailable');

    final result = await wipeAllLocalData();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
    expect(await harness.snapshotContents(), tablesBefore);
    expect((storage.config, storage.credential, storage.lockout), keysBefore);
  });

  test('never leaks PIN material into a failure', () async {
    await harness.forceMidWipeDatabaseFailure();
    storage.failDeleteAll = true;
    final credential = storage.credential!;

    final failure = (await wipeAllLocalData()).getLeft().toNullable()!;

    expect(failure.message, isNot(contains(credential.hash)));
    expect(failure.message, isNot(contains(credential.salt)));
  });

  test('is safe to repeat after a success', () async {
    await wipeAllLocalData();
    expect(await wipeAllLocalData(), const Right<Failure, Unit>(unit));
    await harness.expectFreshInstall();
  });
}
