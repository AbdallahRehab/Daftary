import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/failure.dart';
import '../../domain/ports/currency_usage_checker.dart';

/// [CurrencyUsageChecker] over the app's amount-bearing tables, as
/// read-only `SELECT EXISTS` queries that ignore soft-deleted rows:
///  - `money_transactions` (001 People & Money Relationships)
///  - `finance_entries` (007 Income & Expense)
///  - `budgets` (010 Household Budgets)
///  - `savings_goals` and `savings_contributions.entered_currency_code`
///    (011 Savings Goals, FR-028)
///
/// Occasions (008) carry no amount of their own. A feature that adds an
/// amount-bearing table adds one `EXISTS` clause here — the port and
/// `SetPrimaryCurrency` need no change.
@LazySingleton(as: CurrencyUsageChecker)
class DriftCurrencyUsageChecker implements CurrencyUsageChecker {
  DriftCurrencyUsageChecker(this._db);

  final db.AppDatabase _db;

  @override
  Future<Either<Failure, bool>> isCurrencyInUse(String currencyCode) async {
    try {
      final row = await _db
          .customSelect(
            'SELECT '
            'EXISTS (SELECT 1 FROM money_transactions '
            'WHERE currency_code = ?1 AND deleted_at IS NULL) '
            'OR EXISTS (SELECT 1 FROM finance_entries '
            'WHERE currency_code = ?1 AND deleted_at IS NULL) '
            // 010: an active budget is planned in its currency.
            'OR EXISTS (SELECT 1 FROM budgets '
            'WHERE currency_code = ?1 AND deleted_at IS NULL) '
            // 011: a live goal is saved in its currency, and a live entry
            // keeps the currency the user typed it in (FR-028).
            'OR EXISTS (SELECT 1 FROM savings_goals '
            'WHERE currency_code = ?1 AND deleted_at IS NULL) '
            'OR EXISTS (SELECT 1 FROM savings_contributions '
            'WHERE entered_currency_code = ?1 AND deleted_at IS NULL) '
            'AS in_use',
            variables: [Variable.withString(currencyCode)],
            readsFrom: {
              _db.moneyTransactions,
              _db.financeEntries,
              _db.budgets,
              _db.savingsGoals,
              _db.savingsContributions,
            },
          )
          .getSingle();
      return Right(row.read<int>('in_use') != 0);
    } catch (e) {
      return Left(CacheFailure('Failed to check currency usage: $e'));
    }
  }
}
