import 'package:daftary/core/design_system/app_text_field.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_cubit.dart';
import 'package:daftary/features/people/presentation/cubit/person_list_cubit.dart';
import 'package:daftary/features/people/presentation/pages/archived_people_page.dart';
import 'package:daftary/features/people/presentation/pages/people_list_page.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

/// A minimal router fixture (mirroring `test/widget/main_shell_test.dart`)
/// reproducing the `/` <-> `/people/archived` and `/` <-> `/people/:id`
/// round trips this feature's reload-on-return fixes depend on. The
/// destination pages are simple placeholders — this test is about
/// `PeopleListPage`'s own reload behavior, not the destination screens.
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

Widget _wrap() {
  return MaterialApp.router(
    routerConfig: _buildTestRouter(),
    theme: buildLightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  late MockPeopleRepository peopleRepository;
  late MockTransactionsRepository transactionsRepository;

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

    getIt.registerFactory<PersonListCubit>(
      () => PersonListCubit(
        peopleRepository,
        GetPersonBalance(transactionsRepository),
        ArchivePerson(peopleRepository),
      ),
    );
    getIt.registerFactory<ArchivedPeopleCubit>(
      () => ArchivedPeopleCubit(
        peopleRepository,
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

  tearDown(() => getIt.reset());

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
    'reloads the active list after returning from the archived-list push '
    '(the originally reported bug\'s root-cause call site)',
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

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(PeopleListPage), findsOneWidget);
      verify(
        () => peopleRepository.searchActivePeople(
          nameQuery: any(named: 'nameQuery'),
          statusFilter: any(named: 'statusFilter'),
        ),
      ).called(1);
    },
  );

  testWidgets('reloads the active list after returning from a person-tile push '
      '(User Story 2)', (tester) async {
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
    verify(
      () => peopleRepository.searchActivePeople(
        nameQuery: any(named: 'nameQuery'),
        statusFilter: any(named: 'statusFilter'),
      ),
    ).called(1);
  });

  testWidgets(
    'a search term is preserved and a newly-unarchived matching person is '
    'included after the archived-list reload-on-return fires (FR-005)',
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
      // next active-list reload (on return) must now include her.
      when(
        () => peopleRepository.searchActivePeople(
          nameQuery: 'Sa',
          statusFilter: any(named: 'statusFilter'),
        ),
      ).thenAnswer((_) async => Right([sara]));

      await tester.tap(find.byTooltip(l10n.archivedPeopleAction));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Search term still applied (not reset to unfiltered)...
      expect(find.text('Sa'), findsOneWidget);
      // ...and the newly-unarchived matching person is now visible.
      expect(find.text('Sara'), findsOneWidget);
    },
  );
}
