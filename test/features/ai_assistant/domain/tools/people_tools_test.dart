import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_owed_overview_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/get_person_balance_tool.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:daftary/features/transactions/domain/usecases/get_person_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPersonBalance extends Mock implements GetPersonBalance {}

class MockGetOverview extends Mock implements GetOverview {}

class MockPeopleRepository extends Mock implements PeopleRepository {}

Person _person(String id, String name, {bool archived = false}) => Person(
  id: id,
  name: name,
  isArchived: archived,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('GetPersonBalanceTool', () {
    late MockGetPersonBalance getPersonBalance;
    late MockPeopleRepository people;
    late GetPersonBalanceTool tool;

    setUp(() {
      getPersonBalance = MockGetPersonBalance();
      people = MockPeopleRepository();
      tool = GetPersonBalanceTool(getPersonBalance, people);
    });

    void stubPeople(List<Person> active, [List<Person> archived = const []]) {
      when(
        () => people.searchActivePeople(),
      ).thenAnswer((_) async => Right(active));
      when(
        () => people.searchArchivedPeople(),
      ).thenAnswer((_) async => Right(archived));
    }

    test('resolves the name and passes GetPersonBalance\'s net and status '
        'through unchanged', () async {
      stubPeople([_person('p1', 'Ahmed Ali'), _person('p2', 'Mona')]);
      when(() => getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(150075))),
      );

      final result = (await tool({
        AIToolArgs.personName: ' ahmed  ali ',
      })).getOrElse((f) => fail('$f'));

      verify(() => getPersonBalance('p1')).called(1);
      expect(result.toolName, AIToolNames.getPersonBalance);
      expect(result.sourceUseCase, 'GetPersonBalance');
      expect(result.foundData, isTrue);
      expect(result.data['personName'], 'Ahmed Ali');
      expect(result.data['netMinorUnits'], 150075);
      expect(result.data['status'], 'theyOweYou');
      expect(result.data[AIToolDataKeys.currency], 'EGP');
    });

    test('a negative net stays negative, status youOweThem', () async {
      stubPeople([_person('p2', 'Mona')]);
      when(() => getPersonBalance('p2')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p2', net: Money.egp(-4999))),
      );

      final result = (await tool({
        AIToolArgs.personName: 'Mona',
      })).getOrElse((f) => fail('$f'));

      expect(result.data['netMinorUnits'], -4999);
      expect(result.data['status'], 'youOweThem');
    });

    test('finds archived people too', () async {
      stubPeople([], [_person('p9', 'Old Friend', archived: true)]);
      when(() => getPersonBalance('p9')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p9', net: Money.egp(0))),
      );

      final result = (await tool({
        AIToolArgs.personName: 'old friend',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isTrue);
      expect(result.data['status'], 'settled');
    });

    test('an exact match wins over partial matches', () async {
      stubPeople([_person('p1', 'Ahmed'), _person('p2', 'Ahmed Ali')]);
      when(() => getPersonBalance('p1')).thenAnswer(
        (_) async =>
            const Right(PersonBalance(personId: 'p1', net: Money.egp(10))),
      );

      final result = (await tool({
        AIToolArgs.personName: 'Ahmed',
      })).getOrElse((f) => fail('$f'));

      expect(result.data['personName'], 'Ahmed');
    });

    test('foundData=false for an unmatched name; balance never read', () async {
      stubPeople([_person('p1', 'Ahmed')]);

      final result = (await tool({
        AIToolArgs.personName: 'Khaled',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.personNotFound);
      expect(result.data.containsKey('netMinorUnits'), isFalse);
      verifyZeroInteractions(getPersonBalance);
    });

    test('foundData=false with candidates for an ambiguous name', () async {
      stubPeople([_person('p1', 'Ahmed Ali'), _person('p2', 'Ahmed Samir')]);

      final result = (await tool({
        AIToolArgs.personName: 'ahmed',
      })).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.ambiguousPerson);
      expect(result.data['candidates'], ['Ahmed Ali', 'Ahmed Samir']);
      verifyZeroInteractions(getPersonBalance);
    });

    test('a blank or missing personName → ValidationFailure', () async {
      for (final args in <Map<String, Object?>>[
        {},
        {AIToolArgs.personName: '   '},
        {AIToolArgs.personName: 7},
      ]) {
        final result = await tool(args);
        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      }
      verifyZeroInteractions(people);
      verifyZeroInteractions(getPersonBalance);
    });

    test('passes a use-case failure through unchanged', () async {
      stubPeople([_person('p1', 'Ahmed')]);
      when(
        () => getPersonBalance('p1'),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      final result = await tool({AIToolArgs.personName: 'Ahmed'});

      expect(result, const Left<Failure, Never>(CacheFailure('db')));
    });
  });

  group('GetOwedOverviewTool', () {
    late MockGetOverview getOverview;
    late GetOwedOverviewTool tool;

    setUp(() {
      getOverview = MockGetOverview();
      tool = GetOwedOverviewTool(getOverview);
    });

    test(
      'copies OverviewSummary\'s totals and groupings through unchanged',
      () async {
        when(() => getOverview()).thenAnswer(
          (_) async => const Right(
            OverviewSummary(
              totalOwedToUser: Money.egp(150075),
              totalUserOwes: Money.egp(20001),
              peopleTheyOweYou: [
                PersonSummary(
                  personId: 'p1',
                  name: 'Ahmed',
                  net: Money.egp(150075),
                  isArchived: false,
                ),
              ],
              peopleYouOweThem: [
                PersonSummary(
                  personId: 'p2',
                  name: 'Mona',
                  net: Money.egp(-20001),
                  isArchived: true,
                ),
              ],
              settledCount: 3,
            ),
          ),
        );

        final result = (await tool({})).getOrElse((f) => fail('$f'));

        verify(() => getOverview()).called(1);
        expect(result.toolName, AIToolNames.getOwedOverview);
        expect(result.sourceUseCase, 'GetOverview');
        expect(result.foundData, isTrue);
        expect(result.data['totalOwedToUserMinorUnits'], 150075);
        expect(result.data['totalUserOwesMinorUnits'], 20001);
        expect(result.data['peopleTheyOweYou'], [
          {'personName': 'Ahmed', 'netMinorUnits': 150075},
        ]);
        expect(result.data['peopleYouOweThem'], [
          {'personName': 'Mona', 'netMinorUnits': -20001},
        ]);
        expect(result.data['settledCount'], 3);
      },
    );

    test('an all-settled book is a real answer (foundData true)', () async {
      when(() => getOverview()).thenAnswer(
        (_) async => const Right(
          OverviewSummary(
            totalOwedToUser: Money.egp(0),
            totalUserOwes: Money.egp(0),
            peopleTheyOweYou: [],
            peopleYouOweThem: [],
            settledCount: 2,
          ),
        ),
      );

      final result = (await tool({})).getOrElse((f) => fail('$f'));

      expect(result.foundData, isTrue);
      expect(result.data['totalOwedToUserMinorUnits'], 0);
    });

    test('foundData=false with zero people recorded', () async {
      when(() => getOverview()).thenAnswer(
        (_) async => const Right(
          OverviewSummary(
            totalOwedToUser: Money.egp(0),
            totalUserOwes: Money.egp(0),
            peopleTheyOweYou: [],
            peopleYouOweThem: [],
            settledCount: 0,
          ),
        ),
      );

      final result = (await tool({})).getOrElse((f) => fail('$f'));

      expect(result.foundData, isFalse);
      expect(result.data['reason'], AIToolNoDataReasons.noPeopleRecorded);
      expect(result.data.containsKey('totalOwedToUserMinorUnits'), isFalse);
    });

    test('passes a use-case failure through unchanged', () async {
      when(
        () => getOverview(),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      expect(await tool({}), const Left<Failure, Never>(CacheFailure('db')));
    });
  });
}
