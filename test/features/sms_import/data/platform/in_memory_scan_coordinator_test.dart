import 'dart:async';

import 'package:daftary/features/sms_import/data/platform/in_memory_scan_coordinator.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// T165 — one scan at a time (FR-013, analysis M11).
void main() {
  late InMemoryScanCoordinator coordinator;

  setUp(() => coordinator = InMemoryScanCoordinator());

  test('runs a body and frees the slot', () async {
    expect(coordinator.isRunning, isFalse);
    final result = await coordinator.runExclusive(
      ScanKind.explicit,
      ScanCancellationToken(),
      () async => 1,
    );
    expect(result, 1);
    expect(coordinator.isRunning, isFalse);
  });

  test('a catch-up while any scan runs is skipped', () async {
    final gate = Completer<void>();
    final explicit = coordinator.runExclusive(
      ScanKind.explicit,
      ScanCancellationToken(),
      () => gate.future.then((_) => 'explicit'),
    );
    expect(coordinator.isRunning, isTrue);
    var ran = false;
    final skipped = await coordinator.runExclusive(
      ScanKind.catchUp,
      ScanCancellationToken(),
      () async => ran = true,
    );
    expect(skipped, isNull);
    expect(ran, isFalse);
    gate.complete();
    expect(await explicit, 'explicit');

    final catchUpWhileCatchUp = Completer<void>();
    final first = coordinator.runExclusive(
      ScanKind.catchUp,
      ScanCancellationToken(),
      () => catchUpWhileCatchUp.future,
    );
    expect(
      await coordinator.runExclusive(
        ScanKind.catchUp,
        ScanCancellationToken(),
        () async {},
      ),
      isNull,
    );
    catchUpWhileCatchUp.complete();
    await first;
  });

  test(
    'an explicit scan cancels a running catch-up and waits for it',
    () async {
      final catchUpToken = ScanCancellationToken();
      final events = <String>[];
      final catchUpDone = Completer<void>();
      final catchUp = coordinator.runExclusive(
        ScanKind.catchUp,
        catchUpToken,
        () async {
          events.add('catch-up started');
          // Cooperative: stops at its next check once cancelled.
          while (!catchUpToken.isCancelled) {
            await Future<void>.delayed(Duration.zero);
          }
          await catchUpDone.future;
          events.add('catch-up stopped');
        },
      );
      await Future<void>.delayed(Duration.zero);
      final explicit = coordinator.runExclusive(
        ScanKind.explicit,
        ScanCancellationToken(),
        () async => events.add('explicit ran'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(catchUpToken.isCancelled, isTrue);
      expect(events, ['catch-up started']);
      catchUpDone.complete();
      await catchUp;
      await explicit;
      expect(events, ['catch-up started', 'catch-up stopped', 'explicit ran']);
    },
  );

  test('two explicit scans run one after the other', () async {
    final events = <String>[];
    final gate = Completer<void>();
    final first = coordinator.runExclusive(
      ScanKind.explicit,
      ScanCancellationToken(),
      () async {
        events.add('first start');
        await gate.future;
        events.add('first end');
      },
    );
    final second = coordinator.runExclusive(
      ScanKind.explicit,
      ScanCancellationToken(),
      () async => events.add('second'),
    );
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await Future.wait([first, second]);
    expect(events, ['first start', 'first end', 'second']);
  });

  test('a failing body still frees the slot', () async {
    await expectLater(
      coordinator.runExclusive(
        ScanKind.explicit,
        ScanCancellationToken(),
        () async => throw StateError('x'),
      ),
      throwsStateError,
    );
    expect(coordinator.isRunning, isFalse);
  });
}
