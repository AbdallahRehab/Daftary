import 'dart:async';
import 'dart:io';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/ocr/data/datasources/ocr_dao.dart';
import 'package:daftary/features/ocr/data/parsing/candidate_entry_parser.dart';
import 'package:daftary/features/ocr/data/repositories/ocr_repository_impl.dart';
import 'package:daftary/features/ocr/domain/repositories/text_recognition_service.dart';
import 'package:daftary/features/ocr/domain/usecases/delete_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/watch_scan_detail.dart';
import 'package:daftary/features/ocr/domain/usecases/watch_scan_history.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_detail_cubit.dart';
import 'package:daftary/features/ocr/presentation/cubit/scan_history_cubit.dart';
import 'package:daftary/features/ocr/presentation/pages/scan_detail_page.dart';
import 'package:daftary/features/ocr/presentation/pages/scan_history_page.dart';
import 'package:daftary/features/ocr/presentation/widgets/scan_history_tile.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_transaction_audit_history.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/test_daos.dart';
import '../../transactions/helpers/currency_test_doubles.dart';

/// Reads the same two lines from any image.
class _FakeRecognition implements TextRecognitionService {
  @override
  Future<Either<Failure, RecognizedText>> recognize(String imagePath) async =>
      const Right(
        RecognizedText(
          blocks: [
            RecognizedBlock(
              lines: [
                RecognizedLine(text: 'Ahmed 500'),
                RecognizedLine(text: 'Mona 250'),
              ],
            ),
          ],
        ),
      );

  @override
  Future<bool> isAvailable() async => true;
}

/// 021 FR-031: the scan history and a scan's detail are live — a scan made
/// in the scan flow, or a produced transaction deleted from its person's
/// screen, reaches the open page with no navigation and no reload. The real
/// repositories run on an in-memory database.
void main() {
  late AppDatabase db;
  late TransactionsRepositoryImpl transactions;
  late OcrRepositoryImpl ocr;
  late Directory tempDir;
  late String imagePath;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    transactions = TransactionsRepositoryImpl(testTransactionsDao(db), db);
    final people = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
    ocr = OcrRepositoryImpl(
      OcrDao(db),
      _FakeRecognition(),
      const CandidateEntryParser(),
      transactions,
      OccasionsRepositoryImpl(
        testOccasionsDao(db),
        transactions,
        people,
        db,
        getConversionContextWith(),
        const CurrencyConverterImpl(),
      ),
      people,
      getPrimaryCurrencyReturning(),
      db,
    );
    getIt
      ..registerFactory<ScanHistoryCubit>(
        () => ScanHistoryCubit(WatchScanHistory(ocr), DeleteScan(ocr)),
      )
      ..registerFactory<ScanDetailCubit>(
        () => ScanDetailCubit(WatchScanDetail(ocr), DeleteScan(ocr)),
      )
      ..registerFactory<WatchTransactionAuditHistory>(
        () => WatchTransactionAuditHistory(transactions),
      );
    tempDir = await Directory.systemTemp.createTemp('scan_live_test');
    // Deliberately never written: the pages degrade a missing image to a
    // placeholder, and nothing here is about the picture.
    imagePath = '${tempDir.path}/missing.png';
  });

  tearDown(() async {
    await getIt.reset();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Widget app(Widget home) => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  Future<String> startScan() async => (await ocr.startScan(
    sourceImagePath: imagePath,
    rotationDegrees: 0,
  )).getOrElse((failure) => throw StateError('$failure')).id;

  /// A scan confirmed into two transactions, as the review flow leaves it.
  Future<String> confirmedScan() async {
    final scanId = await startScan();
    await ocr.runExtraction(scanId);
    await ocr.setBatchDefaultDirection(
      scanId: scanId,
      direction: TransactionDirection.received,
    );
    final confirmed = await ocr.confirmScanBatch(
      idempotencyKey: 'batch-$scanId',
      scanId: scanId,
    );
    expect(confirmed.isRight(), isTrue);
    return scanId;
  }

  /// Lets the database streams deliver: the queries run on real time, the
  /// page's debounce timers (50 ms) on the test's fake time.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// Runs [work] while the page is open, in the test's zone, so the page's
  /// own re-queries (started by [work]'s writes) are pumped alongside it
  /// instead of holding the database lock.
  Future<void> drive(WidgetTester tester, Future<void> Function() work) async {
    var done = false;
    Object? error;
    unawaited(
      work().then(
        (_) => done = true,
        onError: (Object e) {
          error = e;
          done = true;
        },
      ),
    );
    for (var i = 0; i < 200 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    if (error != null) throw error!;
    expect(done, isTrue, reason: 'the write did not finish');
    await settle(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Lets the cancelled subscriptions finish before the database closes.
    await settle(tester);
    await tester.runAsync(db.close);
  }

  testWidgets('a scan made in the scan flow appears on the open history, and '
      'one deleted elsewhere leaves it, without navigating', (tester) async {
    await tester.pumpWidget(app(const ScanHistoryPage()));
    await settle(tester);
    expect(find.byType(ScanHistoryTile), findsNothing);

    late String scanId;
    await drive(tester, () async => scanId = await startScan());
    expect(find.byType(ScanHistoryTile), findsOneWidget);

    await drive(tester, () => ocr.deleteScan(scanId));
    expect(find.byType(ScanHistoryTile), findsNothing);
    await dispose(tester);
  });

  testWidgets('a produced transaction deleted from its person\'s screen '
      'leaves the open scan detail, without navigating', (tester) async {
    // A tall surface keeps every row of the detail list built.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late String scanId;
    await tester.runAsync(() async => scanId = await confirmedScan());
    await tester.pumpWidget(app(ScanDetailPage(scanId: scanId)));
    await settle(tester);
    expect(find.byType(TransactionListTile), findsNWidgets(2));

    final produced = tester
        .widget<TransactionListTile>(find.byType(TransactionListTile).first)
        .transaction;
    await drive(tester, () => transactions.deleteTransaction(produced.id));

    expect(find.byType(TransactionListTile), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('tapping a produced transaction\'s "Edited" marker opens its '
      'change history (US8/AC1)', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late String scanId;
    await tester.runAsync(() async => scanId = await confirmedScan());
    await tester.pumpWidget(app(ScanDetailPage(scanId: scanId)));
    await settle(tester);
    final produced = tester
        .widget<TransactionListTile>(find.byType(TransactionListTile).first)
        .transaction;
    await drive(
      tester,
      () => transactions.editTransaction(
        transactionId: produced.id,
        amount: produced.amount,
        direction: produced.direction,
        date: produced.date,
        note: 'corrected',
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanDetailPage)),
    )!;

    await tester.tap(find.text('(${l10n.editedLabel})'));
    await settle(tester);

    expect(find.text(l10n.changeHistoryTitle), findsOneWidget);
    expect(find.text(l10n.changeHistoryCreated), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
  });
}
