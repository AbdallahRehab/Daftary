import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:daftary/features/currency/domain/usecases/watch_primary_currency.dart';
import 'package:daftary/features/people/domain/usecases/watch_person.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_history.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_cubit.dart';
import 'package:daftary/features/transactions/presentation/pages/person_detail_page.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:daftary/features/currency/presentation/widgets/rate_needed_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../features/transactions/helpers/currency_test_doubles.dart';
import '../helpers/watch_stubs.dart';
import '../helpers/sync_conflicts_stub.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;
  late FakeTableChanges changes;

  final now = DateTime(2026, 1, 1);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  WatchPrimaryCurrency watchPrimary() {
    final repository = currencyRepositoryWith();
    stubCurrencyWatches(repository, changes);
    return WatchPrimaryCurrency(repository);
  }

  setUp(() {
    peopleRepository = MockPeopleRepository();
    transactionsRepository = MockTransactionsRepository();
    changes = FakeTableChanges();
    stubPeopleWatches(peopleRepository, changes);
    stubTransactionsWatches(transactionsRepository, changes);

    registerNoSyncConflicts();
    getIt.registerFactory<PersonDetailCubit>(
      () => PersonDetailCubit(
        WatchPerson(peopleRepository),
        WatchPersonBalance(transactionsRepository),
        WatchPersonHistory(transactionsRepository),
        DeleteTransaction(transactionsRepository),
        watchPrimary(),
        transactionsRepository,
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await changes.close();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets(
    'renders the balance headline and lists transactions in chronological order',
    (tester) async {
      final older = MoneyTransaction(
        id: 't1',
        idempotencyKey: 'k1',
        personId: 'p1',
        amount: const Money.egp(200000),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      final newer = MoneyTransaction(
        id: 't2',
        idempotencyKey: 'k2',
        personId: 'p1',
        amount: const Money.egp(50000),
        direction: TransactionDirection.received,
        kind: TransactionKind.initialExchange,
        date: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
      );

      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(150000))),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => Right([older, newer]));

      await tester.pumpWidget(wrap(const PersonDetailPage(personId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('Ahmed owes you 1,500.00 EGP'), findsOneWidget);

      final tiles = tester.widgetList<TransactionListTile>(
        find.byType(TransactionListTile),
      );
      expect(tiles.map((t) => t.transaction.id), ['t1', 't2']);
    },
  );

  testWidgets('shows "Settled" when the net balance is zero', (tester) async {
    when(
      () => peopleRepository.getPersonById('p1'),
    ).thenAnswer((_) async => Right(ahmed));
    when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
      (_) async =>
          const Right(PersonBalance(personId: 'p1', net: Money.egp(0))),
    );
    when(
      () => transactionsRepository.getPersonHistory('p1'),
    ).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(wrap(const PersonDetailPage(personId: 'p1')));
    await tester.pumpAndSettle();

    expect(find.text('Settled'), findsWidgets);
  });

  testWidgets(
    'a balance blocked on a missing rate shows the RateNeededBanner naming '
    'the currency and the known per-currency amount (018 FR-009)',
    (tester) async {
      when(
        () => peopleRepository.getPersonById('p1'),
      ).thenAnswer((_) async => Right(ahmed));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance.blocked(
            personId: 'p1',
            nativeNets: [Money.fromMinorUnits(2500, Currency.usd)],
            missingRatesFor: [Currency.usd],
          ),
        ),
      );
      when(
        () => transactionsRepository.getPersonHistory('p1'),
      ).thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(wrap(const PersonDetailPage(personId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.byKey(RateNeededBanner.rootKey), findsOneWidget);
      expect(find.textContaining('USD'), findsWidgets);
      expect(find.text('Ahmed owes you 25.00 USD'), findsOneWidget);
    },
  );
}
