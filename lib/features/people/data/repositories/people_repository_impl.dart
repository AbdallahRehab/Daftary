import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/balance_queries.dart';
import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../../domain/entities/people_failures.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/usecases/find_possible_duplicate_person.dart';
import '../datasources/people_dao.dart';
import '../models/person_mapper.dart';

@LazySingleton(as: PeopleRepository)
class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl(this._dao, this._findPossibleDuplicatePerson, this._db);

  final PeopleDao _dao;
  final FindPossibleDuplicatePerson _findPossibleDuplicatePerson;
  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Left(ValidationFailure('Name is required'));
    }
    try {
      final existing = await _dao.getAllPeople();
      final matches = _findPossibleDuplicatePerson(
        trimmedName,
        existing.map((row) => row.toDomain()).toList(),
      );
      if (matches.isNotEmpty) {
        return Left(PossibleDuplicateFailure(matches));
      }
      return _insertPerson(
        name: trimmedName,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
        relationshipTag: relationshipTag,
        notes: notes,
      );
    } catch (e) {
      return Left(CacheFailure('Failed to create person: $e'));
    }
  }

  @override
  Future<Either<Failure, Person>> confirmCreateDespiteDuplicate({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Left(ValidationFailure('Name is required'));
    }
    try {
      return _insertPerson(
        name: trimmedName,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
        relationshipTag: relationshipTag,
        notes: notes,
      );
    } catch (e) {
      return Left(CacheFailure('Failed to create person: $e'));
    }
  }

  Future<Either<Failure, Person>> _insertPerson({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final row = await _dao.insertPerson(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      avatarPath: avatarPath,
      relationshipTag: relationshipTag,
      notes: notes,
      createdAt: DateTime.now(),
    );
    return Right(row.toDomain());
  }

  @override
  Future<Either<Failure, Person>> editPerson({
    required String personId,
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Left(ValidationFailure('Name is required'));
    }
    try {
      final existing = await _dao.getPersonById(personId);
      if (existing == null) {
        return const Left(NotFoundFailure('Person not found'));
      }
      final row = await _dao.updatePerson(
        id: personId,
        name: trimmedName,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
        relationshipTag: relationshipTag,
        notes: notes,
        updatedAt: DateTime.now(),
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to edit person: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> archivePerson(String personId) async {
    try {
      final existing = await _dao.getPersonById(personId);
      if (existing == null) {
        return const Left(NotFoundFailure('Person not found'));
      }
      await _dao.setArchived(personId, true, DateTime.now());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to archive person: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> restorePerson(String personId) async {
    try {
      final existing = await _dao.getPersonById(personId);
      if (existing == null) {
        return const Left(NotFoundFailure('Person not found'));
      }
      await _dao.setArchived(personId, false, DateTime.now());
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to restore person: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePerson(String personId) async {
    try {
      final existing = await _dao.getPersonById(personId);
      if (existing == null) {
        return const Left(NotFoundFailure('Person not found'));
      }
      final transactionCount = await _dao.countTransactionsForPerson(personId);
      if (transactionCount > 0) {
        return const Left(PersonHasTransactionsFailure());
      }
      await _dao.deletePerson(personId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete person: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Person>>> searchActivePeople({
    String? nameQuery,
    RelationshipStatus? statusFilter,
  }) async {
    try {
      final rows = await _dao.searchActivePeople(nameQuery: nameQuery);
      var people = rows.map((row) => row.toDomain()).toList();
      if (statusFilter != null) {
        final balances = await _db.netBalanceMinorUnitsForAllPeople();
        people = people.where((person) {
          final net = balances[person.id] ?? 0;
          final status = net > 0
              ? RelationshipStatus.theyOweYou
              : net < 0
              ? RelationshipStatus.youOweThem
              : RelationshipStatus.settled;
          return status == statusFilter;
        }).toList();
      }
      return Right(people);
    } catch (e) {
      return Left(CacheFailure('Failed to search people: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Person>>> searchArchivedPeople({
    String? nameQuery,
  }) async {
    try {
      final rows = await _dao.searchArchivedPeople(nameQuery: nameQuery);
      return Right(rows.map((row) => row.toDomain()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to search archived people: $e'));
    }
  }

  @override
  Future<Either<Failure, Person>> getPersonById(String personId) async {
    try {
      final row = await _dao.getPersonById(personId);
      if (row == null) {
        return const Left(NotFoundFailure('Person not found'));
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to load person: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAnyPerson() async {
    try {
      return Right(await _dao.hasAnyPerson());
    } catch (e) {
      return Left(CacheFailure('Failed to check for existing people: $e'));
    }
  }
}
