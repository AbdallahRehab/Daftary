import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/data_privacy/domain/entities/export_result.dart';
import 'package:daftary/features/data_privacy/domain/services/export_directory_provider.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/domain/repositories/settings_repository.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockFinanceRepository extends Mock implements FinanceRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class _FixedDirectory implements ExportDirectoryProvider {
  _FixedDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

/// T018 / T049 — `ExportUserData` composes only the existing repository
/// reads named in research.md Decision 2 into one section-delimited CSV
/// (Decision 4), and never leaves a file that looks complete on failure
/// (FR-011).
void main() {
  late MockPeopleRepository people;
  late MockTransactionsRepository transactions;
  late MockFinanceRepository finance;
  late MockCategoryRepository categories;
  late MockSettingsRepository settings;
  late Directory dir;
  late ExportUserData exportUserData;

  final created = DateTime.utc(2026, 1, 2, 3, 4, 5);

  final ahmed = Person(
    id: 'p1',
    name: 'Ahmed, "the elder"',
    isArchived: false,
    createdAt: created,
    updatedAt: created,
    phoneNumber: '0100',
  );
  final mona = Person(
    id: 'p2',
    name: 'منى',
    isArchived: true,
    createdAt: created,
    updatedAt: created,
    notes: 'line one\nline two',
  );

  MoneyTransaction tx(String id, String personId, int minor) =>
      MoneyTransaction(
        id: id,
        idempotencyKey: 'k-$id',
        personId: personId,
        amount: Money.egp(minor),
        direction: TransactionDirection.given,
        kind: TransactionKind.initialExchange,
        date: created,
        createdAt: created,
      );

  FinanceEntry entry(String id) => FinanceEntry(
    id: id,
    idempotencyKey: 'k-$id',
    categoryId: 'c-food',
    type: FinanceEntryType.expense,
    amount: const Money.egp(12345),
    date: created,
    createdAt: created,
  );

  final food = Category(
    id: 'c-food',
    name: 'Food',
    type: FinanceEntryType.expense,
    icon: 'restaurant',
    createdAt: created,
    updatedAt: created,
    isDefault: true,
  );
  final salary = Category(
    id: 'c-salary',
    name: 'Salary',
    type: FinanceEntryType.income,
    icon: 'work',
    createdAt: created,
    updatedAt: created,
    isArchived: true,
  );

  void stubEmpty() {
    when(
      () => people.searchActivePeople(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => people.searchArchivedPeople(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => finance.getHistory(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => categories.getCategories(
        type: any(named: 'type'),
        includeArchived: true,
      ),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => settings.getLanguagePreference(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => settings.getThemeModePreference(),
    ).thenAnswer((_) async => const Right(null));
  }

  void stubPopulated() {
    stubEmpty();
    when(
      () => people.searchActivePeople(),
    ).thenAnswer((_) async => Right([ahmed]));
    when(
      () => people.searchArchivedPeople(),
    ).thenAnswer((_) async => Right([mona]));
    when(() => transactions.getPersonHistory('p1')).thenAnswer(
      (_) async => Right([tx('t1', 'p1', 50025), tx('t2', 'p1', 7)]),
    );
    when(
      () => transactions.getPersonHistory('p2'),
    ).thenAnswer((_) async => Right([tx('t3', 'p2', -1)]));
    when(
      () => finance.getHistory(limit: any(named: 'limit'), offset: 0),
    ).thenAnswer((_) async => Right([entry('e1')]));
    when(
      () => categories.getCategories(
        type: FinanceEntryType.income,
        includeArchived: true,
      ),
    ).thenAnswer((_) async => Right([salary]));
    when(
      () => categories.getCategories(
        type: FinanceEntryType.expense,
        includeArchived: true,
      ),
    ).thenAnswer((_) async => Right([food]));
    when(
      () => settings.getLanguagePreference(),
    ).thenAnswer((_) async => const Right(AppLanguage.arabic));
    when(
      () => settings.getThemeModePreference(),
    ).thenAnswer((_) async => const Right(AppThemeMode.dark));
  }

  void verifyOnlyExistingReads() {
    verifyNoMoreInteractions(people);
    verifyNoMoreInteractions(transactions);
    verifyNoMoreInteractions(finance);
    verifyNoMoreInteractions(categories);
    verifyNoMoreInteractions(settings);
  }

  /// Everything in the export directory — used to prove nothing complete-
  /// looking (nor any temporary leftover) survives a failed export.
  List<String> filesIn(Directory d) =>
      d.listSync().map((e) => e.uri.pathSegments.last).toList();

  setUpAll(() => registerFallbackValue(FinanceEntryType.income));

  setUp(() {
    people = MockPeopleRepository();
    transactions = MockTransactionsRepository();
    finance = MockFinanceRepository();
    categories = MockCategoryRepository();
    settings = MockSettingsRepository();
    dir = Directory.systemTemp.createTempSync('export_user_data_test');
    exportUserData = ExportUserData(
      people,
      transactions,
      finance,
      categories,
      settings,
      _FixedDirectory(dir),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  ExportResult expectRight(Either<Failure, ExportResult> result) =>
      result.getOrElse((f) => throw StateError('expected Right, got $f'));

  group('composition (research.md Decision 2)', () {
    test('sources every section from the exact existing read methods, and '
        'nothing else', () async {
      stubPopulated();

      final result = expectRight(await exportUserData());

      verify(() => people.searchActivePeople()).called(1);
      verify(() => people.searchArchivedPeople()).called(1);
      verify(() => transactions.getPersonHistory('p1')).called(1);
      verify(() => transactions.getPersonHistory('p2')).called(1);
      verify(
        () => finance.getHistory(
          limit: ExportUserData.financePageSize,
          offset: 0,
        ),
      ).called(1);
      verify(
        () => categories.getCategories(
          type: FinanceEntryType.income,
          includeArchived: true,
        ),
      ).called(1);
      verify(
        () => categories.getCategories(
          type: FinanceEntryType.expense,
          includeArchived: true,
        ),
      ).called(1);
      verify(() => settings.getLanguagePreference()).called(1);
      verify(() => settings.getThemeModePreference()).called(1);
      verifyOnlyExistingReads();

      expect(result.sectionCounts, {
        'People': 2,
        'Transactions': 3,
        'FinanceEntries': 1,
        'Categories': 2,
        'Settings': 2,
      });
      expect(result.totalRecords, 10);
    });

    test('pages finance history to completion', () async {
      stubEmpty();
      const size = ExportUserData.financePageSize;
      final fullPage = List.generate(size, (i) => entry('a$i'));
      when(
        () => finance.getHistory(limit: size, offset: 0),
      ).thenAnswer((_) async => Right(fullPage));
      when(
        () => finance.getHistory(limit: size, offset: size),
      ).thenAnswer((_) async => Right([entry('b0'), entry('b1')]));

      final result = expectRight(await exportUserData());

      verify(() => finance.getHistory(limit: size, offset: 0)).called(1);
      verify(() => finance.getHistory(limit: size, offset: size)).called(1);
      verifyNoMoreInteractions(finance);
      expect(result.sectionCounts['FinanceEntries'], size + 2);
    });

    test(
      'an exact multiple of the page size stops on the first empty page',
      () async {
        stubEmpty();
        const size = ExportUserData.financePageSize;
        when(() => finance.getHistory(limit: size, offset: 0)).thenAnswer(
          (_) async => Right(List.generate(size, (i) => entry('a$i'))),
        );

        final result = expectRight(await exportUserData());

        verify(() => finance.getHistory(limit: size, offset: size)).called(1);
        expect(result.sectionCounts['FinanceEntries'], size);
      },
    );
  });

  group('file format (research.md Decision 4)', () {
    test('writes one CSV with a marker, header, and rows per section, in '
        'order, with values escaped', () async {
      stubPopulated();

      final result = expectRight(await exportUserData());
      final file = File(result.filePath);
      expect(file.existsSync(), isTrue);
      expect(result.filePath, endsWith('.csv'));
      final content = file.readAsStringSync();

      final markers = ExportSection.values
          .map((s) => content.indexOf('## ${s.marker}'))
          .toList();
      expect(markers, everyElement(greaterThanOrEqualTo(0)));
      expect(markers, orderedEquals([...markers]..sort()));

      // A comma and quotes force quoting, with inner quotes doubled.
      expect(content, contains('"Ahmed, ""the elder"""'));
      // Arabic survives as-is; embedded newlines are quoted.
      expect(content, contains('منى'));
      expect(content, contains('"line one\nline two"'));
      // Amounts: exact minor units, plus a two-decimal major-unit column.
      expect(content, contains('50025,500.25'));
      expect(content, contains('7,0.07'));
      expect(content, contains('-1,-0.01'));
      // Finance entries carry their category's name for readability.
      expect(content, contains('Food'));
      expect(content, contains('language,ar'));
      expect(content, contains('theme_mode,dark'));
    });
  });

  group('empty install (FR-008, T049)', () {
    test('produces a valid, header-only file — not an error', () async {
      stubEmpty();

      final result = expectRight(await exportUserData());

      expect(result.totalRecords, 0);
      expect(result.sectionCounts.keys, ExportSection.values.map((s) => s.key));
      final file = File(result.filePath);
      expect(file.lengthSync(), greaterThan(0));
      final lines = file
          .readAsStringSync()
          .split(RegExp(r'\r?\n'))
          .where((l) => l.isNotEmpty)
          .toList();
      // Exactly one marker line and one header line per section.
      expect(lines, hasLength(ExportSection.values.length * 2));
      for (final (i, section) in ExportSection.values.indexed) {
        expect(lines[i * 2], endsWith('## ${section.marker}'));
        expect(lines[i * 2 + 1], isNotEmpty);
      }
      verify(
        () => finance.getHistory(limit: any(named: 'limit'), offset: 0),
      ).called(1);
      verifyNever(() => transactions.getPersonHistory(any()));
    });
  });

  group('failure (FR-011)', () {
    test('any failing read surfaces as Left and writes nothing', () async {
      stubPopulated();
      when(
        () => finance.getHistory(limit: any(named: 'limit'), offset: 0),
      ).thenAnswer((_) async => const Left(CacheFailure('disk')));

      final result = await exportUserData();

      expect(result, const Left<Failure, ExportResult>(CacheFailure('disk')));
      expect(filesIn(dir), isEmpty);
    });

    for (final (label, arrange) in <(String, void Function())>[
      (
        'people',
        () => when(
          () => people.searchArchivedPeople(),
        ).thenAnswer((_) async => const Left(CacheFailure('x'))),
      ),
      (
        'transactions',
        () => when(
          () => transactions.getPersonHistory('p2'),
        ).thenAnswer((_) async => const Left(CacheFailure('x'))),
      ),
      (
        'categories',
        () => when(
          () => categories.getCategories(
            type: FinanceEntryType.expense,
            includeArchived: true,
          ),
        ).thenAnswer((_) async => const Left(CacheFailure('x'))),
      ),
      (
        'settings',
        () => when(
          () => settings.getThemeModePreference(),
        ).thenAnswer((_) async => const Left(CacheFailure('x'))),
      ),
    ]) {
      test('a $label failure is a Left with no file left behind', () async {
        stubPopulated();
        arrange();

        final result = await exportUserData();

        expect(result.isLeft(), isTrue);
        expect(filesIn(dir), isEmpty);
      });
    }

    test(
      'a write failure is a CacheFailure with no file left behind',
      () async {
        stubPopulated();
        // A directory that does not exist makes the write itself throw.
        final missing = Directory('${dir.path}/missing/deeper');
        exportUserData = ExportUserData(
          people,
          transactions,
          finance,
          categories,
          settings,
          _FixedDirectory(missing),
        );

        final result = await exportUserData();

        expect(result.getLeft().toNullable(), isA<CacheFailure>());
        expect(missing.existsSync(), isFalse);
        expect(filesIn(dir), isEmpty);
      },
    );
  });
}
