import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/data_privacy/domain/services/export_directory_provider.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/data/platform/in_memory_review_lease_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/reparse_pending.dart';
import 'package:daftary/features/sms_import/domain/usecases/show_original_message.dart';
import 'package:daftary/features/sms_import/domain/usecases/undo_ignore.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/catalogue_fixtures.dart';
import '../../../helpers/test_daos.dart';
import '../helpers/fakes.dart';
import '../helpers/pipeline_harness.dart';
import '../helpers/review_harness.dart';

// ---------------------------------------------------------------------------
// The sentinel message (research.md "Privacy leak test", quickstart §91):
// a unique merchant, amount 987654.32, card 4111111111111111 and reference
// 998877665544, plus a raw-only tail that no parser field ever reads. All
// synthetic.
// ---------------------------------------------------------------------------

const String _card = '4111111111111111';
const String _cardHead = '411111111111';
const String _ref = '998877665544';
const String _tail = 'QZSENTINELQZ';
const String _merchant = 'Zqxv Merchant';
const String _merchantLower = 'zqxv';
const String _amountText = '987654.32';
const String _amountGrouped = '987,654.32';
const String _amountMinor = '98765432';

/// The NBE-phrased sentinel (the NBE profile reads the merchant and the
/// amount; the long card number, the reference and the tail are extra).
String _nbeSentinel(String date) =>
    'NBE: Your card ending 4821 was charged EGP $_amountText at $_merchant '
    'on $date at 14:30. Ref $_ref card $_card $_tail';

/// The generic-phrased sentinel, as pasted or shared.
String _genericSentinel(String date) =>
    'Purchase of EGP $_amountText at $_merchant on $date 10:15 with card '
    '$_card. Ref: $_ref $_tail';

/// Never anywhere: logs, toString, any table cell, the outbox, the CSV.
const List<String> _neverAnywhere = [_card, _cardHead, _ref, _tail];

/// Content that may exist only as a parsed or confirmed field, never in a
/// log line or a `toString`.
const List<String> _neverLogged = [
  ..._neverAnywhere,
  _merchant,
  _merchantLower,
  _amountText,
  _amountGrouped,
  _amountMinor,
];

/// The (table, column) cells allowed to hold the merchant text: the
/// pending row's parsed fields (FR-075: parsed fields are ordinary local
/// data) and the learned merchant key (data-model §3.4).
const Set<(String, String)> _merchantCells = {
  ('pending_sms_imports', 'merchant'),
  ('pending_sms_imports', 'merchant_key'),
  ('sms_merchant_category_mappings', 'merchant_key'),
};

class _FixedDirectory implements ExportDirectoryProvider {
  _FixedDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

/// The shipped registry with every rule version bumped by one, so a
/// re-parse runs.
SmsParserRegistry _bumped() {
  BankProfile bump(BankProfile p) => BankProfile(
    id: p.id,
    version: p.version + 1,
    senders: p.senders,
    signatures: p.signatures,
    templates: p.templates,
    nonTransactionalRules: p.nonTransactionalRules,
    merchantKeywordRules: p.merchantKeywordRules,
    ownAccountKeywords: p.ownAccountKeywords,
    cardSettlementKeywords: p.cardSettlementKeywords,
    messageStart: p.messageStart,
    maskThreshold: p.maskThreshold,
    defaultCurrency: p.defaultCurrency,
    dateOrder: p.dateOrder,
    isGeneric: p.isGeneric,
    refIsUnique: p.refIsUnique,
    verified: p.verified,
  );
  final standard = SmsParserRegistry.standard;
  return SmsParserRegistry(
    profiles: [for (final p in standard.profiles) bump(p)],
    generic: bump(standard.generic),
  );
}

/// T152 — the privacy sentinel leak suite (FR-031a, FR-074a, FR-075,
/// FR-088, FR-100/101; research.md "Privacy leak test"). The sentinel goes
/// through scan (fake gateway), paste, share, review (open, Show original,
/// Add), Ignore, Undo, "It's the same", expiry and re-parse over the real
/// pipeline, crypto and database. Then:
/// - no sentinel in captured `debugPrint`, `Zone` print or
///   `FlutterError.onError` output, with every failure the flows return
///   reported as a crash report would be;
/// - no sentinel in any outbox payload or in the CSV export;
/// - `SELECT *` over every table: the card, the reference and the tail are
///   in no TEXT or BLOB cell; the merchant only in its parsed/learned
///   cells; amounts only as confirmed or parsed fields;
/// - `raw_blob` is NULL after every decision and never plaintext while
///   pending (it opens only through the vault, masked);
/// - `AppDatabase` is never opened with `logStatements`;
/// - every value type's `toString` is redacted.
void main() {
  late PipelineHarness h;
  late List<String> logs;
  late List<String> strings;
  late DebugPrintCallback savedDebugPrint;
  late FlutterExceptionHandler? savedOnError;
  late Directory exportDir;

  setUp(() async {
    h = PipelineHarness(now: DateTime(2026, 3, 6, 12));
    await h.open();
    logs = [];
    strings = [];
    exportDir = Directory.systemTemp.createTempSync('sms_leak_suite');
    savedDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    savedOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      logs
        ..add(details.toString())
        ..add(details.exceptionAsString());
    };
  });

