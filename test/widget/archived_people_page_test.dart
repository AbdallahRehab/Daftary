import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/restore_person.dart';
import 'package:daftary/features/people/domain/usecases/watch_archived_people.dart';
import 'package:daftary/features/people/presentation/cubit/archived_people_cubit.dart';
import 'package:daftary/features/people/presentation/pages/archived_people_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/watch_stubs.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

/// A minimal router fixture reproducing `/people/archived` <-> `/people/:id`
/// (mirroring `test/widget/main_shell_test.dart`'s pattern). The detail
/// destination is a placeholder — this test is about `ArchivedPeoplePage`'s
/// own reload behavior, not the destination screen.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/people/archived',
    routes: [
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
  late FakeTableChanges changes;

  final now = DateTime(2026);
  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed',
    isArchived: true,
    createdAt: now,
    updatedAt: now,
  );
  final sara = Person(
    id: 'p2',
    name: 'Sara',
    isArchived: true,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    peopleRepository = MockPeopleRepository();
    changes = FakeTableChanges();
    stubPeopleWatches(peopleRepository, changes);

    getIt.registerFactory<ArchivedPeopleCubit>(
      () => ArchivedPeopleCubit(
        WatchArchivedPeople(peopleRepository),
        RestorePerson(peopleRepository),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await changes.close();
  });

  testWidgets(
    'returning from its own detail push needs no reload — the list is live '
    '(User Story 2, 021 FR-031)',
    (tester) async {
      when(
        () => peopleRepository.searchArchivedPeople(
          nameQuery: any(named: 'nameQuery'),
        ),
      ).thenAnswer((_) async => Right([ahmed]));

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      verify(
        () => peopleRepository.searchArchivedPeople(
          nameQuery: any(named: 'nameQuery'),
        ),
      ).called(1);

      await tester.tap(find.text('Ahmed'));
      await tester.pumpAndSettle();
      expect(find.text('Detail p1'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(ArchivedPeoplePage), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      verifyNever(
        () => peopleRepository.searchArchivedPeople(
          nameQuery: any(named: 'nameQuery'),
        ),
      );
    },
  );

  testWidgets(
    'search term is preserved while a person archived on the detail screen '
    'appears live (FR-005, 021 FR-031)',
    (tester) async {
      when(
        () => peopleRepository.searchArchivedPeople(nameQuery: null),
      ).thenAnswer((_) async => Right([ahmed]));
      when(
        () => peopleRepository.searchArchivedPeople(nameQuery: 'a'),
      ).thenAnswer((_) async => Right([ahmed]));

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ArchivedPeoplePage)),
      )!;

      final searchField = find.ancestor(
        of: find.text(l10n.searchPeopleHint),
        matching: find.byType(TextField),
      );
      await tester.enterText(searchField, 'a');
      await tester.pumpAndSettle();
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Sara'), findsNothing);

      // Sara gets archived while the user is on Ahmed's detail screen —
      // the live list (with the "a" filter still applied, which she now
      // also matches) must surface her by the time the user returns.
      when(
        () => peopleRepository.searchArchivedPeople(nameQuery: 'a'),
      ).thenAnswer((_) async => Right([ahmed, sara]));

      await tester.tap(find.text('Ahmed'));
      await tester.pumpAndSettle();
      changes.notify();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('a'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Sara'), findsOneWidget);
      verify(
        () => peopleRepository.searchArchivedPeople(nameQuery: 'a'),
      ).called(2);
    },
  );

  testWidgets('Arabic: the archived list renders its Arabic title and '
      'restore action right-to-left (RTL-09; the page shows no balance or '
      'amount)', (tester) async {
    when(
      () => peopleRepository.searchArchivedPeople(
        nameQuery: any(named: 'nameQuery'),
      ),
    ).thenAnswer((_) async => Right([ahmed]));

    await tester.pumpWidget(_wrap(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(find.text(l10n.archivedPeopleTitle), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text(l10n.restoreAction), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(ArchivedPeoplePage))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
