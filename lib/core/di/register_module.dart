import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart';
import '../../features/currency/data/sync/exchange_rate_sync_mapper.dart';
import '../../features/currency/data/sync/primary_currency_sync_mapper.dart';
import '../../features/finance/data/sync/finance_category_sync_mapper.dart';
import '../../features/finance/data/sync/finance_entry_sync_mapper.dart';
import '../../features/people/data/sync/person_sync_mapper.dart';
import '../../features/transactions/data/sync/money_transaction_sync_mapper.dart';
import '../../features/transactions/data/sync/transaction_audit_sync_mapper.dart';
import '../database/app_database.dart';
import '../money/egp_formatter.dart';
import '../sync/sync_mapper_registry.dart';

/// Registers third-party/leaf dependencies that aren't themselves annotated
/// with `@injectable` (research.md Decision 11: the DB file lives in the
/// app's sandboxed documents directory, opened lazily by [AppDatabase]'s
/// own default constructor).
@module
abstract class RegisterModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  EgpFormatter get egpFormatter => EgpFormatter();

  /// The app's bundled assets — injected rather than read via `rootBundle`
  /// directly so content-loading data sources can be tested against a
  /// fixture bundle (016 `BundledEducationContentDataSource`).
  @lazySingleton
  AssetBundle get assetBundle => rootBundle;

  /// The OS notification plugin (017) — injected into
  /// `FlutterLocalNotificationsScheduler` rather than constructed there so
  /// tests can substitute a mock and never post a real notification.
  @lazySingleton
  FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      FlutterLocalNotificationsPlugin();

  /// 021: the OS network-change source behind `ConnectivityMonitor` — a
  /// hint only, never a gate (research.md Decision 13).
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// 021: Keychain/Keystore-backed storage for the cloud session
  /// (constitution XII). `SupabaseClient` itself is registered later, and
  /// only once Supabase is initialized (T061).
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// 021: every feature's sync mapper, indexed by entity type. Assembled
  /// here, at the composition root, so `lib/core/sync` never imports a
  /// feature.
  @lazySingleton
  SyncMapperRegistry syncMapperRegistry(
    PersonSyncMapper person,
    MoneyTransactionSyncMapper moneyTransaction,
    TransactionAuditSyncMapper transactionAudit,
    FinanceCategorySyncMapper financeCategory,
    FinanceEntrySyncMapper financeEntry,
    ExchangeRateSyncMapper exchangeRate,
    PrimaryCurrencySyncMapper primaryCurrency,
    ConflictResolutionSyncMapper conflictResolution,
  ) => SyncMapperRegistry([
    person,
    moneyTransaction,
    transactionAudit,
    financeCategory,
    financeEntry,
    exchangeRate,
    primaryCurrency,
    conflictResolution,
  ]);
}
