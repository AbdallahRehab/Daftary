import 'package:daftary/core/database/app_database.dart'
    show Value, driftRuntimeOptions;
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_scheduler.dart';
import 'package:daftary/core/sync/sync_trigger.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/sync_harness.dart';
import 'fakes/sync_test_doubles.dart';

/// Counts cycles that actually reached the engine.
class _CountingEngine extends SyncEngine {
  _CountingEngine(SyncHarness h)
    : super(
        h.store,
        h.remote,
        h.auth,
        h.supabase,
        h.connectivity,
        h.backoff,
        h.logger,
        h.clock,
      );

  int cycles = 0;
  final List<bool> ignoredBackoff = [];

  @override
  Future<SyncCycleOutcome> runCycle({bool ignoreBackoff = false}) {
    cycles++;
    ignoredBackoff.add(ignoreBackoff);
    return super.runCycle(ignoreBackoff: ignoreBackoff);
  }
}

/// A [FakeClock] that follows fake-async time.
class _AsyncClock extends FakeClock {
  _AsyncClock(this._async);

  final FakeAsync _async;
  final _start = DateTime.utc(2026, 9, 27, 9);

  @override
  DateTime now() => _start.add(_async.elapsed);
}

/// Everything a scheduler test needs, living inside one fake-async zone.
class _Ctx {
  _Ctx(this.async, {bool online = true}) {
    h = SyncHarness(clock: _AsyncClock(async));
    h.connectivity.online = online;
    engine = _CountingEngine(h);
    scheduler = SyncScheduler(
      engine,
      h.store,
      h.supabase,
      h.connectivity,
      h.db,
      h.backoff,
      h.logger,
      h.clock,
    );
    scheduler.status.listen(statuses.add);
  }

  final FakeAsync async;
  late final SyncHarness h;
  late final _CountingEngine engine;
  late final SyncScheduler scheduler;
  final statuses = <SchedulerState>[];

  /// Drives fake time until [future] completes.
  T wait<T>(Future<T> future) {
    var done = false;
    T? value;
    Object? error;
    future.then(
      (v) {
        value = v;
        done = true;
      },
      onError: (Object e) {
        error = e;
        done = true;
      },
    );
    for (var i = 0; i < 500 && !done; i++) {
      async.elapse(const Duration(milliseconds: 1));
    }
    if (!done) throw StateError('future never completed');
    if (error != null) throw error!;
    return value as T;
  }

  /// Lets [by] of fake time pass, then waits for any cycle to finish.
  void settle([Duration by = Duration.zero]) {
    async.elapse(by);
    async.elapse(const Duration(milliseconds: 100));
    wait(scheduler.idle);
    async.elapse(const Duration(milliseconds: 100));
  }

  void setOnline(bool online) {
    h.connectivity.online = online;
    async.flushMicrotasks();
  }

  void dispose() {
    scheduler.dispose();
    async.elapse(const Duration(seconds: 1));
    h.close();
    async.elapse(const Duration(minutes: 30));
  }
}

