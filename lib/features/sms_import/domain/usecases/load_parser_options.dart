import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/repositories/category_repository.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../people/domain/usecases/find_possible_duplicate_person.dart';
import '../repositories/sms_import_settings_repository.dart';
import '../services/sms_message_parser.dart';

/// Builds the [ParserOptions] one ingestion call parses with
/// (parser-contract §1, §8): the cash-withdrawal preference, the learned
/// merchant mappings, the ACTIVE categories (so an archived or deleted
/// mapping target or seed is never suggested, FR-055/FR-056) and the
/// existing people's names (exact-name suggestion only, FR-054).
///
/// Reads only. It never touches `TransactionsRepository` or
/// `FinanceRepository` (SC-002).
@injectable
class LoadParserOptions {
  LoadParserOptions(this._settings, this._categories, this._people);

  final SmsImportSettingsRepository _settings;
  final CategoryRepository _categories;
  final PeopleRepository _people;

  /// The id prefix the first-launch category seed gives each default
  /// category: `seed_<key>` (`core/database/finance_category_seed.dart`).
  /// A test pins the two together.
  static const String seedIdPrefix = 'seed_';

  Future<Either<Failure, ParserOptions>> call() async {
    final settings = await _settings.getSettings();
    final mappings = await _settings.getMappingMap();
    final expense = await _categories.getCategories(
      type: FinanceEntryType.expense,
    );
    final income = await _categories.getCategories(
      type: FinanceEntryType.income,
    );
    final people = await _people.searchActivePeople();

    for (final result in [settings, mappings, expense, income, people]) {
      if (result case Left(:final value)) return Left(value);
    }

    final active = [
      ...expense.getOrElse((_) => const []),
      ...income.getOrElse((_) => const []),
    ].where((category) => category.isActive);

    return Right(
      ParserOptions(
        countCashWithdrawals: settings
            .map((s) => s.countCashWithdrawals)
            .getOrElse((_) => false),
        learnedCategoryIds: mappings.getOrElse((_) => const {}),
        activeCategoryIdsBySeedKey: {
          for (final category in active)
            if (category.id.startsWith(seedIdPrefix))
              category.id.substring(seedIdPrefix.length): category.id,
        },
        activeCategoryIds: {for (final category in active) category.id},
        peopleNames: [
          for (final person in people.getOrElse((_) => const []))
            PersonNameRef(
              id: person.id,
              normalizedName: FindPossibleDuplicatePerson.normalize(
                person.name,
              ),
            ),
        ],
      ),
    );
  }
}
