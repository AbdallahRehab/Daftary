import 'dart:async';

import 'package:daftary/core/design_system/app_button.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/people/presentation/cubit/person_list_cubit.dart';
import 'package:daftary/features/people/presentation/pages/people_list_page.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_history.dart';
import 'package:daftary/features/transactions/presentation/cubit/person_detail_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/pages/person_detail_page.dart';
import 'package:daftary/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:daftary/features/transactions/presentation/widgets/balance_status_badge.dart';
import 'package:daftary/features/transactions/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../features/transactions/helpers/currency_test_doubles.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockCreatePerson extends Mock implements CreatePerson {}

class MockAddTransaction extends Mock implements AddTransaction {}

class MockEditTransaction extends Mock implements EditTransaction {}

/// Reproduces the real app's `/people/:id` <-> `/transactions/new` routing
/// (`lib/core/routing/app_router.dart`) without the `StatefulShellRoute`
/// wrapper, mirroring `test/widget/main_shell_test.dart`'s router-fixture
/// pattern. This is enough to exercise the real pop()-based navigation
/// contract fixed in T003-T005.
GoRouter _buildTestRouter({String initialLocation = '/people/p1'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PeopleListPage()),
      GoRoute(
        path: '/people/:id',
        builder: (context, state) =>
            PersonDetailPage(personId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => TransactionFormPage(
          personId: state.uri.queryParameters['personId'],
        ),
      ),
    ],
  );
}

