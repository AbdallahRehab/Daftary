import 'dart:async';

import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/app_lock_status_provider.dart';
import 'package:daftary/features/sms_import/data/platform/app_external_activity_runner.dart';
import 'package:daftary/features/sms_import/data/platform/app_lock_status.dart';
import 'package:daftary/features/sms_import/data/platform/flutter_lifecycle_state_source.dart';
import 'package:daftary/features/sms_import/data/platform/in_memory_review_lease_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoLock implements AppLockStatusProvider {
  @override
  Future<Duration?> lockTimeoutIfEnabled() async => null;
}

/// T065 — the app adapters behind the SMS domain ports.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryReviewLeaseRegistry', () {
    test('counted leases; release is idempotent', () {
      final registry = InMemoryReviewLeaseRegistry();
      expect(registry.isLeased('a'), isFalse);
      final first = registry.acquire('a');
      final second = registry.acquire('a');
      expect(registry.isLeased('a'), isTrue);
      first
        ..release()
        ..release();
      expect(registry.isLeased('a'), isTrue);
      second.release();
      expect(registry.isLeased('a'), isFalse);
      expect(first.importId, 'a');
    });
  });

  group('AppLockStatus', () {
    test('mirrors isLocked and streams changes', () async {
      final observer = AppLifecycleObserver(_NoLock());
      final status = AppLockStatus(observer);
      expect(status.isLocked, isFalse);
      final seen = <bool>[];
      final subscription = status.changes.listen(seen.add);
      observer.lock();
      observer.unlock();
      await Future<void>.delayed(Duration.zero);
      expect(seen, [true, false]);
      expect(status.isLocked, isFalse);
      await subscription.cancel();
      observer.lock();
      await Future<void>.delayed(Duration.zero);
      expect(seen, [true, false]);
      expect(status.isLocked, isTrue);
    });
  });

  group('AppExternalActivityRunner', () {
    test('runs the body through runExternalActivity', () async {
      final observer = AppLifecycleObserver(_NoLock());
      final runner = AppExternalActivityRunner(observer);
      final gate = Completer<int>();
      final pending = runner.run(() => gate.future);
      gate.complete(42);
      expect(await pending, 42);
    });
  });

  group('FlutterLifecycleStateSource', () {
    test('null and resumed are resumed; other states are not', () {
      AppLifecycleState? state;
      final source = FlutterLifecycleStateSource(readState: () => state);
      expect(source.isResumed, isTrue);
      state = AppLifecycleState.resumed;
      expect(source.isResumed, isTrue);
      for (final other in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        state = other;
        expect(source.isResumed, isFalse, reason: other.name);
      }
    });

    test('the default reads the binding', () {
      expect(FlutterLifecycleStateSource().isResumed, isA<bool>());
    });
  });
}
