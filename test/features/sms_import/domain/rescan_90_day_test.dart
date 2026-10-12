import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/fakes.dart';
import '../helpers/pipeline_harness.dart';

// Synthetic NBE-phrased messages (invented names and references; no real
// card or phone numbers), all received on day 0.
const _purchase =
    'NBE: Your card ending 4821 was charged EGP 250.00 at Example Market on '
    '10/01/2026 at 08:30. Available balance EGP 3,200.00';
const _bill =
    'NBE: Bill payment of EGP 320.50 to Example Electricity was debited from '
    'your account ****4821 on 10/01/2026.';
const _transfer =
    'NBE: Transfer of EGP 1,500.00 to Ahmed Example from your account '
    '****4821 on 10/01/2026. Ref 7731902';
const _salary =
    'NBE: Salary of EGP 15,000.00 has been credited to your account ****4821 '
    'on 10/01/2026.';

/// T168 — SC-014 (FR-059, FR-066, FR-067): with a fixed clock, decide one
/// item each way (Add, Ignore, "It's the same", expiry), let the decided
/// rows be purged (30 days), then at day 90 re-scan the very same inbox
/// with the 90-day window, re-paste, re-share and run a catch-up: zero new
/// pending items, no new record, and the tombstones stay until
/// `purge_after` (created + 97 days). Real parser, crypto and database;
/// only the platform edges are fakes. Every value is synthetic.
void main() {
  late PipelineHarness h;
  late DateTime day0;
  late List<InboxSmsMessage> inbox;

  setUp(() async {
    day0 = DateTime(2026, 1, 10, 12);
    h = PipelineHarness(now: day0);
    await h.open();
    inbox = [
      for (final (i, body) in [_purchase, _bill, _transfer, _salary].indexed)
        InboxSmsMessage(
          id: i + 1,
          address: 'NBE',
          date: DateTime(2026, 1, 10, 9, i),
          body: body,
        ),
    ];
  });
  tearDown(() => h.close());

  /// "Day [n]" on the calendar, at [hour]:[minute] local time.
  DateTime day(int n, {int hour = 12, int minute = 0}) =>
      DateTime(day0.year, day0.month, day0.day + n, hour, minute);

  /// A user-initiated scan of [inbox] with the given window, at the
  /// harness clock.
  Future<ScanSummary> scan(ScanWindow window) async {
    final gateway = FakeSmsInboxGateway(rows: inbox);
    final capability = GetSmsCapability(gateway);
    final result = await RunInboxScan(
      capability,
      GetSmsPermissionStatus(
        capability,
        FakeSmsPermissionService(status: SmsPermissionStatus.granted),
      ),
      h.settings,
      h.parser,
      gateway,
      h.ingestion,
      h.coordinator,
      FakeLifecycle(),
      h.clock,
    )(window: window, token: ScanCancellationToken());
    return result.getOrElse((f) => fail('scan failed: $f'));
  }

  Future<int> maintain() async => (await ExpirePendingImports(
    h.repository,
    h.clock,
  )()).getOrElse((f) => fail('maintenance failed: $f'));

  Future<List<int>> purgeAfters() async => [
    for (final row
        in await h.database.select(h.database.smsImportTombstones).get())
      row.purgeAfter,
  ]..sort();

  Future<Map<String, int>> tombstoneOutcomes() async {
    final counts = <String, int>{};
    for (final row
        in await h.database.select(h.database.smsImportTombstones).get()) {
      counts[row.outcome] = (counts[row.outcome] ?? 0) + 1;
    }
    return counts;
  }

  PendingSmsImport byKind(List<PendingSmsImport> items, SmsKind kind) =>
      items.singleWhere((i) => i.kind == kind);

  /// Day 0: scan, then Add / Ignore / "It's the same"; the salary is left
  /// to expire. Day 30: it expires. Day 61: every decided row is purged.
  Future<void> decideEverything() async {
    final first = await scan(ScanWindow.days90);
    expect(first.createdPending, 4);
    final items = await h.pending();

    final purchase = byKind(items, SmsKind.cardPurchase);
    final added = await h.add(
      pendingId: purchase.id,
      draft: ReviewDraft(
        type: SuggestedRecordType.expense,
        amountMinorUnits: purchase.amount!.minorUnits,
        currencyCode: purchase.amount!.currency.code,
        date: purchase.occurredOn,
        categoryId: 'seed_groceries',
      ),
    );
    expect(added.isRight(), isTrue, reason: '${added.getLeft()}');
    expect(
      await IgnoreImport(h.repository)(
        ids: {byKind(items, SmsKind.billPayment).id},
      ),
      const Right<Failure, Unit>(unit),
    );
    expect(
      await h.closeAsDuplicate(byKind(items, SmsKind.transferOut).id),
      const Right<Failure, Unit>(unit),
    );
    expect(await h.pending(), hasLength(1));

    // Day 30 + 1 h: the untouched salary expires.
    h.clock.current = day(30, hour: 13);
    expect(await maintain(), 1);
    expect(await h.pending(), isEmpty);

    // Day 61: every decided row is past its 30 days and is purged.
    h.clock.current = day(61);
    await maintain();
    expect(await h.rows(), isEmpty, reason: 'decided rows purged');
  }

  test('a day-90 re-scan, re-paste, re-share and catch-up of the same '
      'messages resurface zero items', () async {
    await decideEverything();
    expect(await tombstoneOutcomes(), {
      'added': 1,
      'ignored': 1,
      'duplicate': 1,
      'expired': 1,
    });

    // Day 90, early enough that day 0's messages are inside the window.
    h.clock.current = day(90, hour: 8, minute: 30);
    await maintain();
    expect(await purgeAfters(), hasLength(4), reason: 'tombstones remain');

    final rescan = await scan(ScanWindow.days90);
    expect(rescan.scanned, 4, reason: 'the inbox still holds all four');
    expect(rescan.createdPending, 0);
    expect(rescan.alreadyKnown, 4);

    for (final body in [_purchase, _bill, _transfer, _salary]) {
      expect((await h.pasteText(body)).newIds, isEmpty, reason: 'paste');
      expect((await h.shareText(body)).newIds, isEmpty, reason: 'share');
    }
    expect((await h.catchUp(inbox)).createdPending, 0);

    expect(await h.pending(), isEmpty);
    expect(await h.rows(), isEmpty);
    expect(await h.savedRecords(), 1, reason: 'only the one Add');
    expect(await purgeAfters(), hasLength(4));
  });

  test('tombstones stay until purge_after (created + 97 days) and only '
      'then go', () async {
    await decideEverything();
    final dues = await purgeAfters();
    expect(dues, hasLength(4));
    // Three decided on day 0, the expiry on day 30.
    final earliest = DateTime.fromMillisecondsSinceEpoch(dues.first);
    expect(dues.where((d) => d == dues.first), hasLength(3));
    expect(
      earliest.difference(day0),
      greaterThanOrEqualTo(const Duration(days: 97)),
    );

    // One minute before purge_after: still all there.
    h.clock.current = earliest.subtract(const Duration(minutes: 1));
    await maintain();
    expect(await purgeAfters(), hasLength(4));

    // At purge_after: day 0's three go; the expiry's (day 30) stays.
    h.clock.current = earliest;
    await maintain();
    expect(await tombstoneOutcomes(), {'expired': 1});

    // By then day 0 is outside even the 90-day window: nothing is read.
    final outOfWindow = await scan(ScanWindow.days90);
    expect(outOfWindow.scanned, 0);
    expect(outOfWindow.createdPending, 0);
    expect(await h.savedRecords(), 1);
  });
}
