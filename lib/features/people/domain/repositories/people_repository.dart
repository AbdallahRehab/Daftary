import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../transactions/domain/entities/person_balance.dart';
import '../entities/person.dart';

/// Domain/Data boundary for everything about a [Person] (constitution
/// Principle VI). This feature has no network layer, so this interface
/// itself is the contract Presentation and Data both depend on.
abstract class PeopleRepository {
  /// Creates a person. Returns [PossibleDuplicateFailure] instead of
  /// inserting when an existing person's normalized name exactly matches,
  /// prefixes, or is contained within [name] (FR-003) — the caller decides
  /// whether to proceed via [confirmCreateDespiteDuplicate] or select the
  /// existing person instead. Never silently merges.
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  });

  /// Bypasses the duplicate check for a name the user has explicitly
  /// confirmed as a distinct new person.
  Future<Either<Failure, Person>> confirmCreateDespiteDuplicate({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  });

  /// Full field edit. Does not affect archive state.
  Future<Either<Failure, Person>> editPerson({
    required String personId,
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  });

  /// Archives a person (FR-017/FR-018). Always succeeds for an existing
  /// person id — archiving has no transaction-count precondition.
  Future<Either<Failure, Unit>> archivePerson(String personId);

  /// Restores an archived person back to the active list (FR-018).
  Future<Either<Failure, Unit>> restorePerson(String personId);

  /// Permanently deletes a person. Returns `PersonHasTransactionsFailure`
  /// if the person has any transaction (including soft-deleted ones); the
  /// caller should offer archiving instead (FR-017).
  Future<Either<Failure, Unit>> deletePerson(String personId);

  /// Active people only, optionally filtered by [nameQuery] and/or
  /// [statusFilter] (FR-019). Ordered by name.
  Future<Either<Failure, List<Person>>> searchActivePeople({
    String? nameQuery,
    RelationshipStatus? statusFilter,
  });

  /// Archived people only (FR-018), optionally filtered by [nameQuery].
  Future<Either<Failure, List<Person>>> searchArchivedPeople({
    String? nameQuery,
  });

  Future<Either<Failure, Person>> getPersonById(String personId);

  /// FR-010a: whether at least one Person record exists at all — active
  /// OR archived (unlike [searchActivePeople], which excludes archived).
  /// An archived-only install still proves prior real use.
  Future<Either<Failure, bool>> hasAnyPerson();
}
