import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/sms_import/helpers/pipeline_harness.dart';
import '../features/sms_import/helpers/sms_fixture_loader.dart';

/// Counts the SELECT statements that read the bank-message staging tables,
/// to prove the exact-tier duplicate lookup is batched per page and not
/// run per message. It never looks at bound values.
class _SelectCounter extends QueryInterceptor {
  int stagingSelects = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('sms_import_tombstones') ||
        statement.contains('pending_sms_imports')) {
      stagingSelects++;
    }
    return executor.runSelect(statement, args);
  }
}

/// T154 — SC-005 at test scale: one user-initiated scan of 500 inbox
/// messages through the real pipeline (the shipped parser registry, the
/// frozen fingerprint normalizer, HMAC hashing, AES-GCM sealing and the
/// real staging repository on an in-memory SQLite database). Only the
/// inbox gateway, permission and lifecycle are fakes.
///
/// The 500 rows mix recognized transactions from every shipped profile,
/// bank noise (OTP, promo, declined, balance) and wording no template
/// reads, all from allow-listed senders. Another 150 rows from senders no
/// profile knows sit in the same inbox; the gateway's sender filter drops
/// them, as the platform query does.
///
/// Like `ocr_batch_scale_test.dart`, the bound is a regression alarm on
/// developer/CI hardware (an accidental O(n²) or a per-row round trip),
/// not the device benchmark: that is T166
/// (`integration_test/sms_ingest_device_benchmark_test.dart`).
void main() {
  late _SelectCounter counter;
  late PipelineHarness h;

  setUp(() async {
    counter = _SelectCounter();
    h = PipelineHarness(
      database: AppDatabase.forTesting(
        NativeDatabase.memory().interceptWith(counter),
      ),
    );
    await h.open();
  });
  tearDown(() => h.close());

  /// Replaces the first ASCII money amount of [text] so every generated
  /// body is distinct (distinct fingerprints), keeping the template shape.
  final amount = RegExp(r'\d{1,3}(?:,\d{3})*\.\d{2}');
  String vary(String text, int i) => text.replaceFirst(
    amount,
    '${1 + i % 900},${(i * 7 % 1000).toString().padLeft(3, '0')}.'
    '${(i % 100).toString().padLeft(2, '0')}',
  );

  /// 500 allow-listed rows and 150 unknown-sender rows over the last day.
  List<InboxSmsMessage> inbox() {
    final bank = loadSmsFixtures()
        .where((f) => f.isBank && f.sender != null)
        .toList();
    expect(bank, isNotEmpty);
    final unreadable = [
      'Dear customer, your e-statement is now available in the app.',
      'Your request has been received and is being processed.',
      'Service update: our branches will open at 10 am tomorrow.',
    ];
    final rows = <InboxSmsMessage>[];
    final start = DateTime(2026, 3, 5, 12);
    for (var i = 0; i < 500; i++) {
      final fixture = bank[i % bank.length];
      final body = i % 10 == 9
          ? '${fixture.sender}: ${unreadable[i % unreadable.length]} #$i'
          : vary(fixture.text, i);
      rows.add(
        InboxSmsMessage(
          id: i + 1,
          address: fixture.sender!,
          date: start.add(Duration(minutes: i)),
          body: body,
        ),
      );
    }
    for (var i = 0; i < 150; i++) {
      rows.add(
        InboxSmsMessage(
          id: 1000 + i,
          address: i.isEven ? 'EXAMPLESHOP' : 'Vodafone',
          date: start.add(Duration(minutes: i, seconds: 30)),
          body: 'Your order of EGP ${100 + i}.00 has shipped. Ref $i',
        ),
      );
    }
    return rows;
  }

  test('a 500-message scan stays within 5 s; the duplicate lookup is one '
      'batch per page', () async {
    final rows = inbox();

    final stopwatch = Stopwatch()..start();
    final summary = await h.scan(rows);
    stopwatch.stop();

    expect(summary.cancelled, isFalse);
    expect(summary.scanned, 500, reason: 'unknown senders never read');
    expect(summary.createdPending, greaterThan(250));
    expect(
      summary.nonTransactional + summary.unreadable,
      greaterThan(50),
      reason: 'noise and unreadable wording are part of the load',
    );
    expect(await h.savedRecords(), 0, reason: 'a scan never saves money');
    // ignore: avoid_print
    print(
      'SMS ingest scale: 500 messages in ${stopwatch.elapsedMilliseconds} ms '
      '(${summary.createdPending} staged, ${summary.alreadyKnown} known, '
      '${summary.nonTransactional} noise, ${summary.unreadable} unreadable)',
    );
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason:
          'a 500-message scan over 5 s means a per-row round trip or an '
          'O(n²) crept into the pipeline (SC-005)',
    );
  });

  test('re-scanning the same 500 messages stages nothing, reads the '
      'staging tables a bounded number of times per page, and stays '
      'within 5 s', () async {
    final rows = inbox();
    final first = await h.scan(rows);
    final staged = (await h.rows()).length;
    expect(staged, greaterThanOrEqualTo(first.createdPending));

    counter.stagingSelects = 0;
    final stopwatch = Stopwatch()..start();
    final again = await h.scan(rows);
    stopwatch.stop();

    expect(again.createdPending, 0);
    expect(again.alreadyKnown, greaterThanOrEqualTo(first.createdPending));
    expect((await h.rows()).length, staged);
    final pages = (500 / RunInboxScan.pageSize).ceil();
    // ignore: avoid_print
    print(
      'SMS ingest re-scan: 500 known messages in '
      '${stopwatch.elapsedMilliseconds} ms, '
      '${counter.stagingSelects} staging SELECTs over $pages pages',
    );
    expect(
      counter.stagingSelects,
      lessThanOrEqualTo(pages * 8),
      reason: 'the exact-tier lookup must be batched per page, not per row',
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}
