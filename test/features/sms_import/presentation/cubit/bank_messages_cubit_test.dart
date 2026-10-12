import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_state.dart';
import 'dart:async';

import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';

/// T079 — the list part of `BankMessagesCubit`.
void main() {
  late FakeSmsImportRepository repository;
  late FixedClock clock;
  late BankMessagesCubit cubit;

  BankMessagesCubit build() => buildBankMessagesCubit(repository, clock);

  setUp(() {
    clock = FixedClock(DateTime(2026, 4, 10, 12));
    repository = FakeSmsImportRepository(clock: clock);
    cubit = build();
  });
  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  test('empty when nothing is pending', () async {
    await cubit.open();
    expect(cubit.state.status, BankMessagesStatus.empty);
    expect(cubit.state.showExpiredNotice, isFalse);
  });

  test('ordered low confidence first, then oldest', () async {
    repository.seed([
      buildPendingImport(
        id: 'a',
        fingerprint: 'a',
        createdAt: DateTime(2026, 4, 1),
      ),
      buildPendingImport(
        id: 'b',
        fingerprint: 'b',
        createdAt: DateTime(2026, 4, 2),
        confidence: ParseConfidence(
          fields: {
            SmsField.amount: FieldConfidence.read(FieldConfidenceLevel.low),
          },
          overall: OverallConfidence.low,
        ),
      ),
    ]);
    await cubit.open();
    expect(cubit.state.status, BankMessagesStatus.ready);
    expect(cubit.state.items.map((i) => i.id), ['b', 'a']);
  });

  test(
    'opening expires old items and shows the notice; dismiss hides it',
    () async {
      repository.seed([
        buildPendingImport(
          id: 'old',
          fingerprint: 'old',
          createdAt: DateTime(2026, 3, 1),
        ),
        buildPendingImport(
          id: 'new',
          fingerprint: 'new',
          createdAt: DateTime(2026, 4, 9),
        ),
      ]);
      await cubit.open();
      expect(cubit.state.items.map((i) => i.id), ['new']);
      expect(cubit.state.expiredNoticeCount, 1);
      await cubit.dismissExpiredNotice();
      expect(cubit.state.showExpiredNotice, isFalse);
      expect(repository.expiredNoticeSeenAt, clock.now());
    },
  );

  test('a stream failure shows the error state; retry recovers', () async {
    final failing = _FailingWatch(clock);
    await cubit.close();
    cubit = buildBankMessagesCubit(failing, clock);
    await cubit.open();
    expect(cubit.state.status, BankMessagesStatus.error);
    failing.fail = false;
    await cubit.retry();
    expect(cubit.state.status, BankMessagesStatus.empty);
    await failing.close();
  });

  test('the list follows the stream', () async {
    await cubit.open();
    // Lets the fake's generator subscribe to its change feed.
    await pumpEventQueue();
    repository.seed([buildPendingImport()]);
    await pumpEventQueue();
    expect(cubit.state.items, hasLength(1));
  });

  test('toString is redacted', () async {
    repository.seed([buildPendingImport(merchant: 'Secret Shop')]);
    await cubit.open();
    expect(cubit.state.toString(), isNot(contains('Secret')));
  });

  group('scan state (T120)', () {
    late HubScanDeps deps;

    BankMessagesCubit buildWith({
      bool capability = true,
      bool enabled = true,
      SmsPermissionStatus permission = SmsPermissionStatus.granted,
      ScanWindow window = ScanWindow.days30,
    }) {
      deps = HubScanDeps(
        capability: capability,
        settings: FakeSmsImportSettingsRepository(
          settings: SmsImportSettings(isEnabled: enabled, scanWindow: window),
        ),
      );
      deps.permissions.status = permission;
      return buildBankMessagesCubit(repository, clock, deps: deps);
    }

    Future<void> reopen(BankMessagesCubit next) async {
      await cubit.close();
      cubit = next;
      await cubit.open();
    }

    tearDown(() => deps.settings.close());

    test(
      'without the capability nothing about scanning is read or shown',
      () async {
        await reopen(buildWith(capability: false));
        expect(cubit.state.scanAvailable, isFalse);
        expect(cubit.state.canScan, isFalse);
        expect(cubit.state.bannerStatus, isNull);
        expect(cubit.state.showTurnOn, isFalse);
        expect(deps.permissions.statusChecks, 0);
        await cubit.scan();
        expect(deps.scan.calls, 0);
        expect(deps.permissions.requests, 0);
      },
    );

    test('on and granted: Scan now runs the saved window', () async {
      await reopen(buildWith(window: ScanWindow.days7));
      expect(cubit.state.canScan, isTrue);
      expect(cubit.state.bannerStatus, isNull);
      deps.scan.result = Right(
        ScanSummary(
          scanned: 5,
          createdPending: 3,
          ready: 2,
          needsReview: 1,
          nonTransactional: 2,
          skipped: [
            SkippedEntry(
              reason: SkipReason.notRecognized,
              bankId: 'nbe',
              receivedAt: DateTime(2026, 4, 9),
            ),
          ],
        ),
      );
      await cubit.scan();
      expect(deps.scan.windows, [ScanWindow.days7]);
      expect(cubit.state.scanning, isFalse);
      expect(cubit.state.scanSummary!.scanned, 5);
      expect(cubit.state.scanSummary!.skipped, hasLength(1));
      expect(deps.permissions.requests, 0);
      cubit.dismissScanSummary();
      expect(cubit.state.scanSummary, isNull);
    });

    test(
      'progress is reported, a second tap is ignored, Cancel stops it',
      () async {
        await reopen(buildWith());
        deps.scan
          ..progress = [10, 20]
          ..gate = Completer<void>();
        final running = cubit.scan();
        await pumpEventQueue();
        expect(cubit.state.scanning, isTrue);
        expect(cubit.state.scanProcessed, 20);
        await cubit.scan();
        expect(deps.scan.calls, 1);
        cubit.cancelScan();
        expect(deps.scan.lastToken!.isCancelled, isTrue);
        deps.scan.gate!.complete();
        await running;
        expect(cubit.state.scanning, isFalse);
        expect(cubit.state.scanSummary!.cancelled, isTrue);
      },
    );

    test('a failed scan keeps the processed count and the list', () async {
      await reopen(buildWith());
      deps.scan
        ..progress = [4]
        ..result = const Left(SmsInboxQueryFailure());
      await cubit.scan();
      expect(cubit.state.scanFailure, isA<SmsInboxQueryFailure>());
      expect(cubit.state.scanProcessed, 4);
      expect(cubit.state.status, BankMessagesStatus.empty);
    });

    test('a permission failure during the scan shows its banner', () async {
      await reopen(buildWith());
      deps.scan.result = const Left(
        SmsPermissionFailure(SmsPermissionStatus.revoked),
      );
      await cubit.scan();
      expect(cubit.state.permission, SmsPermissionStatus.revoked);
      expect(cubit.state.bannerStatus, SmsPermissionStatus.revoked);
      expect(cubit.state.canScan, isFalse);
    });

    test('revocation is picked up by a prompt-free refresh (resume)', () async {
      await reopen(buildWith());
      deps.permissions.status = SmsPermissionStatus.revoked;
      await cubit.refreshScanContext();
      expect(cubit.state.bannerStatus, SmsPermissionStatus.revoked);
      expect(deps.permissions.requests, 0);
    });

    test(
      'off: the Turn on card, unless Android blocks the permission',
      () async {
        await reopen(
          buildWith(enabled: false, permission: SmsPermissionStatus.denied),
        );
        expect(cubit.state.showTurnOn, isTrue);
        expect(cubit.state.bannerStatus, isNull);
        await reopen(
          buildWith(
            enabled: false,
            permission: SmsPermissionStatus.restrictedBlocked,
          ),
        );
        expect(cubit.state.showTurnOn, isFalse);
        expect(cubit.state.bannerStatus, SmsPermissionStatus.restrictedBlocked);
      },
    );

    test('Open App info prompts nothing', () async {
      await reopen(
        buildWith(permission: SmsPermissionStatus.permanentlyDenied),
      );
      await cubit.openAppInfo();
      expect(deps.permissions.appInfoOpens, 1);
      expect(deps.permissions.requests, 0);
    });

    test('closing cancels a running scan', () async {
      await reopen(buildWith());
      deps.scan.gate = Completer<void>();
      unawaited(cubit.scan());
      await pumpEventQueue();
      await cubit.close();
      expect(deps.scan.lastToken!.isCancelled, isTrue);
      deps.scan.gate!.complete();
    });

    test('scan after close is a no-op (no emit after close)', () async {
      await reopen(buildWith());
      await cubit.close();
      await expectLater(cubit.scan(), completes);
      expect(deps.scan.calls, 0);
    });

    test('the state with a summary prints no bank or date', () async {
      await reopen(buildWith());
      deps.scan.result = Right(
        ScanSummary(
          skipped: [
            SkippedEntry(
              reason: SkipReason.noAmount,
              bankId: 'secretbank',
              receivedAt: DateTime(2026, 4, 9),
            ),
          ],
        ),
      );
      await cubit.scan();
      expect(cubit.state.toString(), isNot(contains('secretbank')));
    });
  });
}

class _FailingWatch extends FakeSmsImportRepository {
  _FailingWatch(FixedClock clock) : super(clock: clock);

  bool fail = true;

  @override
  Stream<Either<Failure, List<Never>>> watchPending() => fail
      ? Stream.value(const Left(CacheFailure('sms_import_store_failed')))
      : Stream.value(const Right([]));
}