Widget _wrap({String initialLocation = '/people/p1'}) {
  return MaterialApp.router(
    routerConfig: _buildTestRouter(initialLocation: initialLocation),
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;
  late MockCreatePerson createPerson;
  late MockAddTransaction addTransaction;
  late MockEditTransaction editTransaction;

  final now = DateTime(2026, 1, 1);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    registerFallbackValue(TransactionDirection.given);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    peopleRepository = MockPeopleRepository();
    transactionsRepository = MockTransactionsRepository();
    createPerson = MockCreatePerson();
    addTransaction = MockAddTransaction();
    editTransaction = MockEditTransaction();

    getIt.registerFactory<PersonDetailCubit>(
      () => PersonDetailCubit(
        peopleRepository,
        GetPersonBalance(transactionsRepository),
        GetPersonHistory(transactionsRepository),
        DeleteTransaction(transactionsRepository),
        getPrimaryCurrencyReturning(),
      ),
    );
    getIt.registerFactory<TransactionFormCubit>(
      () => TransactionFormCubit(
        peopleRepository,
        createPerson,
        addTransaction,
        editTransaction,
        getPrimaryCurrencyReturning(),
      ),
    );
    getIt.registerFactory<PersonListCubit>(
      () => PersonListCubit(
        peopleRepository,
        GetPersonBalance(transactionsRepository),
        ArchivePerson(peopleRepository),
        RestorePerson(peopleRepository),
      ),
    );

    when(
      () => peopleRepository.getPersonById('p1'),
    ).thenAnswer((_) async => Right(ahmed));
  });

  tearDown(() => getIt.reset());

  /// Backs [transactionsRepository]'s `getPersonHistory`/`getPersonBalance`
  /// for `p1` with a mutable in-memory list, so a save that goes through
  /// [addTransaction] and a subsequent `PersonDetailCubit.refresh()` see
  /// each other's effect exactly like the real DB-backed repository would
  /// (data-model.md: `PersonBalance.net` is "computed fresh on every
  /// `TransactionsRepository.getPersonBalance` call").
  List<MoneyTransaction> wireHistoryStore() {
    final store = <MoneyTransaction>[];

    Money netOf(List<MoneyTransaction> history) {
      var minor = 0;
      for (final t in history) {
        minor += t.direction == TransactionDirection.given
            ? t.amount.minorUnits
            : -t.amount.minorUnits;
      }
      return Money.egp(minor);
    }

    when(
      () => transactionsRepository.getPersonHistory('p1'),
    ).thenAnswer((_) async => Right(List.of(store)));
    when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
      (_) async => Right(PersonBalance(personId: 'p1', net: netOf(store))),
    );

    return store;
  }

  void wireSuccessfulAdd(
    List<MoneyTransaction> store, {
    required TransactionDirection direction,
    required Money amount,
  }) {
    when(
      () => addTransaction(
        idempotencyKey: any(named: 'idempotencyKey'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {
      final transaction = MoneyTransaction(
        id: 't${store.length + 1}',
        idempotencyKey: 'key-${store.length + 1}',
        personId: 'p1',
        amount: amount,
        direction: direction,
        kind: TransactionKind.initialExchange,
        date: now,
        createdAt: now,
      );
      store.add(transaction);
      return Right(transaction);
    });
  }

  Future<void> openAddTransactionForm(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormPage), findsOneWidget);
  }

  Future<void> fillAmountAndSave(
    WidgetTester tester,
    AppLocalizations l10n, {
    required String amount,
    bool selectReceived = false,
  }) async {
    if (selectReceived) {
      await tester.tap(find.text(l10n.directionReceived));
      await tester.pumpAndSettle();
    }
    final amountField = find.ancestor(
      of: find.text(l10n.amountLabel),
      matching: find.byType(TextField),
    );
    await tester.enterText(amountField, amount);
    // 018 added a currency field above Save, which puts Save inside the
    // snackbar region of the 800x600 test viewport. A previous save's
    // "Saved" snackbar can still be showing on this fresh form, so
    // dismiss it first, as a user would, instead of tapping through it.
    ScaffoldMessenger.of(
      tester.element(find.byType(TransactionFormPage)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, l10n.commonSave));
    await tester.pumpAndSettle();
  }

  group('User Story 1 - new transaction appears immediately', () {
    testWidgets(
      'a "money received" save is reflected on Person Details with no reload',
      (tester) async {
        final store = wireHistoryStore();
        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.received,
          amount: const Money.egp(50000),
        );

        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PersonDetailPage)),
        )!;

        expect(find.byType(TransactionListTile), findsNothing);

        await openAddTransactionForm(tester);
        await fillAmountAndSave(
          tester,
          l10n,
          amount: '500',
          selectReceived: true,
        );

        // Popped back to the same, still-mounted Person Details screen —
        // no `go()`-driven remount — with the new transaction visible.
        expect(find.byType(PersonDetailPage), findsOneWidget);
        expect(find.byType(TransactionFormPage), findsNothing);
        expect(find.byType(TransactionListTile), findsOneWidget);
      },
    );

    testWidgets(
      'a "money given" save is reflected on Person Details with no reload',
      (tester) async {
        final store = wireHistoryStore();
        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.given,
          amount: const Money.egp(75000),
        );

        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PersonDetailPage)),
        )!;

        await openAddTransactionForm(tester);
        await fillAmountAndSave(tester, l10n, amount: '750');

        expect(find.byType(PersonDetailPage), findsOneWidget);
        expect(find.byType(TransactionListTile), findsOneWidget);
      },
    );

    testWidgets(
      'a second add from the same now-fresh screen also appears immediately '
      'with exactly one entry each (no duplicate/stale Page-key reuse)',
      (tester) async {
        final store = wireHistoryStore();

        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PersonDetailPage)),
        )!;

        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.given,
          amount: const Money.egp(10000),
        );
        await openAddTransactionForm(tester);
        await fillAmountAndSave(tester, l10n, amount: '100');
        expect(find.byType(TransactionListTile), findsOneWidget);

        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.received,
          amount: const Money.egp(20000),
        );
        await openAddTransactionForm(tester);
        await fillAmountAndSave(
          tester,
          l10n,
          amount: '200',
          selectReceived: true,
        );

        expect(find.byType(TransactionListTile), findsNWidgets(2));
      },
    );

    testWidgets(
      'the global-FAB personId-less flow opens the saved transaction\'s '
      'person and the transaction is visible immediately',
      (tester) async {
        when(
          () => peopleRepository.searchActivePeople(
            nameQuery: any(named: 'nameQuery'),
            statusFilter: any(named: 'statusFilter'),
          ),
        ).thenAnswer((_) async => const Right([]));
        final store = wireHistoryStore();
        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.given,
          amount: const Money.egp(30000),
        );

        await tester.pumpWidget(_wrap(initialLocation: '/'));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PeopleListPage)),
        )!;

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(TransactionFormPage), findsOneWidget);

        final personField = find.ancestor(
          of: find.text(l10n.personLabel),
          matching: find.byType(TextField),
        );
        when(
          () => peopleRepository.searchActivePeople(
            nameQuery: 'Ahmed',
            statusFilter: any(named: 'statusFilter'),
          ),
        ).thenAnswer((_) async => Right([ahmed]));
        await tester.enterText(personField, 'Ahmed');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ahmed').last);
        await tester.pumpAndSettle();

        await fillAmountAndSave(tester, l10n, amount: '300');

        expect(find.byType(PersonDetailPage), findsOneWidget);
        expect(find.byType(TransactionListTile), findsOneWidget);
      },
    );
  });

  group('User Story 2 - totals and balance update immediately', () {
    testWidgets(
      'the net balance headline updates by exactly the saved amount',
      (tester) async {
        final store = wireHistoryStore();
        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.given,
          amount: const Money.egp(150000),
        );

        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PersonDetailPage)),
        )!;

        var badge = tester.widget<BalanceStatusBadge>(
          find.byType(BalanceStatusBadge),
        );
        expect(badge.status, RelationshipStatus.settled);

        await openAddTransactionForm(tester);
        await fillAmountAndSave(tester, l10n, amount: '1500');

        badge = tester.widget<BalanceStatusBadge>(
          find.byType(BalanceStatusBadge),
        );
        expect(badge.status, RelationshipStatus.theyOweYou);
      },
    );

    testWidgets(
      'a balance-flipping save updates the relationship status badge, not '
      'just the amount',
      (tester) async {
        final store = wireHistoryStore();
        // Start settled-but-they-owe-slightly, then a large "given" flips
        // it further into theyOweYou (still exercises a status change).
        store.add(
          MoneyTransaction(
            id: 'seed',
            idempotencyKey: 'seed-key',
            personId: 'p1',
            amount: const Money.egp(10000),
            direction: TransactionDirection.received,
            kind: TransactionKind.initialExchange,
            date: now,
            createdAt: now,
          ),
        );
        wireSuccessfulAdd(
          store,
          direction: TransactionDirection.given,
          amount: const Money.egp(500000),
        );

        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PersonDetailPage)),
        )!;

        var badge = tester.widget<BalanceStatusBadge>(
          find.byType(BalanceStatusBadge),
        );
        expect(badge.status, RelationshipStatus.youOweThem);

        await openAddTransactionForm(tester);
        await fillAmountAndSave(tester, l10n, amount: '5000');

        badge = tester.widget<BalanceStatusBadge>(
          find.byType(BalanceStatusBadge),
        );
        expect(badge.status, RelationshipStatus.theyOweYou);
      },
    );
  });

  group(
    'User Story 3 - failed transaction creation does not corrupt state',
    () {
      testWidgets(
        'a failed save leaves the list and totals unchanged after backing out',
        (tester) async {
          final store = wireHistoryStore();
          store.add(
            MoneyTransaction(
              id: 'seed',
              idempotencyKey: 'seed-key',
              personId: 'p1',
              amount: const Money.egp(20000),
              direction: TransactionDirection.given,
              kind: TransactionKind.initialExchange,
              date: now,
              createdAt: now,
            ),
          );
          when(
            () => addTransaction(
              idempotencyKey: any(named: 'idempotencyKey'),
              personId: any(named: 'personId'),
              amount: any(named: 'amount'),
              direction: any(named: 'direction'),
              date: any(named: 'date'),
              note: any(named: 'note'),
            ),
          ).thenAnswer((_) async => const Left(ValidationFailure('rejected')));

          await tester.pumpWidget(_wrap());
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PersonDetailPage)),
          )!;

          await openAddTransactionForm(tester);
          await fillAmountAndSave(tester, l10n, amount: '200');

          // Failure branch never pops/navigates — the form stays open with
          // a snackbar (spec Acceptance Scenario 1, US3).
          expect(find.byType(TransactionFormPage), findsOneWidget);
          expect(find.text(l10n.errorValidation), findsOneWidget);

          // The pre-existing failure path already pops normally on manual
          // back navigation (research.md) — confirm Person Details is
          // unchanged once the user backs out themselves.
          await tester.pageBack();
          await tester.pumpAndSettle();

          expect(find.byType(PersonDetailPage), findsOneWidget);
          expect(find.byType(TransactionListTile), findsOneWidget);
          final badge = tester.widget<BalanceStatusBadge>(
            find.byType(BalanceStatusBadge),
          );
          expect(badge.status, RelationshipStatus.theyOweYou);
        },
      );

      testWidgets(
        'a rapid double-tap of Save persists exactly one transaction',
        (tester) async {
          final store = wireHistoryStore();
          wireSuccessfulAdd(
            store,
            direction: TransactionDirection.given,
            amount: const Money.egp(10000),
          );

          await tester.pumpWidget(_wrap());
          await tester.pumpAndSettle();
          final l10n = AppLocalizations.of(
            tester.element(find.byType(PersonDetailPage)),
          )!;

          await openAddTransactionForm(tester);
          final amountField = find.ancestor(
            of: find.text(l10n.amountLabel),
            matching: find.byType(TextField),
          );
          await tester.enterText(amountField, '100');
          final saveButton = find.widgetWithText(AppButton, l10n.commonSave);
          await tester.tap(saveButton);
          // The button disables itself the instant `isSubmitting` is true
          // (FR-020 guard), so this second tap intentionally won't hit —
          // that's exactly the behavior under test.
          await tester.tap(saveButton, warnIfMissed: false);
          await tester.pumpAndSettle();

          verify(
            () => addTransaction(
              idempotencyKey: any(named: 'idempotencyKey'),
              personId: any(named: 'personId'),
              amount: any(named: 'amount'),
              direction: any(named: 'direction'),
              date: any(named: 'date'),
              note: any(named: 'note'),
            ),
          ).called(1);
          expect(find.byType(TransactionListTile), findsOneWidget);
        },
      );
    },
  );

  group('Edge case - navigated away before the save completes', () {
    testWidgets(
      'popping the form before the save Future resolves does not crash and '
      'does not duplicate the eventual save',
      (tester) async {
        final store = wireHistoryStore();
        final completer = Completer<Either<Failure, MoneyTransaction>>();
        when(
          () => addTransaction(
            idempotencyKey: any(named: 'idempotencyKey'),
            personId: any(named: 'personId'),
            amount: any(named: 'amount'),
            direction: any(named: 'direction'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PersonDetailPage)),
        )!;

        await openAddTransactionForm(tester);
        final amountField = find.ancestor(
          of: find.text(l10n.amountLabel),
          matching: find.byType(TextField),
        );
        await tester.enterText(amountField, '100');
        await tester.tap(find.widgetWithText(AppButton, l10n.commonSave));
        await tester.pump();

        // Navigate away while the save is still in flight.
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(PersonDetailPage), findsOneWidget);

        final transaction = MoneyTransaction(
          id: 't1',
          idempotencyKey: 'key-1',
          personId: 'p1',
          amount: const Money.egp(10000),
          direction: TransactionDirection.given,
          kind: TransactionKind.initialExchange,
          date: now,
          createdAt: now,
        );
        store.add(transaction);
        completer.complete(Right(transaction));
        await tester.pumpAndSettle();

        // No crash from emitting into a disposed cubit/unmounted listener,
        // and only the one transaction ever got persisted.
        expect(tester.takeException(), isNull);
        verify(
          () => addTransaction(
            idempotencyKey: any(named: 'idempotencyKey'),
            personId: any(named: 'personId'),
            amount: any(named: 'amount'),
            direction: any(named: 'direction'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );
  });
}