/// 021 T060: triggers, single-flight, backoff and the disabled state, with
/// fake connectivity, a fake clock and [FakeSyncRemote].
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // Each test opens its own in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  void fakeTest(
    String description,
    void Function(_Ctx c) body, {
    bool online = true,
  }) {
    test(description, () {
      fakeAsync((async) {
        final c = _Ctx(async, online: online);
        body(c);
        c.dispose();
      });
    });
  }

  fakeTest('offline → online gives exactly 1 cycle', (c) {
    c.wait(c.h.createPerson('p1'));
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.engine.cycles, 0);
    expect(c.scheduler.currentStatus, SchedulerState.offline);

    c.setOnline(true);
    c.settle(SyncScheduler.networkSettle);
    c.settle(const Duration(seconds: 10));
    expect(c.engine.cycles, 1);
    expect(c.h.remote.rowCount(SyncEntityType.person), 1);
    expect(c.scheduler.currentStatus, SchedulerState.idle);
  }, online: false);

  fakeTest('10 on/off flaps give 1 cycle', (c) {
    c.wait(c.scheduler.start());
    c.settle();
    for (var i = 0; i < 10; i++) {
      c.setOnline(true);
      c.async.elapse(const Duration(milliseconds: 100));
      c.setOnline(false);
      c.async.elapse(const Duration(milliseconds: 100));
    }
    c.setOnline(true);
    c.settle(SyncScheduler.networkSettle);
    c.settle(const Duration(seconds: 10));
    expect(c.engine.cycles, 1);
  }, online: false);

  fakeTest('online → offline mid-cycle leaves the operations pending', (c) {
    c.wait(c.h.createPerson('p1'));
    // The connection drops while the call is in flight.
    c.h.remote.failNextCalls(1);
    c.wait(c.scheduler.start());
    c.setOnline(false);
    c.settle();

    expect(c.engine.cycles, 1);
    final op = c.wait(c.h.opFor('p1'));
    expect(op!.status, OutboxStatus.pending);
    expect(op.errorCode, 'network');
    expect(c.h.remote.rowCount(SyncEntityType.person), 0);
  });

  fakeTest('a network that is present while the remote throws is a '
      'transient backoff, and flaps do not shorten it', (c) {
    c.wait(c.h.createPerson('p1'));
    c.h.remote.failNextCalls(1);
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.engine.cycles, 1);
    expect(c.scheduler.currentStatus, SchedulerState.backingOff);
    expect(c.wait(c.h.state()).consecutiveFailures, 1);

    // A connectivity flap during the backoff does not run a cycle.
    c.setOnline(false);
    c.settle();
    c.setOnline(true);
    c.settle(SyncScheduler.networkSettle);
    expect(c.engine.cycles, 1);

    // Once the delay (≤ 6 s) has elapsed, the retry runs and succeeds.
    c.settle(const Duration(seconds: 5));
    expect(c.engine.cycles, 2);
    expect(c.wait(c.h.opFor('p1')), isNull);
    expect(c.scheduler.currentStatus, SchedulerState.idle);
    expect(
      c.statuses,
      containsAllInOrder([
        SchedulerState.syncing,
        SchedulerState.backingOff,
        SchedulerState.syncing,
        SchedulerState.idle,
      ]),
    );
  });

  fakeTest('5 rapid requests give at most 2 cycles', (c) {
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.engine.cycles, 1); // launch

    for (var i = 0; i < 5; i++) {
      c.scheduler.request(i == 4 ? SyncTrigger.manual : SyncTrigger.localWrite);
    }
    c.settle();
    c.settle(const Duration(seconds: 10));
    expect(c.engine.cycles, 3); // launch + the first request + 1 follow-up
    // The follow-up keeps the manual right to skip a backoff delay.
    expect(c.engine.ignoredBackoff, [false, false, true]);
  });

  fakeTest('local writes trigger one cycle after the 3 s debounce', (c) {
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.engine.cycles, 1);

    c.wait(c.h.createPerson('p1'));
    c.async.elapse(const Duration(seconds: 1));
    c.wait(c.h.createPerson('p2'));
    c.settle(const Duration(seconds: 1));
    expect(c.engine.cycles, 1);
    c.settle(const Duration(seconds: 3));
    expect(c.engine.cycles, 2);
    expect(c.h.remote.rowCount(SyncEntityType.person), 2);

    // The engine's own outbox writes do not cause another cycle.
    c.settle(const Duration(seconds: 10));
    expect(c.engine.cycles, 2);
  });

  fakeTest('the 5-minute timer runs while resumed; resuming triggers a '
      'cycle', (c) {
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.engine.cycles, 1);

    c.settle(SyncScheduler.periodicInterval);
    expect(c.engine.cycles, 2);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    c.settle(SyncScheduler.periodicInterval * 2);
    expect(c.engine.cycles, 2, reason: 'no periodic timer while paused');

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    c.settle();
    expect(c.engine.cycles, 3);
  });

  fakeTest('start resets operations left in flight by a killed app', (c) {
    c.wait(c.h.createPerson('p1'));
    final op = c.wait(c.h.opFor('p1'));
    c.wait(c.h.store.markInFlight([op!.opId]));
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.wait(c.h.opFor('p1'))!.status, OutboxStatus.pending);
  }, online: false);

  fakeTest('a persisted backoff survives a restart', (c) {
    c.wait(c.h.createPerson('p1'));
    c.wait(
      c.h.store.writeState(
        (s) => s.copyWith(
          consecutiveFailures: 3,
          lastAttemptAt: Value(c.h.clock.now().millisecondsSinceEpoch),
        ),
      ),
    );
    c.wait(c.scheduler.start());
    c.settle();
    expect(c.engine.cycles, 0);
    expect(c.scheduler.currentStatus, SchedulerState.backingOff);
    // 5 s · 2^2 = 20 s nominal.
    c.settle(const Duration(seconds: 21));
    expect(c.engine.cycles, 1);
  });

  fakeTest('unconfigured: disabled, no Supabase, no cycles', (c) {
    c.h.supabase.configured = false;
    c.wait(c.scheduler.start());
    c.scheduler.request(SyncTrigger.manual);
    c.settle();
    expect(c.scheduler.currentStatus, SchedulerState.disabled);
    expect(c.h.supabase.initializeCalls, 0);
    expect(c.engine.cycles, 0);
  });

  fakeTest('switched off: never initializes Supabase; the switch stops and '
      'restarts the token refresh', (c) {
    c.wait(c.h.store.writeState((s) => s.copyWith(enabled: false)));
    c.wait(c.scheduler.start());
    c.scheduler.request(SyncTrigger.manual);
    c.settle();
    expect(c.scheduler.currentStatus, SchedulerState.disabled);
    expect(c.h.supabase.initializeCalls, 0);
    expect(c.engine.cycles, 0);

    c.wait(c.scheduler.setEnabled(true));
    c.settle();
    expect(c.h.supabase.startRefreshCalls, 1);
    expect(c.h.supabase.initializeCalls, 1);
    expect(c.engine.cycles, 1);

    c.wait(c.scheduler.setEnabled(false));
    c.settle();
    expect(c.h.supabase.stopRefreshCalls, 1);
    expect(c.scheduler.currentStatus, SchedulerState.disabled);
    c.scheduler.request(SyncTrigger.manual);
    c.settle();
    expect(c.engine.cycles, 1);
  });
}
