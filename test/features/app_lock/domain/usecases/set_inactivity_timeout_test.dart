import 'dart:async';

import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/data/services/repository_app_lock_status_provider.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/domain/usecases/set_inactivity_timeout.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_secure_app_lock_storage.dart';

/// T070 — `SetInactivityTimeout` persists the new value, and a running
/// `AppLifecycleObserver` picks it up only on the NEXT backgrounding, never
/// retroactively for a timer already in flight (FR-025).
void main() {
  late FakeSecureAppLockStorage storage;
  late AppLockRepositoryImpl repository;
  late SetInactivityTimeout setTimeout;

  setUp(() async {
    storage = FakeSecureAppLockStorage();
    repository = AppLockRepositoryImpl(
      storage,
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      runPinWork: runPinWorkInline,
    );
    setTimeout = SetInactivityTimeout(repository);
    await repository.setPin('1234');
    await repository.enableAppLock();
  });

  test('persists the new value', () async {
    await setTimeout(InactivityTimeout.after5min);

    expect(storage.config?.inactivityTimeout, InactivityTimeout.after5min);
    final config = (await repository.getConfig()).getOrElse((f) => fail('$f'));
    expect(config.inactivityTimeout, InactivityTimeout.after5min);
  });

  test('storage error -> Left, nothing changed', () async {
    storage.throwOnNextCall = Exception('keystore');

    final result = await setTimeout(InactivityTimeout.immediately);

    expect(result.isLeft(), isTrue);
    expect(storage.config?.inactivityTimeout, InactivityTimeout.after1min);
  });

  test('an in-flight timer keeps its old timeout; the next backgrounding '
      'uses the new one', () {
    fakeAsync((async) {
      final start = DateTime(2026, 9, 24, 12);
      final observer = AppLifecycleObserver(
        RepositoryAppLockStatusProvider(repository),
        timerFactory: (duration, callback) =>
            async.run((_) => Timer(duration, callback)),
        clock: () => start.add(async.elapsed),
      );

      // Backgrounded with the default 1-minute timeout.
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      async.flushMicrotasks();

      // Changed to "Immediately" while that timer is running.
      setTimeout(InactivityTimeout.immediately);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 30));
      expect(observer.isLocked.value, isFalse, reason: 'not retroactive');

      async.elapse(const Duration(seconds: 31));
      expect(observer.isLocked.value, isTrue, reason: 'old timer still fires');

      // Next cycle: unlock, return, background again -> new value applies.
      observer
        ..unlock()
        ..didChangeAppLifecycleState(AppLifecycleState.resumed)
        ..didChangeAppLifecycleState(AppLifecycleState.paused);
      async.flushMicrotasks();
      expect(observer.isLocked.value, isTrue, reason: 'immediately');

      observer.dispose();
    });
  });
}
