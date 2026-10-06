import 'package:daftary/core/design_system/app_text_field.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/domain/usecases/watch_active_people.dart';
import 'package:daftary/features/people/domain/usecases/watch_archived_people.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_cubit.dart';
import 'package:daftary/features/people/presentation/cubit/person_list_cubit.dart';
import 'package:daftary/features/people/presentation/pages/archived_people_page.dart';
import 'package:daftary/features/people/presentation/pages/people_list_page.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balances.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/stub_person_balances.dart';
import '../helpers/watch_stubs.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// A minimal router fixture (mirroring `test/widget/main_shell_test.dart`)
/// reproducing the `/` <-> `/people/archived` and `/` <-> `/people/:id`
/// round trips the 005 archive-refresh fixes depend on (met, since 021, by
/// live subscriptions). The destination pages are simple placeholders —
/// this test is about `PeopleListPage`'s own behavior.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const PeopleListPage()),
      GoRoute(
        path: '/people/archived',
        builder: (context, state) => const ArchivedPeoplePage(),
      ),
      GoRoute(
        path: '/people/:id',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: Text('Detail ${state.pathParameters['id']}')),
        ),
      ),
      GoRoute(
        path: '/people/new',
        builder: (context, state) =>
            const Scaffold(appBar: null, body: Text('New Person')),
      ),
    ],
  );
}

