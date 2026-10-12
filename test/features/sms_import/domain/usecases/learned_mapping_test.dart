import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/merchant_category_mapping.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/usecases/clear_learned_mappings.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/remove_learned_mapping.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_learned_mappings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/fakes.dart';

class _MockPeople extends Mock implements PeopleRepository {}

/// 023 T136/T137/T139 — learned categories and people suggestions through
/// the real parser, the real settings and category repositories on one
/// in-memory database, and the read-only people repository.
///
/// - A learned mapping wins over the merchant keyword rule (FR-055 (a)).
/// - A mapping whose category is archived or missing is skipped (the
///   keyword rule, then "other", applies) and is LEFT IN PLACE (FR-056).
/// - People are only read: a named transfer suggests an existing person
///   on an exact name match and never creates one (FR-054, T137).
void main() {
  late db.AppDatabase database;
  late SmsImportSettingsDao settingsDao;
  late SmsImportSettingsRepositoryImpl settings;
  late CategoryRepository categories;
  late _MockPeople people;
  late List<Person> activePeople;
  late ParseMessages parse;

  const cafe = 'Purchase of EGP 125.50 at Example Cafe on 04/03/2026';
  const cafeKey = 'example cafe';

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    // Runs beforeOpen: seeds the first-launch categories.
    await database.select(database.financeCategories).get();
    settingsDao = SmsImportSettingsDao(database);
    final clock = FixedClock(DateTime(2026, 3, 6, 12));
    settings = SmsImportSettingsRepositoryImpl(settingsDao, clock);
    categories = CategoryRepositoryImpl(testFinanceDao(database));
    people = _MockPeople();
    activePeople = const [];
    when(
      () => people.searchActivePeople(
        nameQuery: any(named: 'nameQuery'),
        statusFilter: any(named: 'statusFilter'),
      ),
    ).thenAnswer((_) async => Right(activePeople));
    parse = ParseMessages(RuleBasedSmsParser(clock: clock));
  });

  tearDown(() => database.close());

  Future<void> learn(String merchantKey, String categoryId) =>
      settingsDao.upsertMapping(
        db.SmsMerchantCategoryMappingsCompanion.insert(
          merchantKey: merchantKey,
          entryType: FinanceEntryType.expense.dbValue,
          categoryId: categoryId,
          updatedAt: DateTime(2026, 3, 1).millisecondsSinceEpoch,
        ),
      );

  Future<ParserOptions> options() async => (await LoadParserOptions(
    settings,
    categories,
    people,
  )()).getOrElse((f) => fail('$f'));

  Future<ParsedTransaction> parsePaste(String text) async {
    final result = parse.parseOne(
      RawIncoming(text: text),
      source: SmsSource.paste,
      options: await options(),
    );
    expect(result, isA<ParsedTransaction>(), reason: '$result');
    return result as ParsedTransaction;
  }

  Future<void> archive(String categoryId) async {
    // The state removeCategory leaves for a category that has entries.
    await (database.update(database.financeCategories)
          ..where((c) => c.id.equals(categoryId)))
        .write(const db.FinanceCategoriesCompanion(isArchived: Value(true)));
  }

  group('learned mapping (FR-055, FR-056)', () {
    test('with no mapping the merchant keyword rule applies', () async {
      final p = await parsePaste(cafe);
      expect(p.merchantKey, cafeKey);
      expect(p.suggestedType, SuggestedRecordType.expense);
      expect(p.suggestedCategoryKeyOrId, 'seed_restaurants');
    });

    test('the learned mapping wins over the keyword rule', () async {
      await learn(cafeKey, 'seed_groceries');
      final p = await parsePaste(cafe);
      expect(p.suggestedCategoryKeyOrId, 'seed_groceries');
    });

    test('a mapping to an archived category is skipped and left in '
        'place', () async {
      await learn(cafeKey, 'seed_groceries');
      await archive('seed_groceries');

      final p = await parsePaste(cafe);
      expect(p.suggestedCategoryKeyOrId, 'seed_restaurants');

      final map = (await settings.getMappingMap()).getOrElse((f) => fail('$f'));
      expect(map[(cafeKey, 'expense')], 'seed_groceries');
    });

    test('a mapping to a deleted category is skipped and left in place, '
        'falling to "other" when no keyword matches', () async {
      await learn('example shop', 'deleted-category');
      final p = await parsePaste(
        'Purchase of EGP 80.00 at Example Shop on 04/03/2026',
      );
      expect(p.merchantKey, 'example shop');
      expect(p.suggestedCategoryKeyOrId, 'seed_other');
      final map = (await settings.getMappingMap()).getOrElse((f) => fail('$f'));
      expect(map[('example shop', 'expense')], 'deleted-category');
    });
  });

  group('people are read, never created (FR-054, T137)', () {
    Person person(String id, String name) => Person(
      id: id,
      name: name,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    const incoming =
        'You received a transfer of EGP 500.00 from Example Person on '
        '04/03/2026';

    test('an incoming transfer naming an existing person: Income default '
        'with that person pre-selected for the one-tap Received', () async {
      activePeople = [person('p1', 'Example  Person')];
      final p = await parsePaste(incoming);
      expect(p.kind, SmsKind.transferIn);
      expect(p.suggestedType, SuggestedRecordType.income);
      expect(p.suggestedCategoryKeyOrId, 'seed_other_income');
      expect(p.suggestedPersonId, 'p1');
    });

    test('no match: Income, no person', () async {
      activePeople = [person('p1', 'Someone Else')];
      final p = await parsePaste(incoming);
      expect(p.suggestedType, SuggestedRecordType.income);
      expect(p.suggestedPersonId, isNull);
    });

    test('two people with that name: no person (the review offers the '
        'similar-name choice)', () async {
      activePeople = [
        person('p1', 'Example Person'),
        person('p2', 'example person'),
      ];
      final p = await parsePaste(incoming);
      expect(p.suggestedPersonId, isNull);
    });

    test('the people repository is only searched, never written', () async {
      activePeople = [person('p1', 'Example Person')];
      await parsePaste(incoming);
      verify(() => people.searchActivePeople()).called(1);
      verifyNoMoreInteractions(people);
    });

    test('a failing people read fails the options, content-free', () async {
      when(
        () => people.searchActivePeople(),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
      final result = await LoadParserOptions(settings, categories, people)();
      expect(result.isLeft(), isTrue);
      verifyNever(() => people.createPerson(name: any(named: 'name')));
    });
  });

  group('learned-mapping use cases (T139)', () {
    test('watch lists every mapping, also one whose category is '
        'gone', () async {
      await learn(cafeKey, 'seed_groceries');
      await learn('example shop', 'deleted-category');
      final list = (await WatchLearnedMappings(
        settings,
      )().first).getOrElse((f) => fail('$f'));
      expect(
        {for (final m in list) m.merchantKey: m.categoryId},
        {cafeKey: 'seed_groceries', 'example shop': 'deleted-category'},
      );
      expect(list.every((m) => m.entryType == FinanceEntryType.expense), true);
    });

    test(
      'remove forgets one mapping; the keyword rule applies again',
      () async {
        await learn(cafeKey, 'seed_groceries');
        await learn('example shop', 'seed_other');
        final mapping = MerchantCategoryMapping(
          merchantKey: cafeKey,
          entryType: FinanceEntryType.expense,
          categoryId: 'seed_groceries',
          updatedAt: DateTime(2026, 3, 1),
        );
        expect((await RemoveLearnedMapping(settings)(mapping)).isRight(), true);

        final map = (await settings.getMappingMap()).getOrElse(
          (f) => fail('$f'),
        );
        expect(map.keys, [('example shop', 'expense')]);
        expect(
          (await parsePaste(cafe)).suggestedCategoryKeyOrId,
          'seed_restaurants',
        );
      },
    );

    test('clear forgets every mapping and touches no category', () async {
      final before = await database.select(database.financeCategories).get();
      await learn(cafeKey, 'seed_groceries');
      await learn('example shop', 'seed_other');
      expect((await ClearLearnedMappings(settings)()).isRight(), true);
      expect(
        (await settings.getMappingMap()).getOrElse((f) => fail('$f')),
        isEmpty,
      );
      final after = await database.select(database.financeCategories).get();
      expect(after, before);
    });
  });
}
