import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/notification_engine.dart';
import 'package:daftary/features/insights_notifications/presentation/notification_recompute_trigger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../domain/usecases/notification_engine_harness.dart';

class _MockEngine extends Mock implements NotificationEngine {}

/// T027 — the startup + foreground catch-up trigger.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockEngine engine;
  late FakeLastRunStore lastRun;
  late FakeClock clock;
  late NotificationRecomputeTrigger trigger;

  setUp(() {
    engine = _MockEngine();
    lastRun = FakeLastRunStore();
    clock = FakeClock(DateTime(2026, 9, 24, 12));
    trigger = NotificationRecomputeTrigger(engine, lastRun, clock);
    when(() => engine.run()).thenAnswer((_) async {
      await lastRun.write(clock.now());
      return const Right(NotificationRunSummary.empty);
    });
  });

  tearDown(() => trigger.dispose());

  test('start runs a pass when none has ever completed', () async {
    trigger.start();
    await pumpEventQueue();

    verify(() => engine.run()).called(1);
  });

  test('skips a pass within 6 hours of the last one', () async {
    lastRun.value = clock.now().subtract(const Duration(hours: 5));

    expect(await trigger.runIfDue(), isFalse);
    verifyNever(() => engine.run());
  });

  test('runs once more than 6 hours have passed', () async {
    lastRun.value = clock.now().subtract(const Duration(hours: 6, minutes: 1));

    expect(await trigger.runIfDue(), isTrue);
    verify(() => engine.run()).called(1);
  });

  test('resume runs only when due', () async {
    trigger.start();
    await pumpEventQueue();
    clearInteractions(engine);

    trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    verifyNever(() => engine.run());

    clock.current = clock.current.add(const Duration(hours: 7));
    trigger.didChangeAppLifecycleState(AppLifecycleState.paused);
    await pumpEventQueue();
    verifyNever(() => engine.run());

    trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    verify(() => engine.run()).called(1);
  });

  test('overlapping calls share one pass', () async {
    final gate = Completer<Either<Failure, NotificationRunSummary>>();
    when(() => engine.run()).thenAnswer((_) => gate.future);

    final first = trigger.runIfDue();
    final second = trigger.runIfDue();
    gate.complete(const Right(NotificationRunSummary.empty));

    expect(await Future.wait([first, second]), [true, true]);
    verify(() => engine.run()).called(1);
  });

  test('an engine that throws never escapes the trigger', () async {
    when(() => engine.run()).thenThrow(StateError('boom'));

    expect(await trigger.runIfDue(), isFalse);
  });
}
