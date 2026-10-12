import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_catch_up_scan.dart';
import 'package:daftary/features/sms_import/presentation/sms_catch_up_trigger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class _MockRunCatchUp extends Mock implements RunCatchUpScan {}

class _MockExpire extends Mock implements ExpirePendingImports {}

/// Counts every `isLocked` read, so a test can prove when it happens.
class _CountingLock extends FakeLockStatus {
  int reads = 0;

  @override
  bool get isLocked {
    reads++;
    return super.isLocked;
  }
}

/// A frame waiter the test releases by hand.
class _Frames {
  final List<Completer<void>> pending = [];

  Future<void> wait() {
    final frame = Completer<void>();
    pending.add(frame);
    return frame.future;
  }

  void drawAll() {
    final drawn = List.of(pending);
    pending.clear();
    for (final frame in drawn) {
      frame.complete();
    }
  }
}

final _ran = CatchUpRan(ScanSummary());

/// T125 (presentation half) — `SmsCatchUpTrigger`: `isLocked` is read only
/// after a post-frame callback; single flight; a 60-second debounce;
/// the startup expiry after unlock; never throws.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRunCatchUp catchUp;
  late _MockExpire expire;
  late _CountingLock lock;
  late FixedClock clock;
  late _Frames frames;
  late SmsCatchUpTrigger trigger;

  SmsCatchUpTrigger build({FrameWaiter? waiter}) => SmsCatchUpTrigger(
    catchUp,
    expire,
    lock,
    clock,
    waitForFrame: waiter ?? frames.wait,
  );

  setUp(() {
    catchUp = _MockRunCatchUp();
    expire = _MockExpire();
    lock = _CountingLock();
    clock = FixedClock(DateTime(2026, 10, 12, 9));
    frames = _Frames();
    when(() => catchUp()).thenAnswer((_) async => _ran);
    when(
      () => expire(now: any(named: 'now')),
    ).thenAnswer((_) async => const Right(0));
    trigger = build();
  });

  tearDown(() async {
    await trigger.dispose();
    await lock.close();
  });

  group('post-frame lock check', () {
    test('isLocked is not read before the frame is drawn', () async {
      final run = trigger.runIfDue();
      await pumpEventQueue();

      expect(lock.reads, 0);
      verifyNever(() => catchUp());
      verifyNever(() => expire(now: any(named: 'now')));

      frames.drawAll();
      expect(await run, isTrue);
      expect(lock.reads, greaterThan(0));
      verify(() => catchUp()).called(1);
    });

    test('a lock decided during the frame skips the run', () async {
      final run = trigger.runIfDue();
      await pumpEventQueue();
      // App Lock locks asynchronously on resume, before the frame ends.
      lock.lock();
      frames.drawAll();

      expect(await run, isFalse);
      verifyNever(() => catchUp());
      verifyNever(() => expire(now: any(named: 'now')));
    });

    testWidgets('the default waiter reads isLocked only after a frame', (
      tester,
    ) async {
      // No waiter: the production `WidgetsBinding.endOfFrame`.
      final production = SmsCatchUpTrigger(catchUp, expire, lock, clock);
      addTearDown(production.dispose);

      final run = production.runIfDue();
      await tester.runAsync(pumpEventQueue);
      expect(lock.reads, 0);

      await tester.pump();
      expect(await run, isTrue);
      expect(lock.reads, greaterThan(0));
    });
  });

  group('single flight', () {
    test('overlapping calls share one catch-up', () async {
      final gate = Completer<CatchUpOutcome>();
      when(() => catchUp()).thenAnswer((_) => gate.future);

      final first = trigger.runIfDue();
      final second = trigger.runIfDue();
      expect(identical(first, second), isTrue);

      frames.drawAll();
      await pumpEventQueue();
      gate.complete(_ran);

      expect(await Future.wait([first, second]), [true, true]);
      verify(() => catchUp()).called(1);
    });

    test('a resume during a run joins it', () async {
      final gate = Completer<CatchUpOutcome>();
      when(() => catchUp()).thenAnswer((_) => gate.future);
      trigger.start();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();

      trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(frames.pending, isEmpty);

      gate.complete(_ran);
      await pumpEventQueue();
      verify(() => catchUp()).called(1);
    });
  });

  group('60-second debounce', () {
    test('a second resume within 60 s does not run again', () async {
      final first = trigger.runIfDue();
      frames.drawAll();
      expect(await first, isTrue);

      clock.advance(const Duration(seconds: 59));
      final second = trigger.runIfDue();
      frames.drawAll();
      expect(await second, isFalse);
      verify(() => catchUp()).called(1);
    });

    test('a resume 60 s or more later runs again', () async {
      final first = trigger.runIfDue();
      frames.drawAll();
      await first;

      clock.advance(SmsCatchUpTrigger.debounce);
      final second = trigger.runIfDue();
      frames.drawAll();
      expect(await second, isTrue);
      verify(() => catchUp()).called(2);
    });

    test('the debounce is 60 seconds', () {
      expect(SmsCatchUpTrigger.debounce, const Duration(seconds: 60));
    });

    test('a locked attempt does not start the debounce', () async {
      lock.lock();
      final locked = trigger.runIfDue();
      frames.drawAll();
      expect(await locked, isFalse);

      lock.unlock();
      final unlocked = trigger.runIfDue();
      frames.drawAll();
      expect(await unlocked, isTrue);
      verify(() => catchUp()).called(1);
    });
  });

  group('lifecycle', () {
    test('start runs a first pass and is idempotent', () async {
      trigger
        ..start()
        ..start();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();

      verify(() => catchUp()).called(1);
    });

    test('resumed runs a pass; other states do not', () async {
      trigger.start();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();
      clearInteractions(catchUp);
      clock.advance(const Duration(minutes: 5));

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        trigger.didChangeAppLifecycleState(state);
      }
      await pumpEventQueue();
      expect(frames.pending, isEmpty);

      trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();
      verify(() => catchUp()).called(1);
    });

    test('a start while locked waits for the unlock', () async {
      lock.lock();
      trigger.start();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();
      verifyNever(() => catchUp());
      verifyNever(() => expire(now: any(named: 'now')));

      lock.unlock();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();
      verify(() => expire(now: any(named: 'now'))).called(1);
      verify(() => catchUp()).called(1);
    });

    test('locking cancels a running catch-up', () async {
      final gate = Completer<CatchUpOutcome>();
      when(() => catchUp()).thenAnswer((_) => gate.future);
      trigger.start();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();

      lock.lock();
      await pumpEventQueue();
      verify(() => catchUp.cancel()).called(1);
      gate.complete(_ran);
    });

    test('after dispose, resumes and unlocks do nothing', () async {
      trigger.start();
      await pumpEventQueue();
      frames.drawAll();
      await pumpEventQueue();
      clearInteractions(catchUp);
      await trigger.dispose();
      clock.advance(const Duration(minutes: 5));

      lock
        ..lock()
        ..unlock();
      await pumpEventQueue();
      expect(frames.pending, isEmpty);
      verifyNever(() => catchUp());
    });
  });

  group('startup expiry', () {
    test('runs ExpirePendingImports once, before the first catch-up', () async {
      final order = <String>[];
      when(() => expire(now: any(named: 'now'))).thenAnswer((_) async {
        order.add('expire');
        return const Right(2);
      });
      when(() => catchUp()).thenAnswer((_) async {
        order.add('catchUp');
        return _ran;
      });

      final first = trigger.runIfDue();
      frames.drawAll();
      await first;
      clock.advance(const Duration(minutes: 2));
      final second = trigger.runIfDue();
      frames.drawAll();
      await second;

      expect(order, ['expire', 'catchUp', 'catchUp']);
    });

    test('runs again on a pass a day later in the same process', () async {
      final first = trigger.runIfDue();
      frames.drawAll();
      await first;
      clock.advance(const Duration(hours: 23));
      final second = trigger.runIfDue();
      frames.drawAll();
      await second;
      verify(() => expire(now: any(named: 'now'))).called(1);

      clock.advance(const Duration(hours: 2));
      final third = trigger.runIfDue();
      frames.drawAll();
      await third;
      verify(() => expire(now: any(named: 'now'))).called(1);
    });

    test('an expiry failure does not stop the catch-up', () async {
      when(
        () => expire(now: any(named: 'now')),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));

      final run = trigger.runIfDue();
      frames.drawAll();
      expect(await run, isTrue);
    });
  });

  group('never throws', () {
    test('a throwing catch-up returns false', () async {
      when(() => catchUp()).thenThrow(StateError('boom'));

      final run = trigger.runIfDue();
      frames.drawAll();
      expect(await run, isFalse);
    });

    test('a skipped or failed outcome returns false', () async {
      when(
        () => catchUp(),
      ).thenAnswer((_) async => const CatchUpSkipped(ScanBlockReason.disabled));
      final skipped = trigger.runIfDue();
      frames.drawAll();
      expect(await skipped, isFalse);

      clock.advance(const Duration(minutes: 2));
      when(() => catchUp()).thenAnswer(
        (_) async => CatchUpFailed(const UnknownFailure('x'), ScanSummary()),
      );
      final failed = trigger.runIfDue();
      frames.drawAll();
      expect(await failed, isFalse);
    });
  });
}
