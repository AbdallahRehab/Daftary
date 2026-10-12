import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/sms_import/domain/entities/merchant_category_mapping.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockCategories extends Mock implements CategoryRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

/// T062 support — the options one ingestion call parses with.
void main() {
  late _MockCategories categories;
  late _MockPeople people;
  late FakeSmsImportSettingsRepository settings;

  setUpAll(() => registerFallbackValue(FinanceEntryType.expense));

  Category category(
    String id,
    FinanceEntryType type, {
    bool archived = false,
  }) => Category(
    id: id,
    name: id,
    type: type,
    icon: 'other',
    isArchived: archived,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    categories = _MockCategories();
    people = _MockPeople();
    settings = FakeSmsImportSettingsRepository(
      settings: const SmsImportSettings(countCashWithdrawals: true),
    );
    settings.mappings[('example cafe', 'expense')] = MerchantCategoryMapping(
      merchantKey: 'example cafe',
      entryType: FinanceEntryType.expense,
      categoryId: 'custom-1',
      updatedAt: DateTime(2026),
    );
    when(
      () => categories.getCategories(type: FinanceEntryType.expense),
    ).thenAnswer(
      (_) async => Right([
        category('seed_other', FinanceEntryType.expense),
        category('seed_groceries', FinanceEntryType.expense, archived: true),
        category('custom-1', FinanceEntryType.expense),
      ]),
    );
    when(
      () => categories.getCategories(type: FinanceEntryType.income),
    ).thenAnswer(
      (_) async => Right([category('seed_salary', FinanceEntryType.income)]),
    );
    when(() => people.searchActivePeople()).thenAnswer(
      (_) async => Right([
        Person(
          id: 'person-1',
          name: '  Example   Person ',
          isArchived: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
    );
  });

  test(
    'builds the options from settings, active categories and people',
    () async {
      final options = (await LoadParserOptions(
        settings,
        categories,
        people,
      )()).getOrElse((f) => fail('$f'));
      expect(options.countCashWithdrawals, isTrue);
      expect(options.learnedCategoryIds, {
        ('example cafe', 'expense'): 'custom-1',
      });
      expect(options.activeCategoryIdsBySeedKey, {
        'other': 'seed_other',
        'salary': 'seed_salary',
      });
      expect(options.activeCategoryIds, {
        'seed_other',
        'custom-1',
        'seed_salary',
      });
      expect(options.peopleNames.single.normalizedName, 'example person');
    },
  );

  test('a failing read is returned', () async {
    when(
      () => people.searchActivePeople(),
    ).thenAnswer((_) async => const Left(CacheFailure('x')));
    final result = await LoadParserOptions(settings, categories, people)();
    expect(result.isLeft(), isTrue);
  });

  test('the seed id prefix matches the first-launch seed', () async {
    final database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final ids = (await database.select(database.financeCategories).get()).map(
      (c) => c.id,
    );
    expect(ids, isNotEmpty);
    expect(
      ids.every((id) => id.startsWith(LoadParserOptions.seedIdPrefix)),
      isTrue,
    );
    expect(
      ids,
      containsAll(['seed_other', 'seed_other_income', 'seed_salary']),
    );
  });
}
