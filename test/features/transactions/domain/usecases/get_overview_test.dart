import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;
  late GetOverview getOverview;

  setUp(() {
    repository = MockTransactionsRepository();
    getOverview = GetOverview(repository);
  });

  test('delegates to the repository, including archived people with a non-zero '
      'balance in the totals/groupings (FR-024, Clarifications)', () async {
    const summary = OverviewSummary(
      totalOwedToUser: Money.egp(150000),
      totalUserOwes: Money.egp(20000),
      peopleTheyOweYou: [
        PersonSummary(
          personId: 'p1',
          name: 'Ahmed',
          net: Money.egp(150000),
          isArchived: false,
        ),
        PersonSummary(
          personId: 'p2',
          name: 'Old Contact',
          net: Money.egp(0), // never reached; see below
          isArchived: true,
        ),
      ],
      peopleYouOweThem: [
        PersonSummary(
          personId: 'p3',
          name: 'Sara',
          net: Money.egp(-20000),
          isArchived: false,
        ),
      ],
      settledCount: 1,
    );
    when(
      () => repository.getOverview(),
    ).thenAnswer((_) async => const Right(summary));

    final result = await getOverview();

    final overview = result.getOrElse((_) => throw StateError('x'));
    expect(overview.totalOwedToUser, const Money.egp(150000));
    expect(overview.totalUserOwes, const Money.egp(20000));
    expect(
      overview.peopleTheyOweYou.any((p) => p.personId == 'p2' && p.isArchived),
      isTrue,
    );
  });

  test(
    'settledCount counts people with a zero net; isAllSettled reflects empty groupings',
    () {
      const allSettled = OverviewSummary(
        totalOwedToUser: Money.egp(0),
        totalUserOwes: Money.egp(0),
        peopleTheyOweYou: [],
        peopleYouOweThem: [],
        settledCount: 3,
      );
      expect(allSettled.isAllSettled, isTrue);

      const notSettled = OverviewSummary(
        totalOwedToUser: Money.egp(1),
        totalUserOwes: Money.egp(0),
        peopleTheyOweYou: [
          PersonSummary(
            personId: 'p1',
            name: 'Ahmed',
            net: Money.egp(1),
            isArchived: false,
          ),
        ],
        peopleYouOweThem: [],
        settledCount: 0,
      );
      expect(notSettled.isAllSettled, isFalse);
    },
  );
}
