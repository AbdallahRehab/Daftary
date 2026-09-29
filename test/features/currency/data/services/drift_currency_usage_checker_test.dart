import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/currency/data/services/drift_currency_usage_checker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The FR-012 "is this currency in use" check: read-only EXISTS queries over
/// live (non-deleted) money_transactions, finance_entries, budgets,
/// savings_goals and savings_contributions rows.
void main() {
  late db.AppDatabase database;
  late DriftCurrencyUsageChecker checker;
  var seq = 0;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    checker = DriftCurrencyUsageChecker(database);
    await database
        .into(database.people)
        .insert(
          db.PeopleCompanion.insert(
            id: 'p1',
            name: 'Ali',
            normalizedName: 'ali',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
    await database
        .into(database.financeCategories)
        .insert(
          db.FinanceCategoriesCompanion.insert(
            id: 'c1',
            name: 'Food',
            normalizedName: 'food',
            type: 'expense',
            icon: 'food',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
  });

  Future<void> addTransaction(String code, {int? deletedAt}) async {
    seq++;
    await database
        .into(database.moneyTransactions)
        .insert(
          db.MoneyTransactionsCompanion.insert(
            id: 't$seq',
            idempotencyKey: 'k$seq',
            personId: 'p1',
            amountMinorUnits: 1000,
            currencyCode: Value(code),
            direction: 'lent',
            kind: 'loan',
            date: 0,
            createdAt: 0,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<void> addEntry(String code, {int? deletedAt}) async {
    seq++;
    await database
        .into(database.financeEntries)
        .insert(
          db.FinanceEntriesCompanion.insert(
            id: 'e$seq',
            idempotencyKey: 'fk$seq',
            categoryId: 'c1',
            type: 'expense',
            amountMinorUnits: 500,
            currencyCode: Value(code),
            date: 0,
            createdAt: 0,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<void> addGoal(String id, String code, {int? deletedAt}) => database
      .into(database.savingsGoals)
      .insert(
        db.SavingsGoalsCompanion.insert(
          id: id,
          idempotencyKey: 'gk-$id',
          name: 'Goal $id',
          currencyCode: Value(code),
          targetAmountMinorUnits: 100000,
          createdAt: 0,
          updatedAt: 0,
          deletedAt: Value(deletedAt),
        ),
      );

  /// A contribution to goal [goalId] typed in [enteredCode].
  Future<void> addContribution(
    String goalId,
    String enteredCode, {
    int? deletedAt,
  }) async {
    seq++;
    await database
        .into(database.savingsContributions)
        .insert(
          db.SavingsContributionsCompanion.insert(
            id: 'sc$seq',
            idempotencyKey: 'sck$seq',
            goalId: goalId,
            type: 'contribution',
            amountMinorUnits: 4850,
            enteredAmountMinorUnits: 100,
            enteredCurrencyCode: enteredCode,
            date: 0,
            createdAt: 0,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<bool> inUse(String code) async => (await checker.isCurrencyInUse(
    code,
  )).getOrElse((Failure f) => fail('unexpected $f'));

  test('an empty database uses no currency', () async {
    expect(await inUse('EGP'), isFalse);
  });

  test('a live money transaction marks its currency as used', () async {
    await addTransaction('USD');
    expect(await inUse('USD'), isTrue);
    expect(await inUse('EGP'), isFalse);
  });

  test('a live finance entry marks its currency as used', () async {
    await addEntry('SAR');
    expect(await inUse('SAR'), isTrue);
    expect(await inUse('USD'), isFalse);
  });

  test('soft-deleted rows are ignored', () async {
    await addTransaction('EUR', deletedAt: 1);
    await addEntry('EUR', deletedAt: 1);
    expect(await inUse('EUR'), isFalse);
  });

  test('a live savings goal marks its currency as used (011)', () async {
    await addGoal('g1', 'AED');
    expect(await inUse('AED'), isTrue);
    expect(await inUse('GBP'), isFalse);
  });

  test('a live savings entry marks the currency it was typed in as used '
      '(011 FR-028)', () async {
    await addGoal('g1', 'EGP');
    await addContribution('g1', 'USD');
    expect(await inUse('USD'), isTrue);
  });

  test('soft-deleted savings goals and entries are ignored', () async {
    await addGoal('g1', 'GBP', deletedAt: 1);
    await addGoal('g2', 'EGP');
    await addContribution('g2', 'SAR', deletedAt: 1);
    expect(await inUse('GBP'), isFalse);
    expect(await inUse('SAR'), isFalse);
  });

  test('a closed database surfaces as CacheFailure', () async {
    await database.close();
    final result = await checker.isCurrencyInUse('EGP');
    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}
