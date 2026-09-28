import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_filter.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/usecases/get_occasions_list.dart';
import 'package:daftary/features/occasions/domain/usecases/restore_occasion.dart';
import 'package:daftary/features/occasions/presentation/cubit/archived_occasions_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/archived_occasions_state.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasions_list_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasions_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOccasionsList extends Mock implements GetOccasionsList {}

class MockRestoreOccasion extends Mock implements RestoreOccasion {}

/// T062 — the occasions list (FR-015/FR-020) and the archived list (FR-014).
void main() {
  late MockGetOccasionsList getOccasionsList;
  late MockRestoreOccasion restoreOccasion;

  Occasion occasion(
    String id,
    DateTime date, {
    String type = OccasionType.wedding,
    bool isArchived = false,
  }) => Occasion(
    id: id,
    idempotencyKey: 'key-$id',
    name: 'Occasion $id',
    date: date,
    type: type,
    createdAt: date,
    updatedAt: date,
    isArchived: isArchived,
  );

  final newest = occasion('o3', DateTime(2026, 9, 20));
  final middle = occasion(
    'o2',
    DateTime(2026, 5, 10),
    type: OccasionType.condolence,
  );
  final oldest = occasion('o1', DateTime(2026, 1, 5));

  setUp(() {
    getOccasionsList = MockGetOccasionsList();
    restoreOccasion = MockRestoreOccasion();
  });

  void stubList(
    List<Occasion> result, {
    OccasionFilter? filter,
    bool includeArchived = false,
  }) {
    when(
      () => getOccasionsList(
        filter: filter ?? any(named: 'filter'),
        includeArchived: includeArchived,
      ),
    ).thenAnswer((_) async => Right(result));
  }

  group('OccasionsListCubit', () {
    blocTest<OccasionsListCubit, OccasionsListState>(
      'loads the list in the order the query returned it, newest first '
      '(FR-015) — never re-sorted here',
      build: () {
        stubList([newest, middle, oldest]);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.occasions.map((o) => o.id), ['o3', 'o2', 'o1']);
        expect(cubit.state.hasAnyOccasion, isTrue);
        expect(cubit.state.status, OccasionsListStatus.success);
      },
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'a name search is pushed into the query, not filtered in memory',
      build: () {
        stubList([newest]);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) => cubit.searchChanged('wedding'),
      verify: (cubit) {
        expect(cubit.state.filter.nameQuery, 'wedding');
        final captured =
            verify(
                  () => getOccasionsList(
                    filter: captureAny(named: 'filter'),
                    includeArchived: false,
                  ),
                ).captured.last
                as OccasionFilter?;
        expect(captured?.nameQuery, 'wedding');
      },
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'clearing the search drops the criterion rather than sending an '
      'empty string the query would have to special-case',
      build: () {
        stubList([newest, middle, oldest]);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) async {
        await cubit.searchChanged('wedding');
        await cubit.searchChanged('   ');
      },
      verify: (cubit) => expect(cubit.state.filter.nameQuery, isNull),
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'filters by type, and deselecting the chip clears it (FR-015)',
      build: () {
        stubList([middle]);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) async {
        await cubit.typeChanged(OccasionType.condolence);
        expect(cubit.state.filter.type, OccasionType.condolence);
        await cubit.typeChanged(null);
      },
      verify: (cubit) => expect(cubit.state.filter.type, isNull),
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'filters by date range (FR-015)',
      build: () {
        stubList([middle]);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) => cubit.dateRangeChanged(
        from: DateTime(2026, 4, 1),
        to: DateTime(2026, 6, 30),
      ),
      verify: (cubit) {
        expect(cubit.state.filter.fromDate, DateTime(2026, 4, 1));
        expect(cubit.state.filter.toDate, DateTime(2026, 6, 30));
      },
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'clearFilters resets every criterion at once',
      build: () {
        stubList([newest, middle, oldest]);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) async {
        await cubit.searchChanged('wedding');
        await cubit.typeChanged(OccasionType.wedding);
        await cubit.clearFilters();
      },
      verify: (cubit) => expect(cubit.state.filter.isEmpty, isTrue),
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'an empty result with no filter is the first-run state, which offers '
      'to create the first occasion (FR-020)',
      build: () {
        stubList(const []);
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.isEmptyOverall, isTrue);
        expect(cubit.state.isEmptyForFilter, isFalse);
      },
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'an empty result WITH a filter is the no-match state instead — the '
      'two cannot be told apart from an empty list alone (FR-020)',
      build: () {
        // Filtered read finds nothing; the unfiltered read behind it
        // proves occasions do exist.
        when(
          () => getOccasionsList(
            filter: any(named: 'filter'),
            includeArchived: false,
          ),
        ).thenAnswer((invocation) async {
          final filter = invocation.namedArguments[#filter] as OccasionFilter?;
          return Right(
            filter == null ? [newest, middle, oldest] : <Occasion>[],
          );
        });
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) => cubit.searchChanged('nothing matches this'),
      verify: (cubit) {
        expect(cubit.state.isEmptyForFilter, isTrue);
        expect(cubit.state.isEmptyOverall, isFalse);
        expect(cubit.state.hasAnyOccasion, isTrue);
      },
    );

    blocTest<OccasionsListCubit, OccasionsListState>(
      'surfaces a failure typed rather than rendering an empty list as if '
      'the user simply had no occasions',
      build: () {
        when(
          () => getOccasionsList(
            filter: any(named: 'filter'),
            includeArchived: false,
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('db gone')));
        return OccasionsListCubit(getOccasionsList);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, OccasionsListStatus.failure);
        expect(cubit.state.failure, isA<CacheFailure>());
        expect(cubit.state.isEmptyOverall, isFalse);
      },
    );
  });

  group('ArchivedOccasionsCubit (FR-014)', () {
    final archived = occasion('a1', DateTime(2026, 3, 3), isArchived: true);

    blocTest<ArchivedOccasionsCubit, ArchivedOccasionsState>(
      'lists only the archived half of the widened query',
      build: () {
        stubList([newest, archived], includeArchived: true);
        return ArchivedOccasionsCubit(getOccasionsList, restoreOccasion);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.occasions.map((o) => o.id), ['a1']);
      },
    );

    blocTest<ArchivedOccasionsCubit, ArchivedOccasionsState>(
      'restoring refreshes the list so the occasion leaves this screen',
      build: () {
        var restored = false;
        when(
          () => getOccasionsList(
            filter: any(named: 'filter'),
            includeArchived: true,
          ),
        ).thenAnswer((_) async => Right(restored ? <Occasion>[] : [archived]));
        when(() => restoreOccasion(any())).thenAnswer((_) async {
          restored = true;
          return const Right(unit);
        });
        return ArchivedOccasionsCubit(getOccasionsList, restoreOccasion);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.restore('a1');
      },
      verify: (cubit) {
        verify(() => restoreOccasion('a1')).called(1);
        expect(cubit.state.occasions, isEmpty);
      },
    );

    blocTest<ArchivedOccasionsCubit, ArchivedOccasionsState>(
      'reports an empty archive as an empty state, not a failure',
      build: () {
        stubList(const [], includeArchived: true);
        return ArchivedOccasionsCubit(getOccasionsList, restoreOccasion);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
    );
  });
}
