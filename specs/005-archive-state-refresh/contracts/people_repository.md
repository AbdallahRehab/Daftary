# Contract: PeopleRepository — no interface change

This feature has no external/network API (local-only, same as feature 002 — see `specs/002-localization-language-switch/contracts/settings_repository.md` for the project's general contract-documentation convention). The equivalent contract boundary for this feature would be the Domain repository interface `PeopleRepository` (`lib/features/people/domain/repositories/people_repository.dart`), per constitution Principle VI.

**This feature does not change that interface.** Documented explicitly here rather than fabricating a diff, per planning instructions.

```dart
abstract class PeopleRepository {
  // ...createPerson / confirmCreateDespiteDuplicate / editPerson / deletePerson
  // / getPersonById unchanged, omitted here — see the source file.

  /// Archives a person (FR-017/FR-018). Always succeeds for an existing
  /// person id — archiving has no transaction-count precondition.
  Future<Either<Failure, Unit>> archivePerson(String personId);

  /// Restores an archived person back to the active list (FR-018).
  Future<Either<Failure, Unit>> restorePerson(String personId);

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
}
```

**Why no change**: research.md (Decision 1) traces the root cause of the reported staleness bug entirely to the Presentation layer — specific `context.push(...)` call sites in `PeopleListPage`/`ArchivedPeoplePage` that don't reload their owning Cubit on return, while sibling call sites in the same files already do. `archivePerson`/`restorePerson`/`searchActivePeople`/`searchArchivedPeople` already do exactly what their names promise: mutate or query the current, correct `isArchived` state with no caching or staleness of their own (each call reaches the database fresh — `PeopleRepositoryImpl`, `lib/features/people/data/repositories/people_repository_impl.dart:136-217`). No new method, no new parameter (e.g. no move to a reactive `watchActivePeople`/`watchArchivedPeople` — see research.md Decision 1's rejected alternative), and no signature change is needed to fix FR-001–FR-009.

**What does change** (Presentation layer only, not this contract):
- `PersonListCubit`/`ArchivedPeopleCubit` gain a `processingPersonId` state field and a re-entrancy guard in `archive()`/`restore()` (data-model.md) — internal to the Cubit, not part of any interface Data implements.
- `PeopleListPage`/`ArchivedPeoplePage` gain `await`+reload after every outgoing `context.push(...)` (research.md Decision 1) — internal to those widgets, not a contract.

**Failure modes** (unchanged): `NotFoundFailure` (archive/restore target id no longer exists), `CacheFailure` (local DB I/O error). Both already surface through the existing `errorMessage` state field and existing `AppEmptyView`/snackbar-style error presentation (FR-007) — no new failure type is introduced.
