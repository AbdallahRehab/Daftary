import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/balance_queries.dart';
import '../../../../core/error/failure.dart';
import '../../../currency/domain/entities/conversion_context.dart';
import '../../../currency/domain/usecases/get_conversion_context.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../../../transactions/domain/services/person_balance_calculator.dart';
import '../../domain/entities/people_failures.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/people_repository.dart';
import '../../domain/usecases/find_possible_duplicate_person.dart';
import '../datasources/people_dao.dart';
import '../models/person_mapper.dart';

@LazySingleton(as: PeopleRepository)
class PeopleRepositoryImpl implements PeopleRepository {
  /// [getConversionContext] supplies the primary currency + rates used to
  /// derive each person's status for [searchActivePeople]'s status filter
  /// (018). Always injected in the app; when omitted (single-currency tests
  /// only) the EGP-only context is used.
  PeopleRepositoryImpl(
    this._dao,
    this._findPossibleDuplicatePerson,
    this._db, {
    GetConversionContext? getConversionContext,
  }) : _getConversionContext = getConversionContext;

  final PeopleDao _dao;
  final FindPossibleDuplicatePerson _findPossibleDuplicatePerson;
  final AppDatabase _db;
  final GetConversionContext? _getConversionContext;
  static const _uuid = Uuid();
  static const _calculator = PersonBalanceCalculator();

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
      return await _insertPerson(
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
      return await _insertPerson(
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
        final getContext = _getConversionContext;
        final contextResult = getContext == null
            ? const Right<Failure, ConversionContext>(ConversionContext.egpOnly)
            : await getContext();
        if (contextResult case Left(:final value)) return Left(value);
        final context = contextResult.getOrElse(
          (_) => ConversionContext.egpOnly,
        );
        final balances = await _db.netBalanceMinorUnitsByCurrencyForAllPeople();
        // A blocked balance whose currencies point in opposite directions
        // has a `null` status and so matches no status filter — it still
        // appears under "All".
        people = people.where((person) {
          final balance = _calculator.calculate(
            personId: person.id,
            nativeNetsByCode: balances[person.id] ?? const {},
            context: context,
          );
          return balance.status == statusFilter;
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
