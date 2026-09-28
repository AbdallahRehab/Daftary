import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/data_privacy/domain/services/export_directory_provider.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_daos.dart';

class _FixedDirectory implements ExportDirectoryProvider {
  _FixedDirectory(this.directory);

  final Directory directory;

  @override
  Future<Directory> resolve() async => directory;
}

/// T048 — `ExportUserData` is read-only: every table's rows are identical
/// before and after an export, proven against real repositories over one
/// in-memory SQLite database rather than mocks.
void main() {
  late AppDatabase db;
  late Directory dir;
  late ExportUserData exportUserData;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dir = Directory.systemTemp.createTempSync('export_read_only_test');

    final people = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
    );
    final financeDao = testFinanceDao(db);
    final finance = FinanceRepositoryImpl(financeDao);
    final categories = CategoryRepositoryImpl(financeDao);
    final settings = SettingsRepositoryImpl(SettingsDao(db));

    exportUserData = ExportUserData(
      people,
      transactions,
      finance,
      categories,
      settings,
      _FixedDirectory(dir),
    );

    final ahmed = (await people.createPerson(
      name: 'Ahmed',
    )).getOrElse((f) => throw StateError(f.message));
    final mona = (await people.createPerson(
      name: 'Mona',
    )).getOrElse((f) => throw StateError(f.message));
    await transactions.addTransaction(
      idempotencyKey: 'tx-1',
      personId: ahmed.id,
      amount: const Money.egp(50025),
      direction: TransactionDirection.given,
      date: DateTime(2026, 9, 1),
    );
    final edited = (await transactions.addTransaction(
      idempotencyKey: 'tx-2',
      personId: mona.id,
      amount: const Money.egp(1000),
      direction: TransactionDirection.received,
      date: DateTime(2026, 9, 2),
    )).getOrElse((f) => throw StateError(f.message));
    // Leaves an audit row behind, so that table is populated too.
    await transactions.editTransaction(
      transactionId: edited.id,
      amount: const Money.egp(1500),
      direction: TransactionDirection.received,
      date: DateTime(2026, 9, 2),
    );
    await people.archivePerson(mona.id);
    await finance.addEntry(
      idempotencyKey: 'fin-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amount: Money.egp(75033),
      date: DateTime(2026, 9, 3),
    );
    await settings.setLanguagePreference(AppLanguage.arabic);
    await settings.setThemeModePreference(AppThemeMode.dark);
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  /// Every row of every user table, keyed by table name — whatever tables
  /// exist, so a table added later is covered automatically.
  Future<Map<String, List<Map<String, Object?>>>> snapshot() async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();
    return {
      for (final table in tables)
        table.read<String>('name'):
            (await db
                    .customSelect(
                      'SELECT * FROM "${table.read<String>('name')}" '
                      'ORDER BY rowid',
                    )
                    .get())
                .map((row) => row.data)
                .toList(),
    };
  }

  test('an export leaves every table exactly as it was', () async {
    final before = await snapshot();
    expect(before['people'], hasLength(2));
    expect(before['money_transactions'], hasLength(2));
    expect(before['finance_entries'], hasLength(1));

    final result = await exportUserData();

    expect(result.isRight(), isTrue);
    expect(await snapshot(), before);
  });

  test('the export carries every record the repositories expose', () async {
    final result = (await exportUserData()).getOrElse(
      (f) => throw StateError(f.message),
    );
    final categoryCount =
        (await db
                .customSelect('SELECT COUNT(*) AS c FROM finance_categories')
                .getSingle())
            .read<int>('c');

    expect(result.sectionCounts, {
      'People': 2,
      'Transactions': 2,
      'FinanceEntries': 1,
      'Categories': categoryCount,
      'Settings': 2,
    });
  });
}
