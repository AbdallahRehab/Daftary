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
///
/// Occasions (008), Budgets (010) and Savings Goals (011) have no tables in
/// this codebase yet; when they land, add one `EXISTS` clause per table
/// here — the port and `SetPrimaryCurrency` need no change.
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
            'AS in_use',
            variables: [Variable.withString(currencyCode)],
            readsFrom: {_db.moneyTransactions, _db.financeEntries, _db.budgets},
          )
          .getSingle();
      return Right(row.read<int>('in_use') != 0);
    } catch (e) {
      return Left(CacheFailure('Failed to check currency usage: $e'));
    }
  }
}
