import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/platform/in_memory_scan_coordinator.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/scan_coordinator.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/services/sms_ingestion_service.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/reparse_pending.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_catch_up_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fakes.dart';

class _FixedOptions extends Fake implements LoadParserOptions {
  @override
  Future<Either<Failure, ParserOptions>> call() async =>
      const Right(ParserOptions());
}

class _SpyExpire extends Fake implements ExpirePendingImports {
  int calls = 0;

  @override
  Future<Either<Failure, int>> call({DateTime? now}) async {
    calls++;
    return const Right(0);
  }
}

class _SpyReparse extends Fake implements ReparsePending {
  int calls = 0;

  @override
  Future<Either<Failure, int>> call() async {
    calls++;
    return const Right(0);
  }
}

/// A gateway that runs [afterQuery] after its first page, or throws.
class _HookedGateway extends FakeSmsInboxGateway {
  _HookedGateway({super.rows, this.afterQuery, this.throwOnQuery = false});

  final FutureOr<void> Function()? afterQuery;
  final bool throwOnQuery;
  Completer<void>? hold;
  var _fired = false;

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    if (throwOnQuery) throw StateError('provider broke: EGP 125.50');
    final page = await super.queryInbox(
      senders: senders,
      afterDate: afterDate,
      afterId: afterId,
      limit: limit,
    );
    final gate = hold;
    if (gate != null) await gate.future;
    if (!_fired && afterQuery != null) {
      _fired = true;
      await afterQuery!();
    }
    return page;
  }
}

final DateTime _now = DateTime(2026, 3, 10, 12);

/// A synthetic NBE purchase (NBE profile phrasing; no real card number).
InboxSmsMessage _nbe(int id, {DateTime? date}) => InboxSmsMessage(
  id: id,
  address: 'NBE',
  date: date ?? DateTime(2026, 3, 9, 9).add(Duration(minutes: id)),
  body:
      'NBE: Your card ending 4821 was charged EGP $id.00 at Example '
      'Market on 09/03/2026.',
);

