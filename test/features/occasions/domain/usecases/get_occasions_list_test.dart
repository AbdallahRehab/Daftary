import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_filter.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasions_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late GetOccasionsList getOccasionsList;

  Occasion buildOccasion({
    required String id,
    required String name,
    required DateTime date,
    String type = OccasionType.wedding,
    bool isArchived = false,
  }) {
    return Occasion(
      id: id,
      idempotencyKey: 'key-$id',
      name: name,
      date: date,
      type: type,
      isArchived: isArchived,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  final march = buildOccasion(
    id: 'o1',
    name: 'Ahmed wedding',
    date: DateTime(2026, 3, 14),
  );
  final february = buildOccasion(
    id: 'o2',
    name: 'Mona engagement',
    date: DateTime(2026, 2, 2),
    type: OccasionType.engagement,
  );
  final january = buildOccasion(
    id: 'o3',
    name: 'Sara birthday',
    date: DateTime(2026, 1, 9),
    type: OccasionType.birthday,
  );
  final archived = buildOccasion(
    id: 'o4',
    name: 'Old wedding',
    date: DateTime(2025, 6, 1),
    isArchived: true,
  );

  void stubList(Either<Failure, List<Occasion>> response) {
    when(
      () => repository.getOccasionsList(
        filter: any(named: 'filter'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUpAll(() {
    registerFallbackValue(const OccasionFilter());
  });

  setUp(() {
    repository = MockOccasionsRepository();
    getOccasionsList = GetOccasionsList(repository);
  });

  test('returns the default view reverse-chronologically, newest first '
      '(FR-015)', () async {
    stubList(Right([march, february, january]));

    final result = await getOccasionsList();

    expect(result.toNullable()!.map((occasion) => occasion.id), [
      'o1',
      'o2',
      'o3',
    ]);
    final dates = result.toNullable()!.map((o) => o.date).toList();
    for (var i = 1; i < dates.length; i++) {
      expect(dates[i - 1].isAfter(dates[i]), isTrue);
    }
  });

  test('excludes archived occasions unless asked for them (FR-015)', () async {
    stubList(Right([march, february, january]));

    final result = await getOccasionsList();

    expect(result.toNullable(), isNot(contains(archived)));
    verify(
      () => repository.getOccasionsList(filter: null, includeArchived: false),
    ).called(1);
  });

  test('includeArchived: true asks for the archived view too '
      '(FR-014/FR-015)', () async {
    stubList(Right([march, february, january, archived]));

    final result = await getOccasionsList(includeArchived: true);

    expect(result.toNullable(), contains(archived));
    verify(
      () => repository.getOccasionsList(filter: null, includeArchived: true),
    ).called(1);
  });

  test('forwards a name query filter unchanged (FR-015)', () async {
    const filter = OccasionFilter(nameQuery: 'wedding');
    stubList(Right([march]));

    final result = await getOccasionsList(filter: filter);

    expect(result.toNullable(), [march]);
    verify(
      () => repository.getOccasionsList(filter: filter, includeArchived: false),
    ).called(1);
  });

  test('forwards a type filter unchanged (FR-015)', () async {
    const filter = OccasionFilter(type: OccasionType.engagement);
    stubList(Right([february]));

    final result = await getOccasionsList(filter: filter);

    expect(result.toNullable(), [february]);
    verify(
      () => repository.getOccasionsList(filter: filter, includeArchived: false),
    ).called(1);
  });

  test('forwards an inclusive date-range filter unchanged (FR-015)', () async {
    final filter = OccasionFilter(
      fromDate: DateTime(2026, 2, 1),
      toDate: DateTime(2026, 3, 31),
    );
    stubList(Right([march, february]));

    final result = await getOccasionsList(filter: filter);

    expect(result.toNullable()!.map((o) => o.id), ['o1', 'o2']);
    verify(
      () => repository.getOccasionsList(filter: filter, includeArchived: false),
    ).called(1);
  });

  test('forwards combined criteria as one filter rather than filtering in '
      'memory (FR-015)', () async {
    final filter = OccasionFilter(
      nameQuery: 'wedding',
      type: OccasionType.wedding,
      fromDate: DateTime(2026),
      toDate: DateTime(2026, 12, 31),
    );
    stubList(Right([march]));

    final result = await getOccasionsList(filter: filter);

    expect(result.toNullable(), [march]);
    expect(filter.isEmpty, isFalse);
    verify(
      () => repository.getOccasionsList(filter: filter, includeArchived: false),
    ).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('returns an empty list, not a failure, when nothing matches '
      '(FR-020)', () async {
    stubList(const Right([]));

    final result = await getOccasionsList(
      filter: const OccasionFilter(nameQuery: 'nothing'),
    );

    expect(result.toNullable(), isEmpty);
  });

  test('forwards a CacheFailure from the local database', () async {
    stubList(const Left(CacheFailure('Database unavailable')));

    final result = await getOccasionsList();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}
