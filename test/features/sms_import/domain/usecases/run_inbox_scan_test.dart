import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
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
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockCategories extends Mock implements CategoryRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

/// A gateway that also returns rows from senders it was not asked for
/// (a misbehaving platform), so the defensive re-check can be observed.
class _LeakyGateway extends FakeSmsInboxGateway {
  _LeakyGateway({super.rows, required this.leaked});

  final InboxSmsMessage leaked;

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    final page = await super.queryInbox(
      senders: senders,
      afterDate: afterDate,
      afterId: afterId,
      limit: limit,
    );
    return page.map((rows) => [leaked, ...rows]);
  }
}

/// A gateway that runs [afterQuery] once, after its first page.
class _HookedGateway extends FakeSmsInboxGateway {
  _HookedGateway({super.rows, required this.afterQuery});

  final Future<void> Function() afterQuery;
  var _fired = false;

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    final page = await super.queryInbox(
      senders: senders,
      afterDate: afterDate,
      afterId: afterId,
      limit: limit,
    );
    if (!_fired) {
      _fired = true;
      await afterQuery();
    }
    return page;
  }
}

final DateTime _now = DateTime(2026, 3, 10, 12);

/// A synthetic NBE purchase (NBE profile phrasing; no real card number).
InboxSmsMessage _nbe(int id, {String address = 'NBE', DateTime? date}) =>
    InboxSmsMessage(
      id: id,
      address: address,
      date: date ?? DateTime(2026, 3, 5, 9).add(Duration(minutes: id)),
      body:
          'NBE: Your card ending 4821 was charged EGP $id.00 at Example '
          'Market on 05/03/2026.',
    );

