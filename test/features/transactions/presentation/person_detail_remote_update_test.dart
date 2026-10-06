import 'dart:async';

import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/resolve_sync_conflict.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:daftary/features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart';
import 'package:daftary/features/cloud_sync/presentation/widgets/conflict_badge.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_primary_currency.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/people/domain/usecases/watch_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/preview_transaction_deletion.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_history.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_cubit.dart';
import 'package:daftary/features/transactions/presentation/pages/person_detail_page.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/sync/fakes/server_rows.dart';
import '../../../core/sync/fakes/sync_harness.dart';
import '../../../helpers/test_daos.dart';

/// 021 T070: a change made on another device reaches an open Person Detail
/// page through one sync cycle — the real repositories on an in-memory
/// database, [SyncEngine] against a [FakeSyncRemote] — with no navigation.
void main() {
  late SyncHarness h;

  setUp(() {
    h = SyncHarness();
    final db = h.db;
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    final context = GetConversionContext(currency);
    final people = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
      getConversionContext: context,
    );
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: context,
    );
    final cloudSync = h.cloudSync();

    getIt
      ..registerFactory<PersonDetailCubit>(
        () => PersonDetailCubit(
          WatchPerson(people),
          WatchPersonBalance(transactions),
          WatchPersonHistory(transactions),
          DeleteTransaction(transactions),
          WatchPrimaryCurrency(currency),
          transactions,
          PreviewTransactionDeletion(
            transactions,
            GetConversionContext(currency),
          ),
        ),
      )
      ..registerFactory<SyncConflictsCubit>(
        () => SyncConflictsCubit(
          WatchSyncConflicts(cloudSync),
          ResolveSyncConflict(cloudSync),
        ),
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget app() => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const PersonDetailPage(personId: 'p1'),
  );

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
    expect(done, isTrue, reason: 'the sync work did not finish');
    await settle(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Lets the cancelled subscriptions finish before the database closes.
    await settle(tester);
    await tester.runAsync(h.close);
  }

  testWidgets('a transaction added on another device appears with the new '
      'balance after one sync, without navigating', (tester) async {
    await tester.runAsync(() async {
      await h.createPerson('p1', name: 'Ahmed');
      await h.createTransaction('t1', personId: 'p1', amount: 50000);
      await h.engine.runCycle();
    });
    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.byType(TransactionListTile), findsOneWidget);
    expect(find.text('Ahmed owes you 500.00 EGP'), findsOneWidget);

    // Another device of the same account records a second transaction.
    h.remote.seedServerRow(
      SyncEntityType.moneyTransaction,
      transactionRow('t2', personId: 'p1', amount: 25000),
    );
    await drive(tester, () => h.engine.runCycle().then((_) {}));

    expect(find.byType(TransactionListTile), findsNWidgets(2));
    expect(find.text('Ahmed owes you 750.00 EGP'), findsOneWidget);
    expect(find.byType(ConflictBadge), findsNothing);
    await dispose(tester);
  });

  testWidgets('a conflict found by sync badges only that row', (tester) async {
    await tester.runAsync(() async {
      await h.createPerson('p1', name: 'Ahmed');
      await h.createTransaction('t1', personId: 'p1', amount: 50000);
      await h.createTransaction('t2', personId: 'p1', amount: 10000);
      await h.engine.runCycle();
    });
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.byType(ConflictBadge), findsNothing);

    h.remote.seedServerRow(SyncEntityType.moneyTransaction, {
      ...h.remote.rowOf(SyncEntityType.moneyTransaction, 't1')!,
      'amount_minor': 99900,
    });
    await drive(tester, () async {
      await h.editTransaction('t1', amount: 60000);
      await h.engine.runCycle();
    });

    expect(find.byType(ConflictBadge), findsOneWidget);
    final badged = tester.widget<TransactionListTile>(
      find.ancestor(
        of: find.byType(ConflictBadge),
        matching: find.byType(TransactionListTile),
      ),
    );
    expect(badged.transaction.id, 't1');
    await dispose(tester);
  });
}
