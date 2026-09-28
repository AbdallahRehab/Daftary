import 'dart:async';

import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/media/attachment_picker_service.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/occasions/data/sync/occasion_sync_mapper.dart';
import 'package:daftary/features/occasions/domain/usecases/add_occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/usecases/archive_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/delete_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/remove_occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/usecases/remove_participant_contribution.dart';
import 'package:daftary/features/occasions/domain/usecases/restore_occasion.dart';
import 'package:daftary/features/occasions/domain/usecases/watch_occasion_detail.dart';
import 'package:daftary/features/occasions/domain/usecases/watch_occasions_list.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasion_detail_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasions_list_cubit.dart';
import 'package:daftary/features/occasions/presentation/pages/occasion_detail_page.dart';
import 'package:daftary/features/occasions/presentation/pages/occasions_list_page.dart';
import 'package:daftary/features/occasions/presentation/widgets/occasion_list_tile.dart';
import 'package:daftary/features/occasions/presentation/widgets/occasion_totals_card.dart';
import 'package:daftary/features/occasions/presentation/widgets/participant_row.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/sync/fakes/server_rows.dart';
import '../../../core/sync/fakes/sync_harness.dart';
import '../../../helpers/test_daos.dart';

class _MockAttachmentPickerService extends Mock
    implements AttachmentPickerService {}

/// 021 FR-031: a change made on another device reaches an open occasions
/// screen through one sync cycle — the real repositories on an in-memory
/// database, `SyncEngine` against a `FakeSyncRemote` — with no navigation
/// and no reload.
void main() {
  late SyncHarness h;

  setUp(() {
    h = SyncHarness();
    final database = h.db;
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(database),
      const SystemAppClock(),
    );
    final context = GetConversionContext(currency);
    final people = PeopleRepositoryImpl(
      testPeopleDao(database),
      const FindPossibleDuplicatePerson(),
      database,
      getConversionContext: context,
    );
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(database),
      database,
      getConversionContext: context,
    );
    final occasions = OccasionsRepositoryImpl(
      testOccasionsDao(database),
      transactions,
      people,
      database,
      context,
      const CurrencyConverterImpl(),
    );

    getIt
      ..registerFactory<OccasionsListCubit>(
        () => OccasionsListCubit(WatchOccasionsList(occasions)),
      )
      ..registerFactory<OccasionDetailCubit>(
        () => OccasionDetailCubit(
          WatchOccasionDetail(occasions),
          RemoveParticipantContribution(occasions),
          AddOccasionAttachment(occasions),
          RemoveOccasionAttachment(occasions),
          ArchiveOccasion(occasions),
          RestoreOccasion(occasions),
          DeleteOccasion(occasions),
          _MockAttachmentPickerService(),
        ),
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget app(Widget home) => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  /// An occasion as another device uploads it.
  Map<String, Object?> occasionRow(String id, String name) =>
      const OccasionSyncMapper().toWire(
        db.Occasion(
          id: id,
          idempotencyKey: 'key-$id',
          name: name,
          date: DateTime(2026, 3, 10).millisecondsSinceEpoch,
          type: 'wedding',
          isArchived: false,
          createdAt: 1000,
          updatedAt: 1000,
        ),
      );

  /// A contribution to [occasionId] as another device uploads it.
  Map<String, Object?> contributionRow(
    String id, {
    required String occasionId,
    required int amount,
  }) => {
    ...transactionRow(id, personId: 'p1', amount: amount),
    'direction': 'received',
    'kind': 'occasionContribution',
    'occasion_id': occasionId,
    'counts_toward_balance': true,
    'source': 'manual',
  };

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

  testWidgets('an occasion created on another device appears on the open '
      'list after one sync, without navigating', (tester) async {
    await tester.runAsync(() async {
      h.remote.seedServerRow(
        SyncEntityType.occasion,
        occasionRow('o1', "Sara's wedding"),
      );
      await h.engine.runCycle();
    });
    await tester.pumpWidget(app(const OccasionsListPage()));
    await settle(tester);

    expect(find.byType(OccasionListTile), findsOneWidget);
    expect(find.text("Sara's wedding"), findsOneWidget);

    h.remote.seedServerRow(
      SyncEntityType.occasion,
      occasionRow('o2', "Omar's graduation"),
    );
    await drive(tester, () => h.engine.runCycle().then((_) {}));

    expect(find.byType(OccasionListTile), findsNWidgets(2));
    expect(find.text("Omar's graduation"), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('a contribution recorded on another device appears on the open '
      'occasion with recalculated totals, without navigating', (tester) async {
    await tester.runAsync(() async {
      await h.createPerson('p1', name: 'Ahmed');
      h.remote.seedServerRow(
        SyncEntityType.occasion,
        occasionRow('o1', "Sara's wedding"),
      );
      h.remote.seedServerRow(
        SyncEntityType.moneyTransaction,
        contributionRow('t1', occasionId: 'o1', amount: 50000),
      );
      await h.engine.runCycle();
    });
    await tester.pumpWidget(app(const OccasionDetailPage(occasionId: 'o1')));
    await settle(tester);

    OccasionTotalsCard card() =>
        tester.widget<OccasionTotalsCard>(find.byType(OccasionTotalsCard));
    expect(find.byType(ParticipantRow), findsOneWidget);
    expect(card().summary.totalReceived, const Money.egp(50000));

    // Another device of the same account records a second contribution.
    h.remote.seedServerRow(
      SyncEntityType.moneyTransaction,
      contributionRow('t2', occasionId: 'o1', amount: 25000),
    );
    await drive(tester, () => h.engine.runCycle().then((_) {}));

    expect(find.byType(ParticipantRow), findsNWidgets(2));
    expect(card().summary.totalReceived, const Money.egp(75000));
    await dispose(tester);
  });
}