void main() {
  setUpAll(() => registerFallbackValue(FinanceEntryType.expense));

  late FixedClock clock;
  late FakeSmsImportSettingsRepository settings;
  late FakeSmsImportRepository repository;
  late FakeSmsPermissionService permissions;
  late FakeLifecycle lifecycle;
  late ScanCoordinator coordinator;
  late RuleBasedSmsParser parser;
  late SmsIngestionService ingestion;
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
    coordinator = InMemoryScanCoordinator();
    parser = RuleBasedSmsParser(clock: clock);
    final categories = _MockCategories();
    final people = _MockPeople();
    when(() => categories.getCategories(type: any(named: 'type'))).thenAnswer(
      (invocation) async => Right([
        Category(
          id: 'seed_other',
          name: 'Other',
          type: invocation.namedArguments[#type] as FinanceEntryType,
          icon: 'other',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
    );
    when(
      () => people.searchActivePeople(),
    ).thenAnswer((_) async => const Right([]));
    ingestion = SmsIngestionService(
      ParseMessages(parser),
      LoadParserOptions(settings, categories, people),
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

  RunInboxScan build(FakeSmsInboxGateway gateway) {
    final capability = GetSmsCapability(gateway);
    return RunInboxScan(
      capability,
      GetSmsPermissionStatus(capability, permissions),
      settings,
      parser,
      gateway,
      ingestion,
      coordinator,
      lifecycle,
      clock,
    );
  }

  Future<Either<Failure, ScanSummary>> scan(
    FakeSmsInboxGateway gateway, {
    ScanWindow window = ScanWindow.days30,
    ScanCancellationToken? token,
    void Function(ScanProgress)? onProgress,
  }) => build(gateway)(
    window: window,
    token: token ?? ScanCancellationToken(),
    onProgress: onProgress,
  );

  ScanSummary summaryOf(Either<Failure, ScanSummary> result) =>
      result.getOrElse((f) => fail('unexpected $f'));

  group('allow-list', () {
    test('is the profile senders minus the muted senders, canonical', () async {
      await settings.muteSender('cib');
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      await scan(gateway);
      final senders = gateway.calls.first.senders;
      expect(senders, containsAll(['NBE', 'NBEGYPT', 'BANQUEMISR', 'AAIB']));
      expect(senders, isNot(contains('CIB')));
      expect(senders.toSet(), parser.allowedSenders.difference({'CIB'}));
      expect(senders, everyElement(matches(RegExp(r'^[A-Z0-9]+$'))));
    });

    test('an all-muted allow-list reads nothing', () async {
      for (final sender in parser.allowedSenders) {
        await settings.muteSender(sender);
      }
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final summary = summaryOf(await scan(gateway));
      expect(gateway.calls, isEmpty);
      expect(summary.createdPending, 0);
    });

    test('defensive sender re-check: a row from an unrequested sender is '
        'never ingested', () async {
      await settings.muteSender('NBEGYPT');
      final gateway = _LeakyGateway(
        rows: [_nbe(1)],
        leaked: _nbe(2, address: 'NBEGYPT'),
      );
      final summary = summaryOf(await scan(gateway));
      expect(summary.scanned, 1);
      expect(summary.createdPending, 1);
      expect(repository.rows.values.map((r) => r.senderId), ['NBE']);
    });
  });

  group('cursor and paging', () {
    test(
      'an explicit scan resets to now - window, not the stored cursor',
      () async {
        await settings.advanceCursor(date: DateTime(2026, 3, 9), id: 99);
        final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
        await scan(gateway, window: ScanWindow.days7);
        expect(gateway.calls.first.afterDate, DateTime(2026, 3, 3, 12));
        expect(gateway.calls.first.afterId, isNull);
        expect(gateway.calls.first.limit, RunInboxScan.pageSize);
      },
    );

    test('a short page ends the scan', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1), _nbe(2), _nbe(3)]);
      final summary = summaryOf(await scan(gateway));
      expect(gateway.calls, hasLength(1));
      expect(summary.scanned, 3);
      expect(summary.createdPending, 3);
      expect(summary.cancelled, isFalse);
    });

    test('a full page is followed by the next page after its last row; the '
        'stored cursor advances per page', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      final gateway = FakeSmsInboxGateway(rows: rows);
      final progress = <int>[];
      final summary = summaryOf(
        await scan(gateway, onProgress: (p) => progress.add(p.processed)),
      );
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls[1].afterDate, rows[199].date);
      expect(gateway.calls[1].afterId, 200);
      expect(summary.scanned, 205);
      expect(summary.createdPending, 205);
      expect(settings.settings.cursorDate, rows.last.date);
      expect(settings.settings.cursorId, 205);
      expect(progress.last, 205);
    });

    test('a re-scan adds nothing (fingerprints absorb the overlap)', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1), _nbe(2)]);
      await scan(gateway);
      final again = summaryOf(await scan(gateway));
      expect(again.createdPending, 0);
      expect(again.alreadyKnown, 2);
      expect(repository.rows, hasLength(2));
    });
  });

  group('cancellation (FR-007, FR-008a)', () {
    test('the lifecycle leaving resumed mid-scan stops further queries, '
        'keeps the items and the cursor of the finished page', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      final gateway = FakeSmsInboxGateway(rows: rows);
      lifecycle.pauseAfterChecks(1);
      final summary = summaryOf(await scan(gateway));
      expect(gateway.calls, hasLength(1));
      expect(summary.cancelled, isTrue);
      expect(summary.createdPending, 200);
      expect(repository.rows, hasLength(200));
      expect(settings.settings.cursorId, 200);
      expect(settings.settings.cursorDate, rows[199].date);
    });

    test('a paused app reads nothing at all', () async {
      lifecycle.pause();
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final summary = summaryOf(await scan(gateway));
      expect(gateway.calls, isEmpty);
      expect(summary.cancelled, isTrue);
    });

    test('turning the feature off between pages stops the scan', () async {
      final rows = [for (var i = 1; i <= 205; i++) _nbe(i)];
      final gateway = _HookedGateway(
        rows: rows,
        afterQuery: () async => settings.setEnabled(false),
      );
      final summary = summaryOf(await scan(gateway));
      expect(gateway.calls, hasLength(1));
      expect(summary.cancelled, isTrue);
      expect(repository.rows, hasLength(200));
    });

    test('a token cancelled before the scan starts reads nothing', () async {
      final token = ScanCancellationToken()..cancel();
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final summary = summaryOf(await scan(gateway, token: token));
      expect(gateway.calls, isEmpty);
      expect(summary.cancelled, isTrue);
      expect(repository.rows, isEmpty);
    });

    test('an explicit scan cancels a running catch-up and then runs '
        '(FR-013)', () async {
      final catchUpToken = ScanCancellationToken();
      final catchUp = coordinator.runExclusive(
        ScanKind.catchUp,
        catchUpToken,
        () async {
          while (!catchUpToken.isCancelled) {
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          return 'stopped';
        },
      );
      await Future<void>.delayed(Duration.zero);
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final summary = summaryOf(await scan(gateway));
      expect(await catchUp, 'stopped');
      expect(catchUpToken.isCancelled, isTrue);
      expect(summary.createdPending, 1);
      expect(coordinator.isRunning, isFalse);
    });
  });

  group('preconditions', () {
    test('capability off: refused, nothing read', () async {
      final gateway = FakeSmsInboxGateway(
        rows: [_nbe(1)],
        capability: SmsCapability.unavailable,
      );
      final result = await scan(gateway);
      expect(
        result.getLeft().toNullable(),
        isA<SmsCapabilityUnavailableFailure>(),
      );
      expect(gateway.calls, isEmpty);
      expect(permissions.statusChecks, 0);
    });

    test('disabled: refused, nothing read', () async {
      await settings.setEnabled(false);
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
      final result = await scan(gateway);
      expect(
        result.getLeft().toNullable(),
        const ScanNotAllowedFailure(ScanBlockReason.disabled),
      );
      expect(gateway.calls, isEmpty);
    });

    for (final status in [
      SmsPermissionStatus.denied,
      SmsPermissionStatus.permanentlyDenied,
      SmsPermissionStatus.restrictedBlocked,
      SmsPermissionStatus.revoked,
    ]) {
      test('permission $status: refused with that status, nothing read, '
          'never prompts', () async {
        permissions.status = status;
        final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
        final result = await scan(gateway);
        expect(result.getLeft().toNullable(), SmsPermissionFailure(status));
        expect(gateway.calls, isEmpty);
        expect(permissions.requests, 0);
      });
    }

    test('a query failure is returned; finished pages stay', () async {
      final gateway = FakeSmsInboxGateway(rows: [_nbe(1)])
        ..nextFailure = const SmsInboxQueryFailure();
      final result = await scan(gateway);
      expect(result.getLeft().toNullable(), const SmsInboxQueryFailure());
    });
  });

  test('sets lastScanAt (not lastCatchUpAt) and bumps the counters', () async {
    final gateway = FakeSmsInboxGateway(rows: [_nbe(1), _nbe(2)]);
    await scan(gateway);
    expect(settings.settings.lastScanAt, _now);
    expect(settings.settings.lastCatchUpAt, isNull);
    expect(settings.settings.scannedCount, 2);
    expect(settings.settings.recognizedCount, 2);
  });

  test('stages pending items only, from the inbox source, with the sender '
      'and receipt time', () async {
    final gateway = FakeSmsInboxGateway(rows: [_nbe(1)]);
    await scan(gateway);
    final row = repository.rows.values.single;
    expect(row.status, SmsImportStatus.pending);
    expect(row.source, SmsSource.inboxScan);
    expect(row.senderId, 'NBE');
    expect(row.bankId, 'nbe');
    expect(row.receivedAt, _nbe(1).date);
    expect(repository.confirmCalls, isEmpty);
  });
}
