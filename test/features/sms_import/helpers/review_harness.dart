import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/people/domain/entities/people_failures.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/sms_import/domain/usecases/add_imported_transaction.dart';
import 'package:daftary/features/sms_import/domain/usecases/check_duplicates.dart';
import 'package:daftary/features/sms_import/domain/usecases/close_as_duplicate.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/mute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/show_original_message.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_sms_import_settings.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'fakes.dart';

/// Synthetic categories (seed ids, invented names).
Category testCategory(
  String id,
  FinanceEntryType type, {
  String? name,
  bool archived = false,
}) => Category(
  id: id,
  name: name ?? id,
  type: type,
  icon: 'category',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isArchived: archived,
);

Person testPerson(String id, String name) => Person(
  id: id,
  name: name,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Active categories by type; archived ones are filtered as the real
/// repository does.
class FakeCategoryRepository extends Fake implements CategoryRepository {
  FakeCategoryRepository(this.categories);

  final List<Category> categories;

  @override
  Future<Either<Failure, List<Category>>> getCategories({
    required CategoryType type,
    bool includeArchived = false,
  }) async => Right([
    for (final c in categories)
      if (c.type == type && (includeArchived || !c.isArchived)) c,
  ]);
}

/// People by id, a name search, and the similar-name rule of
/// `createPerson`.
class FakePeopleRepository extends Fake implements PeopleRepository {
  FakePeopleRepository(List<Person> people)
    : people = {for (final p in people) p.id: p};

  final Map<String, Person> people;
  int _created = 0;

  @override
  Future<Either<Failure, Person>> getPersonById(String personId) async {
    final person = people[personId];
    return person == null
        ? const Left(NotFoundFailure('missing'))
        : Right(person);
  }

  @override
  Future<Either<Failure, List<Person>>> searchActivePeople({
    String? nameQuery,
    RelationshipStatus? statusFilter,
  }) async => Right([
    for (final p in people.values)
      if (p.name.toLowerCase().contains((nameQuery ?? '').toLowerCase())) p,
  ]);

  @override
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final similar = [
      for (final p in people.values)
        if (p.name.toLowerCase() == name.toLowerCase()) p,
    ];
    if (similar.isNotEmpty) return Left(PossibleDuplicateFailure(similar));
    return confirmCreateDespiteDuplicate(name: name);
  }

  @override
  Future<Either<Failure, Person>> confirmCreateDespiteDuplicate({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? relationshipTag,
    String? notes,
  }) async {
    final person = testPerson('new-person-${_created++}', name);
    people[person.id] = person;
    return Right(person);
  }
}

/// Everything an [ImportReviewCubit] needs, on in-memory fakes.
class ReviewHarness {
  ReviewHarness({
    List<Category>? categories,
    List<Person>? people,
    AddImportedTransaction? addOverride,
    FakeSmsImportRepository? repositoryOverride,
  }) {
    repository = repositoryOverride ?? FakeSmsImportRepository();
    lookup = FakeSmsDuplicateLookup();
    leases = FakeReviewLeaseRegistry();
    this.categories = FakeCategoryRepository(
      categories ??
          [
            testCategory('seed_groceries', FinanceEntryType.expense),
            testCategory('seed_other', FinanceEntryType.expense),
            testCategory('seed_salary', FinanceEntryType.income),
          ],
    );
    this.people = FakePeopleRepository(
      people ?? [testPerson('person-1', 'Mona')],
    );
    final check = CheckDuplicates(lookup, FakeBankReferencePolicy());
    add = addOverride ?? AddImportedTransaction(repository, check);
    checkDuplicates = check;
    settings = FakeSmsImportSettingsRepository(pending: repository);
  }

  late final FakeSmsImportRepository repository;
  late final FakeSmsDuplicateLookup lookup;
  late final FakeReviewLeaseRegistry leases;
  late final FakeCategoryRepository categories;
  late final FakePeopleRepository people;
  late final AddImportedTransaction add;
  late final CheckDuplicates checkDuplicates;

  /// Mutes delete this repository's pending rows of the sender (T132).
  late final FakeSmsImportSettingsRepository settings;

  /// [withSettings] false builds it without the cash-preference reader,
  /// as the direct constructions in older suites do.
  ImportReviewCubit build({bool withSettings = true}) => ImportReviewCubit(
    GetPendingImport(repository),
    GetPendingImports(repository),
    add,
    checkDuplicates,
    ShowOriginalMessage(repository),
    leases,
    GetCategories(categories),
    people,
    CreatePerson(people),
    CloseAsDuplicate(repository),
    ignoreImport: IgnoreImport(repository),
    muteSender: MuteSender(settings),
    watchSettings: withSettings ? WatchSmsImportSettings(settings) : null,
  );

  Future<void> dispose() async {
    await settings.close();
    await repository.close();
  }
}
