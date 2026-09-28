import 'dart:async';

import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// 021: a stand-in for the database's table-change notifications in tests
/// that mock a repository. Every `watch*` stream stubbed through it reads
/// once when listened to, then again on each [notify] — exactly how the
/// real `changesOf` + `reRead` streams behave (including dropping a re-read
/// that returns an equal result).
class FakeTableChanges {
  final _changes = StreamController<void>.broadcast();

  /// Simulates a write to a watched table.
  void notify() => _changes.add(null);

  /// Fires on listen, then on every [notify].
  Stream<void> signal() {
    late final StreamController<void> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<void>(
      onListen: () {
        controller.add(null);
        subscription = _changes.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  Future<void> close() => _changes.close();
}

/// Answers `watchActivePeople`/`watchArchivedPeople` by re-running the
/// test's `searchActivePeople`/`searchArchivedPeople` stubs.
void stubPeopleWatches(PeopleRepository repository, FakeTableChanges changes) {
  when(
    () => repository.watchActivePeople(
      nameQuery: any(named: 'nameQuery'),
      statusFilter: any(named: 'statusFilter'),
    ),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.searchActivePeople(
        nameQuery: invocation.namedArguments[#nameQuery] as String?,
        statusFilter:
            invocation.namedArguments[#statusFilter] as RelationshipStatus?,
      ),
    ),
  );
  when(() => repository.watchPersonById(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getPersonById(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
  when(
    () => repository.watchArchivedPeople(nameQuery: any(named: 'nameQuery')),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.searchArchivedPeople(
        nameQuery: invocation.namedArguments[#nameQuery] as String?,
      ),
    ),
  );
}

/// Answers the four transactions `watch*` methods by re-running the test's
/// matching `get*` stubs.
void stubTransactionsWatches(
  TransactionsRepository repository,
  FakeTableChanges changes,
) {
  registerFallbackValue(<String>[]);
  when(() => repository.watchPersonHistory(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getPersonHistory(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
  when(() => repository.watchPersonBalance(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getPersonBalance(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
  when(() => repository.watchPersonBalances(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getPersonBalances(
        invocation.positionalArguments.first as List<String>,
      ),
    ),
  );
  when(
    repository.watchOverview,
  ).thenAnswer((_) => changes.signal().reRead(repository.getOverview));
  // 008: most flows have no occasion contributions, so "no names" is the
  // default; a test that cares stubs `getOccasionNamesForPerson` after this.
  when(
    () => repository.getOccasionNamesForPerson(any()),
  ).thenAnswer((_) async => const Right({}));
  when(() => repository.watchOccasionNamesForPerson(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getOccasionNamesForPerson(
        invocation.positionalArguments.first as String,
      ),
    ),
  );
}

/// Answers `watchHistory`/`watchSummaryTotals` by re-running the test's
/// `getHistory`/`getSummaryTotals` stubs.
void stubFinanceWatches(
  FinanceRepository repository,
  FakeTableChanges changes,
) {
  registerFallbackValue(DateRange(start: DateTime(2026), end: DateTime(2026)));
  when(
    () => repository.watchHistory(
      filter: any(named: 'filter'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getHistory(
        filter: invocation.namedArguments[#filter] as FinanceHistoryFilter?,
        limit: invocation.namedArguments[#limit] as int,
      ),
    ),
  );
  when(() => repository.watchSummaryTotals(any())).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getSummaryTotals(
        invocation.positionalArguments.first as DateRange,
      ),
    ),
  );
}

/// Answers `watchCategories` by re-running the test's `getCategories`
/// stubs.
void stubCategoryWatches(
  CategoryRepository repository,
  FakeTableChanges changes,
) {
  registerFallbackValue(CategoryType.expense);
  when(
    () => repository.watchCategories(
      type: any(named: 'type'),
      includeArchived: any(named: 'includeArchived'),
    ),
  ).thenAnswer(
    (invocation) => changes.signal().reRead(
      () => repository.getCategories(
        type: invocation.namedArguments[#type] as CategoryType,
        includeArchived:
            invocation.namedArguments[#includeArchived] as bool? ?? false,
      ),
    ),
  );
}

/// Answers `watchPrimaryCurrency`/`watchExchangeRates` by re-running the
/// test's `getPrimaryCurrency`/`getExchangeRates` stubs.
void stubCurrencyWatches(
  CurrencyRepository repository,
  FakeTableChanges changes,
) {
  when(
    repository.watchPrimaryCurrency,
  ).thenAnswer((_) => changes.signal().reRead(repository.getPrimaryCurrency));
  when(
    repository.watchExchangeRates,
  ).thenAnswer((_) => changes.signal().reRead(repository.getExchangeRates));
}
