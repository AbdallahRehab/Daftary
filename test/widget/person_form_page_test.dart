import 'package:daftary/core/design_system/app_button.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/archive_person.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/people/domain/usecases/delete_person.dart';
import 'package:daftary/features/people/domain/usecases/edit_person.dart';
import 'package:daftary/features/people/presentation/cubit/person_form_cubit.dart';
import 'package:daftary/features/people/presentation/pages/person_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

/// A minimal router fixture (mirroring `test/widget/main_shell_test.dart`
/// and `transaction_form_page.dart`'s equivalent 004-transaction-state-
/// refresh fix) reproducing the caller's `await context.push(...); if
/// (context.mounted) { reload(); }` idiom that `PersonFormPage`'s
/// pop()-based navigation (005-archive-state-refresh T031/T032) must
/// complete for.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _CallerPage()),
      GoRoute(
        path: '/edit',
        builder: (context, state) =>
            PersonFormPage(editingPerson: state.extra as Person?),
      ),
    ],
  );
}

class _CallerPage extends StatefulWidget {
  const _CallerPage();

  @override
  State<_CallerPage> createState() => _CallerPageState();
}

class _CallerPageState extends State<_CallerPage> {
  int reloadCount = 0;

  Future<void> _openEdit(BuildContext context, Person person) async {
    await context.push<Person?>('/edit', extra: person);
    if (context.mounted) {
      setState(() => reloadCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('reloadCount: $reloadCount'),
          Builder(
            builder: (context) => TextButton(
              onPressed: () => _openEdit(
                context,
                Person(
                  id: 'p1',
                  name: 'Ahmed',
                  isArchived: false,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ),
              child: const Text('Open Edit'),
            ),
          ),
        ],
      ),
    );
  }
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

  setUp(() {
    peopleRepository = MockPeopleRepository();

    getIt.registerFactory<PersonFormCubit>(
      () => PersonFormCubit(
        peopleRepository,
        CreatePerson(peopleRepository),
        EditPerson(peopleRepository),
        ArchivePerson(peopleRepository),
        DeletePerson(peopleRepository),
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets(
    'a successful save pops (not context.go()) when reached via a pushed '
    'route, so the caller\'s reload-on-return fires (FR-010)',
    (tester) async {
      final edited = Person(
        id: 'p1',
        name: 'Ahmed Updated',
        isArchived: false,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      when(
        () => peopleRepository.editPerson(
          personId: 'p1',
          name: any(named: 'name'),
          phoneNumber: any(named: 'phoneNumber'),
          relationshipTag: any(named: 'relationshipTag'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer((_) async => Right(edited));

      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('reloadCount: 0'), findsOneWidget);

      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonFormPage), findsOneWidget);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(PersonFormPage)),
      )!;
      await tester.tap(find.widgetWithText(AppButton, l10n.commonSave));
      await tester.pumpAndSettle();

      // Popped back to the same caller widget (not a `go()`-driven
      // remount), and the caller's own reload fired exactly once.
      expect(find.byType(PersonFormPage), findsNothing);
      expect(find.text('reloadCount: 1'), findsOneWidget);
    },
  );
}