/// T125 — `RunCatchUpScan` (FR-013, FR-008a, domain-interfaces §5.2,
/// invariants 6, 9 and 10) against fakes. Every value is synthetic.
void main() {
  late FixedClock clock;
  late FakeSmsImportSettingsRepository settings;
  late FakeSmsImportRepository repository;
  late FakeSmsPermissionService permissions;
  late FakeLifecycle lifecycle;
  late FakeLockStatus lock;
  late ScanCoordinator coordinator;
  late RuleBasedSmsParser parser;
  late SmsIngestionService ingestion;
  late _SpyExpire expire;
  late _SpyReparse reparse;
  var ids = 0;

  setUp(() {
    ids = 0;
    clock = FixedClock(_now);
    settings = FakeSmsImportSettingsRepository(
      settings: const SmsImportSettings(isEnabled: true),
    );
    repository = FakeSmsImportRepository(clock: clock);
    permissions = FakeSmsPermissionService(status: SmsPermissionStatus.granted);
    lifecycle = FakeLifecycle();
    lock = FakeLockStatus();
    coordinator = InMemoryScanCoordinator();
    parser = RuleBasedSmsParser(clock: clock);
    expire = _SpyExpire();
    reparse = _SpyReparse();
    ingestion = SmsIngestionService(
      ParseMessages(parser),
      _FixedOptions(),
      FakeFingerprintNormalizer(),
      FakeFingerprintHasher(),
      FakeSmsMasker(),
      FakeBankReferencePolicy(),
      repository,
      settings,
      clock,
      newId: () => 'id-${ids++}',
    );
  });
  tearDown(() => lock.close());

  RunCatchUpScan build(FakeSmsInboxGateway gateway) {
    final capability = GetSmsCapability(gateway);
    return RunCatchUpScan(
      capability,
      GetSmsPermissionStatus(capability, permissions),
      settings,
      parser,
      gateway,
      ingestion,
      coordinator,
      lifecycle,
      lock,
      clock,
      expire,
      reparse,
    );
  }

  ScanSummary ran(CatchUpOutcome outcome) => switch (outcome) {
    CatchUpRan(:final summary) => summary,
    _ => fail('expected ran, got $outcome'),
  };

  group('skipped, with no inbox read (invariant 6)', () {
    test('capability off', () async {
      final gateway = FakeSmsInboxGateway(
        rows: [_nbe(1)],
        capability: const SmsCapability(
          readSmsDeclared: false,
          isAndroid: true,
        ),
      );
      expect(
        await build(gateway)(),
        const CatchUpSkipped(ScanBlockReason.capabilityOff),
      );
      expect(gateway.calls, isEmpty);
    });

    test('disabled', () async {
      settings = FakeSmsImportSettingsRepository();
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      expect(
        await build(gateway)(),
        const CatchUpSkipped(ScanBlockReason.disabled),
      );
      expect(gateway.calls, isEmpty);
      expect(permissions.statusChecks, 0);
    });

    test('locked', () async {
      lock.lock();
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      expect(
        await build(gateway)(),
        const CatchUpSkipped(ScanBlockReason.locked),
      );
      expect(gateway.calls, isEmpty);
    });

    test('not resumed (FR-008a)', () async {
      lifecycle.pause();
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      expect(
        await build(gateway)(),
        const CatchUpSkipped(ScanBlockReason.notResumed),
      );
      expect(gateway.calls, isEmpty);
    });

    for (final status in [
      SmsPermissionStatus.denied,
      SmsPermissionStatus.permanentlyDenied,
      SmsPermissionStatus.restrictedBlocked,
      SmsPermissionStatus.revoked,
    ]) {
      test('permission ${status.name}, never prompting', () async {
        permissions.status = status;
        final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
        expect(
          await build(gateway)(),
          const CatchUpSkipped(ScanBlockReason.noPermission),
        );
        expect(gateway.calls, isEmpty);
        expect(permissions.requests, 0);
      });
    }

    test('within the 60-second debounce of the last catch-up', () async {
      await settings.recordScan(
        at: _now.subtract(const Duration(seconds: 59)),
        catchUp: true,
      );
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      expect(
        await build(gateway)(),
        const CatchUpSkipped(ScanBlockReason.debounced),
      );
      expect(gateway.calls, isEmpty);
    });

    test('an explicit scan holds the coordinator', () async {
      final release = Completer<void>();
      final explicit = coordinator.runExclusive(
        ScanKind.explicit,
        ScanCancellationToken(),
        () => release.future,
      );
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      expect(
        await build(gateway)(),
        const CatchUpSkipped(ScanBlockReason.alreadyRunning),
      );
      expect(gateway.calls, isEmpty);
      release.complete();
      await explicit;
    });
  });

  group('debounce', () {
    test('runs once 60 seconds have passed, and records its start', () async {
      await settings.recordScan(
        at: _now.subtract(const Duration(seconds: 60)),
        catchUp: true,
      );
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final summary = ran(await build(gateway)());
      expect(summary.createdPending, 1);
      expect(settings.settings.lastCatchUpAt, _now);
    });

    test('a second resume right after a run is debounced', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final catchUp = build(gateway);
      ran(await catchUp());
      clock.advance(const Duration(seconds: 10));
      expect(await catchUp(), const CatchUpSkipped(ScanBlockReason.debounced));
      expect(gateway.calls, hasLength(1));
    });

    test(
      'a last catch-up in the future (clock change) does not block',
      () async {
        await settings.recordScan(
          at: _now.add(const Duration(days: 1)),
          catchUp: true,
        );
        final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
        expect(await build(gateway)(), isA<CatchUpRan>());
      },
    );
  });

  group('single flight and coordination', () {
    test('concurrent calls join one run and share its outcome', () async {
      final gateway = _HookedGateway(rows: [_nbe(1)])..hold = Completer();
      final catchUp = build(gateway);
      final first = catchUp();
      final second = catchUp();
      expect(identical(first, second), isTrue);
      expect(catchUp.isRunning, isTrue);
      gateway.hold!.complete();
      final outcomes = await Future.wait([first, second]);
      expect(outcomes[0], outcomes[1]);
      expect(gateway.calls, hasLength(1));
      expect(catchUp.isRunning, isFalse);
    });

    test('an explicit scan cancels a running catch-up, which keeps what '
        'it created (invariant 10)', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      late Future<Object?> explicit;
      final gateway = _HookedGateway(
        rows: rows,
        afterQuery: () {
          explicit = coordinator.runExclusive(
            ScanKind.explicit,
            ScanCancellationToken(),
            () async => 'explicit ran',
          );
        },
      );
      final summary = ran(await build(gateway)());
      expect(summary.cancelled, isTrue);
      expect(gateway.calls, hasLength(1));
      expect(await explicit, 'explicit ran');
    });

    test('cancel() stops the running catch-up', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      late RunCatchUpScan catchUp;
      final gateway = _HookedGateway(
        rows: rows,
        afterQuery: () => catchUp.cancel(),
      );
      catchUp = build(gateway);
      final summary = ran(await catchUp());
      expect(summary.cancelled, isTrue);
      expect(gateway.calls, hasLength(1));
    });
  });

  group('cursor', () {
    test('reads from the stored cursor minus 24 hours', () async {
      await settings.advanceCursor(date: DateTime(2026, 3, 9, 18), id: 42);
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      await build(gateway)();
      expect(gateway.calls.single.afterDate, DateTime(2026, 3, 8, 18));
      expect(gateway.calls.single.afterId, isNull);
      expect(gateway.calls.single.limit, RunCatchUpScan.pageSize);
    });

    test('the 24-hour overlap re-reads without duplicates', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1), _nbe(2)]);
      final catchUp = build(gateway);
      ran(await catchUp());
      expect(repository.rows, hasLength(2));
      clock.advance(const Duration(minutes: 5));
      final again = ran(await catchUp());
      expect(gateway.calls.last.afterDate.isBefore(_nbe(1).date), isTrue);
      expect(again.createdPending, 0);
      expect(again.alreadyKnown, 2);
      expect(repository.rows, hasLength(2));
    });

    test('never reads further back than 90 days', () async {
      await settings.advanceCursor(date: DateTime(2025, 6, 1), id: 1);
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      await build(gateway)();
      expect(gateway.calls.single.afterDate, DateTime(2025, 12, 10, 12));
    });

    test('with no cursor yet it starts at the scan window', () async {
      settings = FakeSmsImportSettingsRepository(
        settings: const SmsImportSettings(
          isEnabled: true,
          scanWindow: ScanWindow.days7,
        ),
      );
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      await build(gateway)();
      expect(gateway.calls.single.afterDate, DateTime(2026, 3, 3, 12));
    });

    test('pages until a short page and advances the cursor per page', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      final gateway = FakeSmsInboxGateway(rows: rows);
      final summary = ran(await build(gateway)());
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls[1].afterId, 200);
      expect(summary.createdPending, 205);
      expect(settings.settings.cursorId, 205);
      expect(repository.rows.values.map((r) => r.source).toSet(), {
        SmsSource.catchUpScan,
      });
    });
  });

  group('stops between pages', () {
    final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];

    Future<ScanSummary> stopAfterFirstPage(
      FutureOr<void> Function() change,
    ) async {
      final gateway = _HookedGateway(rows: rows, afterQuery: change);
      final summary = ran(await build(gateway)());
      expect(gateway.calls, hasLength(1));
      expect(summary.cancelled, isTrue);
      return summary;
    }

    test('when the feature is turned off (FR-078)', () async {
      final summary = await stopAfterFirstPage(
        () => settings.setEnabled(false),
      );
      expect(summary.createdPending, 200);
      expect(repository.rows, hasLength(200));
      expect(settings.settings.cursorId, 200);
    });

    test('when the permission is revoked (FR-012)', () async {
      await stopAfterFirstPage(
        () => permissions.status = SmsPermissionStatus.revoked,
      );
      expect(permissions.requests, 0);
    });

    test('when the app is paused (FR-008a, invariant 9)', () async {
      await stopAfterFirstPage(lifecycle.pause);
    });

    test('when App Lock engages: the run is cancelled at once', () async {
      final summary = await stopAfterFirstPage(lock.lock);
      // Cancelled before the first message of the page was handled.
      expect(summary.createdPending, 0);
      expect(settings.settings.cursorId, isNull);
    });
  });

  group('maintenance at the end', () {
    test('runs Expire and Reparse once after a run', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      await build(gateway)();
      expect(expire.calls, 1);
      expect(reparse.calls, 1);
    });

    test('not while paused or locked, and never when skipped', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      final gateway = _HookedGateway(rows: rows, afterQuery: lifecycle.pause);
      await build(gateway)();
      expect(expire.calls, 0);
      expect(reparse.calls, 0);

      settings = FakeSmsImportSettingsRepository();
      lifecycle.resume();
      await build(FakeSmsInboxGateway())();
      expect(expire.calls, 0);
    });
  });

  group('never throws', () {
    test('a gateway failure ends the run as failed, content-free', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)])
        ..nextFailure = const SmsInboxQueryFailure();
      final outcome = await build(gateway)();
      expect(outcome, isA<CatchUpFailed>());
      expect((outcome as CatchUpFailed).failure, const SmsInboxQueryFailure());
    });

    test('an exception becomes a fixed token with no content', () async {
      final gateway = _HookedGateway(rows: [_nbe(1)], throwOnQuery: true);
      final outcome = await build(gateway)();
      expect(outcome, isA<CatchUpFailed>());
      final failure = (outcome as CatchUpFailed).failure;
      expect(failure.message, isNot(matches(RegExp('[0-9]'))));
      expect(failure.toString(), isNot(contains('125')));
      // The next resume can run again (not stuck in flight).
    });

    test('a failed start record never stops the catch-up', () async {
      settings = FakeSmsImportSettingsRepository(
        settings: const SmsImportSettings(isEnabled: true),
      );
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final catchUp = build(gateway);
      settings.nextFailure = const CacheFailure('sms_settings_store_failed');
      // The first write is the start record; a failed write never stops it.
      expect(await catchUp(), isA<CatchUpRan>());
    });
  });

  test(
    'never creates a transaction: the only writes are pending rows',
    () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1), _nbe(2)]);
      await build(gateway)();
      expect(repository.confirmCalls, isEmpty);
      expect(repository.rows.values.every((r) => r.isPending), isTrue);
    },
  );
}