Widget _wrap({Locale? locale}) {
  return MaterialApp.router(
    locale: locale,
    routerConfig: _buildTestRouter(),
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;
  late FakeTableChanges changes;

  final now = DateTime(2026);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
  final sara = Person(
    id: 'p2',
    name: 'Sara',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    peopleRepository = MockPeopleRepository();
    transactionsRepository = MockTransactionsRepository();
    changes = FakeTableChanges();
    stubPersonBalancesFromSingle(transactionsRepository);
    stubPeopleWatches(peopleRepository, changes);
    stubTransactionsWatches(transactionsRepository, changes);

    getIt.registerFactory<PersonListCubit>(
      () => PersonListCubit(
        WatchActivePeople(peopleRepository),
        WatchPersonBalances(transactionsRepository),
        ArchivePerson(peopleRepository),
        RestorePerson(peopleRepository),
      ),
    );
    getIt.registerFactory<ArchivedPeopleCubit>(
      () => ArchivedPeopleCubit(
        WatchArchivedPeople(peopleRepository),
        RestorePerson(peopleRepository),
      ),
    );

    when(() => transactionsRepository.getPersonBalance(any())).thenAnswer(
      (invocation) async => Right(
        PersonBalance(
          personId: invocation.positionalArguments.first as String,
          net: const Money.egp(0),
        ),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await changes.close();
  });

  testWidgets(
    'a balance blocked on a missing rate shows its native amount and a '
    'compact rate-needed label instead of crashing (018 FR-009)',
    (tester) async {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => Right([ahmed, sara]));
      when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
        (_) async => const Right(
          PersonBalance.blocked(
            personId: 'p1',
            nativeNets: [Money.fromMinorUnits(2500, Currency.usd)],
            missingRatesFor: [Currency.usd],
          ),
        ),
      );
      when(() => transactionsRepository.getPersonBalance('p2')).thenAnswer(
        (_) async => const Right(
          PersonBalance.blocked(
            personId: 'p2',
            nativeNets: [
              Money.egp(1000),
              Money.fromMinorUnits(-300, Currency.eur),
            ],
            missingRatesFor: [Currency.eur],
          ),
        ),
      );

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('25.00 USD'), findsOneWidget);
      expect(find.text('10.00 EGP + 3.00 EUR'), findsOneWidget);
      expect(
        find.byKey(const Key('person_rate_needed_label')),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'an unarchive on the archived list shows on return with no reload '
    '(the originally reported bug\'s root-cause call site; 021 FR-031)',
    (tester) async {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => Right([ahmed]));
      when(
        () => peopleRepository.searchArchivedPeople(
          nameQuery: any(named: 'nameQuery'),
        ),
      ).thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PeopleListPage)),
      )!;

      verify(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).called(1);

      await tester.tap(find.byTooltip(l10n.archivedPeopleAction));
      await tester.pumpAndSettle();
      expect(find.byType(ArchivedPeoplePage), findsOneWidget);

      // Sara is unarchived while the archived list is open: only the table
      // notification reaches the list underneath.
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => Right([ahmed, sara]));
      changes.notify();
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(PeopleListPage), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
    },
  );

  testWidgets('returning from a person-tile push needs no reload — the list '
      'is live (User Story 2, 021 FR-031)', (tester) async {
    when(
      () => peopleRepository.searchActivePeople(
        nameQuery: any(named: 'nameQuery'),
        statusFilter: any(named: 'statusFilter'),
      ),
    ).thenAnswer((_) async => Right([ahmed]));

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    verify(
      () => peopleRepository.searchActivePeople(
        nameQuery: any(named: 'nameQuery'),
        statusFilter: any(named: 'statusFilter'),
      ),
    ).called(1);

    await tester.tap(find.text('Ahmed'));
    await tester.pumpAndSettle();
    expect(find.text('Detail p1'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(PeopleListPage), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
    verifyNever(
      () => peopleRepository.searchActivePeople(
        nameQuery: any(named: 'nameQuery'),
        statusFilter: any(named: 'statusFilter'),
      ),
    );
  });

  testWidgets(
    'a search term is preserved and a newly-unarchived matching person is '
    'included once the unarchive is written (FR-005, 021 FR-031)',
    (tester) async {
      // Initial load (empty query) and the not-yet-unarchived "Sa" search
      // both start empty — Sara isn't in the active list yet.
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => peopleRepository.searchArchivedPeople(
          nameQuery: any(named: 'nameQuery'),
        ),
      ).thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PeopleListPage)),
      )!;

      final searchField = find.ancestor(
        of: find.text(l10n.searchPeopleHint),
        matching: find.byType(TextField),
      );
      await tester.enterText(searchField, 'Sa');
      await tester.pumpAndSettle();
      expect(find.byType(AppTextField), findsWidgets);

      // Sara gets unarchived while the user is on the archived list, so the
      // live active list (still filtered by "Sa") must now include her.
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: 'Sa',
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => Right([sara]));

      await tester.tap(find.byTooltip(l10n.archivedPeopleAction));
      await tester.pumpAndSettle();
      changes.notify();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Search term still applied (not reset to unfiltered)...
      expect(find.text('Sa'), findsOneWidget);
      // ...and the newly-unarchived matching person is now visible.
      expect(find.text('Sara'), findsOneWidget);
    },
  );

  testWidgets('Arabic: the status label, the amount with its currency and '
      'right-to-left direction (RTL-09)', (tester) async {
    when(
      () => peopleRepository.searchActivePeople(
        nameQuery: any(named: 'nameQuery'),
        statusFilter: any(named: 'statusFilter'),
      ),
    ).thenAnswer((_) async => Right([ahmed]));
    when(() => transactionsRepository.getPersonBalance('p1')).thenAnswer(
      (_) async =>
          const Right(PersonBalance(personId: 'p1', net: Money.egp(150000))),
    );

    await tester.pumpWidget(_wrap(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('ar'));
    final amount = EgpFormatter(
      locale: 'ar',
    ).formatWithSymbol(const Money.egp(150000));
    expect(amount, contains('EGP'));
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text(l10n.filterTheyOweYou), findsWidgets);
    expect(find.text(amount), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(PeopleListPage))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  group('T097 no-match state', () {
    void stubNoPeople() {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => const Right([]));
    }

    Future<void> search(WidgetTester tester, String hint, String q) async {
      await tester.enterText(
        find.ancestor(of: find.text(hint), matching: find.byType(TextField)),
        q,
      );
      await tester.pumpAndSettle();
    }

    for (final locale in ['en', 'ar']) {
      testWidgets('[$locale] an empty result under a name query says no '
          'match, not "no people yet"', (tester) async {
        stubNoPeople();
        await tester.pumpWidget(_wrap(locale: Locale(locale)));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PeopleListPage)),
        )!;
        expect(find.text(l10n.emptyPeopleTitle), findsOneWidget);

        await search(tester, l10n.searchPeopleHint, 'zzz');

        expect(find.text(l10n.peopleNoMatchTitle), findsOneWidget);
        expect(find.text(l10n.peopleNoMatchMessage), findsOneWidget);
        expect(find.text(l10n.emptyPeopleTitle), findsNothing);
        expect(
          Directionality.of(tester.element(find.text(l10n.peopleNoMatchTitle))),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      });

      testWidgets('[$locale] an empty result under a status filter says no '
          'match', (tester) async {
        stubNoPeople();
        await tester.pumpWidget(_wrap(locale: Locale(locale)));
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PeopleListPage)),
        )!;

        await tester.tap(find.text(l10n.filterSettled));
        await tester.pumpAndSettle();

        expect(find.text(l10n.peopleNoMatchTitle), findsOneWidget);
        expect(find.text(l10n.emptyPeopleTitle), findsNothing);
      });
    }

    testWidgets('Clear filters empties the search box and the filter and '
        'brings the list back', (tester) async {
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: null,
          statusFilter: null,
        ),
      ).thenAnswer((_) async => Right([ahmed]));
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await search(tester, 'Search people', 'zzz');
      await tester.tap(find.text('Settled'));
      await tester.pumpAndSettle();
      expect(find.text('No matching people'), findsOneWidget);

      await tester.tap(find.text('Clear search and filter'));
      await tester.pumpAndSettle();

      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('zzz'), findsNothing);
      expect(find.text('No matching people'), findsNothing);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('Arabic: the clear action is offered', (tester) async {
      stubNoPeople();
      await tester.pumpWidget(_wrap(locale: const Locale('ar')));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PeopleListPage)),
      )!;
      await search(tester, l10n.searchPeopleHint, 'zzz');
      expect(find.text(l10n.peopleClearFiltersAction), findsOneWidget);
    });

    testWidgets('English copy', (tester) async {
      stubNoPeople();
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await search(tester, 'Search people', 'zzz');
      expect(find.text('No matching people'), findsOneWidget);
    });
  });
}