  tearDown(() async {
    debugPrint = savedDebugPrint;
    FlutterError.onError = savedOnError;
    await h.close();
    if (exportDir.existsSync()) exportDir.deleteSync(recursive: true);
  });

  /// Runs [body] with `print` captured and any uncaught error forwarded
  /// to `FlutterError.onError`, as a crash reporter would see it.
  Future<void> captured(Future<void> Function() body) async {
    final done = Completer<void>();
    runZonedGuarded(
      () => body().then(done.complete, onError: done.completeError),
      (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
        if (!done.isCompleted) done.completeError(error, stack);
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => logs.add(line),
      ),
    );
    await done.future;
  }

  /// What a crash report would carry for [result] (a failure), plus its
  /// `toString` for the redaction check.
  T observe<T>(Either<Failure, T> result) {
    result.match((failure) {
      strings.add(failure.toString());
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: failure,
          stack: StackTrace.current,
          library: 'sms_import leak suite',
        ),
      );
    }, (value) => strings.add(value.toString()));
    return result.getOrElse((f) => fail('unexpected failure: $f'));
  }

  ImportReviewCubit reviewCubit() {
    final people = PeopleRepositoryImpl(
      testPeopleDao(h.database),
      const FindPossibleDuplicatePerson(),
      h.database,
    );
    final cubit = ImportReviewCubit(
      GetPendingImport(h.repository),
      GetPendingImports(h.repository),
      h.add,
      h.checkDuplicates,
      ShowOriginalMessage(h.repository),
      InMemoryReviewLeaseRegistry(),
      GetCategories(CategoryRepositoryImpl(testFinanceDao(h.database))),
      people,
      CreatePerson(people),
      h.closeAsDuplicate,
    );
    cubit.stream.listen((ImportReviewState s) => strings.add(s.toString()));
    return cubit;
  }

  // ------------------------------------------------------------- checks

  /// Bytes of [needle] inside [haystack].
  bool containsBytes(Uint8List haystack, List<int> needle) {
    outer:
    for (var i = 0; i + needle.length <= haystack.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  /// Every sentinel appearing in [text], case-insensitive.
  List<String> hits(String text, List<String> sentinels) => [
    for (final s in sentinels)
      if (text.toLowerCase().contains(s.toLowerCase())) s,
  ];

  /// `SELECT *` over every table; TEXT and BLOB cells.
  Future<void> expectCleanDatabase(String stage) async {
    final tables = await h.database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    expect(tables.length, greaterThan(30), reason: 'every table is scanned');
    for (final t in tables) {
      final table = t.read<String>('name');
      final rows = await h.database
          .customSelect('SELECT * FROM "$table"')
          .get();
      for (final row in rows) {
        for (final MapEntry(key: column, value: value) in row.data.entries) {
          final where = '$stage: $table.$column';
          if (value is String) {
            expect(hits(value, _neverAnywhere), isEmpty, reason: where);
            expect(
              hits(value, [_amountText, _amountGrouped]),
              isEmpty,
              reason: where,
            );
            if (!_merchantCells.contains((table, column))) {
              expect(hits(value, [_merchantLower]), isEmpty, reason: where);
            }
            if (table != 'sync_outbox') {
              expect(hits(value, [_amountMinor]), isEmpty, reason: where);
            }
          } else if (value is Uint8List) {
            for (final s in _neverLogged) {
              expect(
                containsBytes(value, utf8.encode(s)),
                isFalse,
                reason: '$where (BLOB holds plaintext "$s")',
              );
            }
          }
        }
      }
    }
  }

  /// `raw_blob` is NULL for every decided row, and every pending row's
  /// blob is ciphertext that opens (through the vault) to masked text.
  Future<void> expectBlobs(String stage) async {
    for (final row in await h.rows()) {
      if (row.status != 'pending') {
        expect(row.rawBlob, isNull, reason: '$stage: ${row.status} row');
        continue;
      }
      final blob = row.rawBlob;
      expect(blob, isNotNull, reason: '$stage: pending row has its original');
      expect(containsBytes(blob!, utf8.encode(_tail)), isFalse);
      expect(containsBytes(blob, utf8.encode(_merchant)), isFalse);
      // The opened text is the feature's own display value, not a log or
      // a toString, so it is not added to the observed strings.
      final original = (await h.repository.openOriginal(
        row.id,
      )).getOrElse((f) => fail('$stage: the original does not open: $f'));
      expect(original, contains(_tail), reason: 'opens with the vault');
      expect(
        hits(original, [_card, _cardHead, _ref]),
        isEmpty,
        reason: '$stage: the sealed original is masked',
      );
    }
  }

  void expectCleanLogs(String stage) {
    for (final line in logs) {
      expect(hits(line, _neverLogged), isEmpty, reason: '$stage log: $line');
    }
    for (final line in strings) {
      expect(
        hits(line, _neverLogged),
        isEmpty,
        reason: '$stage toString: $line',
      );
    }
  }

  Future<void> expectCleanOutbox(String stage) async {
    final rows = await h.database.select(h.database.syncOutboxEntries).get();
    for (final row in rows) {
      final payload = row.payloadJson;
      expect(hits(payload, _neverAnywhere), isEmpty, reason: stage);
      expect(
        hits(payload, [_merchantLower, _amountText, _amountGrouped]),
        isEmpty,
        reason: '$stage outbox ${row.entityType}',
      );
    }
  }

  Future<String> exportCsv() async {
    final env = await CatalogueEnv.open(database: h.database);
    final export = ExportUserData(
      env.people,
      env.transactions,
      env.finance,
      env.categories,
      SettingsRepositoryImpl(SettingsDao(h.database)),
      _FixedDirectory(exportDir),
      env.occasions,
      env.budgets,
      env.savings,
      env.currency,
    );
    final result = observe(await export());
    return File(result.filePath).readAsStringSync();
  }

  Future<void> expectEverythingClean(String stage) async {
    await expectBlobs(stage);
    await expectCleanDatabase(stage);
    await expectCleanOutbox(stage);
    expectCleanLogs(stage);
  }

  // -------------------------------------------------------------- tests

  test('positive controls: the capture and the matchers see a leak', () async {
    await captured(() async {
      debugPrint('x $_card');
      // ignore: avoid_print
      print('y $_tail');
      FlutterError.reportError(FlutterErrorDetails(exception: 'z $_ref'));
    });
    expect(logs.where((l) => hits(l, _neverLogged).isNotEmpty), hasLength(4));
    expect(
      containsBytes(
        Uint8List.fromList(utf8.encode('a$_tail')),
        utf8.encode(_tail),
      ),
      isTrue,
    );
    logs.clear();
  });

  test(
    'scan -> review (open, Show original) -> Add: nothing leaks; the '
    'original is purged; outbox and CSV carry only confirmed fields',
    () async {
      await captured(() async {
        final summary = await h.scan([inboxRow(1, _nbeSentinel('05/03/2026'))]);
        strings.add(summary.toString());
        expect(summary.createdPending, 1);
        final item = (await h.pending()).single;
        strings.add(item.toString());
        await expectEverythingClean('scan, pending');

        final cubit = reviewCubit();
        try {
          await cubit.load(item.id);
          expect(cubit.state.status, ImportReviewStatus.ready);
          await cubit.toggleOriginal();
          expect(cubit.state.original, isNotNull);
          expect(cubit.state.original!.text, contains(_tail));
          expect(cubit.state.original!.text, isNot(contains(_card)));
          // A category other than the suggestion: the merchant is learned.
          cubit.categorySelected('seed_groceries');
          strings.add(cubit.state.draft.toString());
          await cubit.add();
          expect(cubit.state.status, ImportReviewStatus.success);
        } finally {
          await cubit.close();
        }

        // A second Add of the decided item fails, content-free.
        final again = await h.add(
          pendingId: item.id,
          draft: ReviewDraft(
            type: SuggestedRecordType.expense,
            amountMinorUnits: item.amount!.minorUnits,
            currencyCode: 'EGP',
            date: item.occurredOn,
            categoryId: 'seed_groceries',
          ),
        );
        expect(again.isLeft(), isTrue);
        again.match((f) {
          strings.add(f.toString());
          FlutterError.reportError(FlutterErrorDetails(exception: f));
        }, (_) {});
        // Show original after the decision is unavailable.
        expect(
          (await ShowOriginalMessage(h.repository)(item.id)).isLeft(),
          isTrue,
        );
      });

      final entries = await h.database.select(h.database.financeEntries).get();
      expect(entries.single.amountMinorUnits, 98765432);
      expect(entries.single.note, isNull, reason: 'the merchant is not a note');
      final outbox = await h.database
          .select(h.database.syncOutboxEntries)
          .get();
      final queued = outbox.where((r) => r.entityId == entries.single.id);
      expect(queued, isNotEmpty, reason: 'the Add queued its record for sync');
      for (final row in queued) {
        final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        // Only user-confirmed fields plus the provenance (FR-088).
        expect(payload['note'], isNull);
        expect(payload['import_source'], 'sms');
        expect(payload.keys, isNot(contains('merchant')));
        expect(payload.keys, isNot(contains('fingerprint')));
      }
      await expectEverythingClean('after Add');

      final csv = await exportCsv();
      expect(hits(csv, [..._neverAnywhere, _merchantLower]), isEmpty);
      expectCleanLogs('after export');
    },
  );

  test('paste -> Ignore -> Undo, share -> "It\'s the same": originals are '
      'purged and nothing leaks', () async {
    await captured(() async {
      final pasted = await h.pasteText(_genericSentinel('01/03/2026'));
      strings.add(pasted.toString());
      final shared = await h.shareText(_genericSentinel('03/03/2026'));
      strings.add(shared.toString());
      strings.add(SharedText(text: _genericSentinel('03/03/2026')).toString());
      expect(pasted.newIds, hasLength(1));
      expect(shared.newIds, hasLength(1));
      await expectEverythingClean('paste+share, pending');

      observe(await IgnoreImport(h.repository)(ids: {pasted.newIds.single}));
      await expectEverythingClean('after Ignore');
      observe(await UndoIgnore(h.repository)(pasted.newIds.single));
      await expectEverythingClean('after Undo');

      observe(await h.closeAsDuplicate(shared.newIds.single));
      await expectEverythingClean('after "It\'s the same"');
      // Deciding twice: a content-free failure, reported as a crash.
      final twice = await h.closeAsDuplicate(shared.newIds.single);
      expect(twice.isLeft(), isTrue);
      twice.match((f) {
        strings.add(f.toString());
        FlutterError.reportError(FlutterErrorDetails(exception: f));
      }, (_) {});
    });
    expect(await h.pending(), isEmpty);
    await expectEverythingClean('end');
  });

  test('expiry purges the original; nothing leaks', () async {
    await captured(() async {
      final pasted = await h.pasteText(_genericSentinel('02/03/2026'));
      expect(pasted.newIds, hasLength(1));
      h.clock.advance(const Duration(days: 31));
      expect(observe(await ExpirePendingImports(h.repository, h.clock)()), 1);
    });
    final row = (await h.rows()).single;
    expect(row.status, 'expired');
    expect(row.rawBlob, isNull);
    await expectEverythingClean('after expiry');
  });

  test('a re-parse after a rule update keeps the original sealed and leaks '
      'nothing', () async {
    await captured(() async {
      await h.scan([inboxRow(1, _nbeSentinel('04/03/2026'))]);
      await h.settings.setRulesSeen(h.parser.currentVersions);
      final parser = RuleBasedSmsParser(clock: h.clock, registry: _bumped());
      final reparse = ReparsePending(
        h.repository,
        h.settings,
        parser,
        ParseMessages(parser),
        LoadParserOptions(
          h.settings,
          CategoryRepositoryImpl(testFinanceDao(h.database)),
          FakePeopleRepository(const []),
        ),
        FakeReviewLeaseRegistry(),
      );
      expect(observe(await reparse()), 1);
      // The parse result itself is redacted.
      final parsed = parser.parse(
        SmsParseInput(
          rawText: _nbeSentinel('04/03/2026'),
          source: SmsSource.inboxScan,
          sender: 'NBE',
        ),
      );
      strings
        ..add(parsed.toString())
        ..add(
          SmsParseInput(
            rawText: _nbeSentinel('04/03/2026'),
            source: SmsSource.inboxScan,
          ).toString(),
        )
        ..add(
          RawIncoming(
            text: _nbeSentinel('04/03/2026'),
            receivedAt: h.clock.now(),
          ).toString(),
        );
    });
    final row = (await h.rows()).single;
    expect(row.ruleVersion, 'nbe@2');
    expect(row.rawBlob, isNotNull);
    await expectEverythingClean('after re-parse');
  });

  test('AppDatabase is never opened with logStatements', () {
    final hitsInLib = <String>[];
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      if (file.readAsStringSync().contains('logStatements')) {
        hitsInLib.add(file.path);
      }
    }
    expect(hitsInLib, isEmpty);
    final database = File(
      'lib/core/database/app_database.dart',
    ).readAsStringSync();
    expect(database, contains('NativeDatabase.createInBackground(dbFile)'));
  });
}
