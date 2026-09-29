import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/features/budgets/data/datasources/budgets_dao.dart';
import 'package:daftary/features/budgets/data/sync/budget_sync_mapper.dart';
import 'package:daftary/features/currency/data/datasources/currency_dao.dart';
import 'package:daftary/features/currency/data/sync/exchange_rate_sync_mapper.dart';
import 'package:daftary/features/currency/data/sync/primary_currency_sync_mapper.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_sync_mapper.dart';
import 'package:daftary/features/occasions/data/datasources/occasions_dao.dart';
import 'package:daftary/features/occasions/data/sync/occasion_sync_mapper.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/people/data/sync/person_sync_mapper.dart';
import 'package:daftary/features/savings/data/datasources/savings_dao.dart';
import 'package:daftary/features/savings/data/sync/savings_contribution_audit_sync_mapper.dart';
import 'package:daftary/features/savings/data/sync/savings_contribution_sync_mapper.dart';
import 'package:daftary/features/savings/data/sync/savings_goal_sync_mapper.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:daftary/features/transactions/data/sync/transaction_audit_sync_mapper.dart';

/// 021: the feature DAOs wired to a real [DriftSyncOutbox] on [db], exactly
/// as DI builds them, for tests that drive an in-memory database.
SyncOutbox testOutbox(
  AppDatabase db, [
  AppClock clock = const SystemAppClock(),
]) => DriftSyncOutbox(db, clock);

PeopleDao testPeopleDao(AppDatabase db) =>
    PeopleDao(db, testOutbox(db), const PersonSyncMapper());

TransactionsDao testTransactionsDao(AppDatabase db) => TransactionsDao(
  db,
  testOutbox(db),
  const MoneyTransactionSyncMapper(),
  const TransactionAuditSyncMapper(),
);

FinanceDao testFinanceDao(AppDatabase db) => FinanceDao(
  db,
  testOutbox(db),
  const FinanceCategorySyncMapper(),
  const FinanceEntrySyncMapper(),
);

CurrencyDao testCurrencyDao(AppDatabase db) => CurrencyDao(
  db,
  testOutbox(db),
  const ExchangeRateSyncMapper(),
  const PrimaryCurrencySyncMapper(),
);

OccasionsDao testOccasionsDao(AppDatabase db) =>
    OccasionsDao(db, testOutbox(db), const OccasionSyncMapper());

BudgetsDao testBudgetsDao(AppDatabase db) => BudgetsDao(
  db,
  testOutbox(db),
  const BudgetSyncMapper(),
  const BudgetAllocationSyncMapper(),
);

SavingsDao testSavingsDao(AppDatabase db) => SavingsDao(
  db,
  testOutbox(db),
  const SavingsGoalSyncMapper(),
  const SavingsContributionSyncMapper(),
  const SavingsContributionAuditSyncMapper(),
);
