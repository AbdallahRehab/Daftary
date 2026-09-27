import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/stream_recorder.dart';
import '../../../../helpers/test_daos.dart';

/// 021 T029: the people lists are live — a write shows up with no reload.
void main() {
  late AppDatabase db;
  late PeopleRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
  });

  tearDown(() => db.close());

  List<String> names(Either<Failure, List<Person>> result) =>
      rightOf(result).map((p) => p.name).toList();

  test('the first emission equals searchActivePeople', () async {
    await repository.createPerson(name: 'Ahmed');
    await repository.createPerson(name: 'Mona');

    final first = await repository.watchActivePeople().first;

    expect(rightOf(first), rightOf(await repository.searchActivePeople()));
  });

  test('a created person appears in the active stream', () async {
    final active = StreamRecorder(repository.watchActivePeople());
    addTearDown(active.cancel);
    await active.waitFor((r) => names(r).isEmpty);

    await repository.createPerson(name: 'Ahmed');

    await active.waitFor((r) => names(r).contains('Ahmed'));
  });

  test('archiving moves a person from the active to the archived stream, '
      'and restoring moves them back', () async {
    final ahmed = rightOf(await repository.createPerson(name: 'Ahmed'));
    final active = StreamRecorder(repository.watchActivePeople());
    final archived = StreamRecorder(repository.watchArchivedPeople());
    addTearDown(active.cancel);
    addTearDown(archived.cancel);
    await active.waitFor((r) => names(r).contains('Ahmed'));
    await archived.waitFor((r) => names(r).isEmpty);

    await repository.archivePerson(ahmed.id);

    await active.waitFor((r) => names(r).isEmpty);
    await archived.waitFor((r) => names(r).contains('Ahmed'));

    await repository.restorePerson(ahmed.id);

    await active.waitFor((r) => names(r).contains('Ahmed'));
    await archived.waitForNext((r) => names(r).isEmpty);
  });

  test('a name query is applied to every emission', () async {
    final active = StreamRecorder(
      repository.watchActivePeople(nameQuery: 'mo'),
    );
    addTearDown(active.cancel);

    await repository.createPerson(name: 'Ahmed');
    await repository.createPerson(name: 'Mona');

    final result = await active.waitFor((r) => names(r).isNotEmpty);
    expect(names(result), ['Mona']);
  });

  test('a write that leaves the list unchanged emits nothing new', () async {
    await repository.createPerson(name: 'Ahmed');
    final active = StreamRecorder(repository.watchActivePeople());
    addTearDown(active.cancel);
    await active.waitFor((r) => names(r).isNotEmpty);
    await StreamRecorder.settle();
    final count = active.values.length;

    // The table is written (and notified), but every row reads the same.
    await db.update(db.people).write(const PeopleCompanion(notes: Value(null)));
    await StreamRecorder.settle();

    expect(active.values, hasLength(count));
  });
}
