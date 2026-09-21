import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/usecases/find_possible_duplicate_person.dart';

/// Direct `drift` access to the `people` table only. Cross-table reads
/// (e.g. a person's transaction count) live in [PeopleRepositoryImpl],
/// which also holds the shared [AppDatabase].
@injectable
class PeopleDao {
  PeopleDao(this._db);

  final AppDatabase _db;

  Future<PeopleData> insertPerson({
    required String id,
    required String name,
    required DateTime createdAt,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final companion = PeopleCompanion.insert(
      id: id,
      name: name,
      normalizedName: FindPossibleDuplicatePerson.normalize(name),
      phoneNumber: Value(phoneNumber),
      avatarPath: Value(avatarPath),
      relationshipTag: Value(relationshipTag),
      notes: Value(notes),
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: createdAt.millisecondsSinceEpoch,
    );
    await _db.into(_db.people).insert(companion);
    return (_db.select(_db.people)..where((p) => p.id.equals(id))).getSingle();
  }

  /// Every person, active and archived — used for the FR-003 duplicate
  /// check, which must consider both (Clarifications).
  Future<List<PeopleData>> getAllPeople() => _db.select(_db.people).get();

  Future<PeopleData?> getPersonById(String id) =>
      (_db.select(_db.people)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<PeopleData>> searchActivePeople({String? nameQuery}) {
    return _searchByArchiveState(isArchived: false, nameQuery: nameQuery);
  }

  Future<List<PeopleData>> searchArchivedPeople({String? nameQuery}) {
    return _searchByArchiveState(isArchived: true, nameQuery: nameQuery);
  }

  Future<List<PeopleData>> _searchByArchiveState({
    required bool isArchived,
    String? nameQuery,
  }) {
    final query = _db.select(_db.people)
      ..where((p) => p.isArchived.equals(isArchived));
    final trimmedQuery = nameQuery?.trim() ?? '';
    if (trimmedQuery.isNotEmpty) {
      final normalized = FindPossibleDuplicatePerson.normalize(trimmedQuery);
      query.where((p) => p.normalizedName.like('%$normalized%'));
    }
    query.orderBy([(p) => OrderingTerm(expression: p.name)]);
    return query.get();
  }

  Future<PeopleData> updatePerson({
    required String id,
    required String name,
    required DateTime updatedAt,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    await (_db.update(_db.people)..where((p) => p.id.equals(id))).write(
      PeopleCompanion(
        name: Value(name),
        normalizedName: Value(FindPossibleDuplicatePerson.normalize(name)),
        phoneNumber: Value(phoneNumber),
        avatarPath: Value(avatarPath),
        relationshipTag: Value(relationshipTag),
        notes: Value(notes),
        updatedAt: Value(updatedAt.millisecondsSinceEpoch),
      ),
    );
    return (_db.select(_db.people)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<void> setArchived(String id, bool isArchived, DateTime updatedAt) {
    return (_db.update(_db.people)..where((p) => p.id.equals(id))).write(
      PeopleCompanion(
        isArchived: Value(isArchived),
        updatedAt: Value(updatedAt.millisecondsSinceEpoch),
      ),
    );
  }

  /// Counts every transaction for [personId], including soft-deleted rows
  /// (data-model.md: a delete precondition must count those too, to keep
  /// audit history attributable).
  Future<int> countTransactionsForPerson(String personId) async {
    final countExpr = _db.moneyTransactions.id.count();
    final query = _db.selectOnly(_db.moneyTransactions)
      ..addColumns([countExpr])
      ..where(_db.moneyTransactions.personId.equals(personId));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<void> deletePerson(String id) =>
      (_db.delete(_db.people)..where((p) => p.id.equals(id))).go();

  /// FR-010a: whether at least one `Person` row exists at all — active or
  /// archived. A cheap `LIMIT 1` existence check, never a full list fetch.
  Future<bool> hasAnyPerson() async {
    final row = await (_db.select(_db.people)..limit(1)).getSingleOrNull();
    return row != null;
  }
}
