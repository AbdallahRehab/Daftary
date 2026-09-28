import 'dart:async';

import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/app_lock_status_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns [timeout] (null = App Lock disabled), counting reads so tests can
/// prove the timeout is read fresh on every backgrounding.
class FakeStatusProvider implements AppLockStatusProvider {
  FakeStatusProvider(this.timeout);

  Duration? timeout;
  int reads = 0;

  @override
  Future<Duration?> lockTimeoutIfEnabled() async {
    reads++;
    return timeout;
  }
}

/// T021 — primary automated evidence for FR-010 (backgrounding vs. brief
/// interruption) and the timeout/cold-launch lock rules.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStatusProvider status;

  AppLifecycleObserver build(FakeAsync async) {
    final start = DateTime(2026, 9, 24, 12);
    return AppLifecycleObserver(status, clock: () => start.add(async.elapsed));
  }

  setUp(() => status = FakeStatusProvider(const Duration(minutes: 1)));

  group('cold launch', () {
    test('locked when App Lock is enabled', () {
      fakeAsync((async) {
        final observer = build(async);
        unawaited(observer.initialize());
        async.flushMicrotasks();
        expect(observer.isLocked.value, isTrue);
        observer.dispose();
      });
    });

    test('unlocked when App Lock is disabled', () {
      status.timeout = null;
      fakeAsync((async) {
        final observer = build(async);
        unawaited(observer.initialize());
        async.flushMicrotasks();
        expect(observer.isLocked.value, isFalse);
        observer.dispose();
      });
    });
  });

  group('backgrounding', () {
    test('paused past the timeout locks (timer fires while backgrounded)', () {
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
        observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 59));
        expect(observer.isLocked.value, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(observer.isLocked.value, isTrue);
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(observer.isLocked.value, isTrue);
      });
    });

    test('paused -> resumed before the timeout does NOT lock', () {
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 30));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        async.elapse(const Duration(minutes: 10));
        expect(observer.isLocked.value, isFalse);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('a suspended process (timer never fired) still locks on resume', () {
      fakeAsync((async) {
        // Timers that never fire, like a suspended iOS process.
        final start = DateTime(2026, 9, 24, 12);
        var wallClock = start;
        final observer = AppLifecycleObserver(
          status,
          timerFactory: (_, _) => Timer(const Duration(days: 365), () {}),
          clock: () => wallClock,
        );
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        wallClock = start.add(const Duration(minutes: 2));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(observer.isLocked.value, isTrue);
      });
    });

    test('a clock moved backwards while paused locks (fail closed)', () {
      fakeAsync((async) {
        final start = DateTime(2026, 9, 24, 12);
        var wallClock = start;
        final observer = AppLifecycleObserver(status, clock: () => wallClock);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        wallClock = start.subtract(const Duration(hours: 1));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(observer.isLocked.value, isTrue);
      });
    });

    test('"immediately" locks as soon as the app is paused', () {
      status.timeout = Duration.zero;
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(observer.isLocked.value, isTrue);
      });
    });

    test('App Lock disabled: backgrounding never locks', () {
      status.timeout = null;
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(hours: 1));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(observer.isLocked.value, isFalse);
      });
    });

    test('the timeout is read fresh on every backgrounding (FR-025)', () {
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 10));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(observer.isLocked.value, isFalse);

        status.timeout = const Duration(seconds: 5);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(seconds: 5));
        expect(observer.isLocked.value, isTrue);
        expect(status.reads, 2);
      });
    });
  });

  group('brief interruptions (FR-010)', () {
    test('inactive alone never starts the timer', () {
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
        async.flushMicrotasks();
        expect(async.pendingTimers, isEmpty);
        expect(status.reads, 0);
        async.elapse(const Duration(hours: 1));
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(observer.isLocked.value, isFalse);
      });
    });

    test(
      'an external activity (own share sheet) never counts as backgrounding',
      () {
        fakeAsync((async) {
          final observer = build(async);
          final done = Completer<void>();
          unawaited(observer.runExternalActivity(() => done.future));
          observer.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(minutes: 5));
          observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
          done.complete();
          async.flushMicrotasks();
          expect(observer.isLocked.value, isFalse);

          // After the external activity ends, backgrounding counts again.
          observer.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(minutes: 1));
          expect(observer.isLocked.value, isTrue);
        });
      },
    );
  });

  group('lock/unlock', () {
    test('unlock clears the signal; lock sets it; listeners notified', () {
      fakeAsync((async) {
        final observer = build(async);
        final seen = <bool>[];
        observer.isLocked.addListener(() => seen.add(observer.isLocked.value));
        observer.lock();
        observer.unlock();
        expect(seen, [true, false]);
      });
    });

    test('unlock cancels a pending inactivity timer', () {
      fakeAsync((async) {
        final observer = build(async);
        observer.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.flushMicrotasks();
        observer.unlock();
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
