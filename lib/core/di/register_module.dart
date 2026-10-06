import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart';
import '../../features/currency/data/sync/exchange_rate_sync_mapper.dart';
import '../../features/currency/data/sync/primary_currency_sync_mapper.dart';
import '../../features/finance/data/sync/finance_category_sync_mapper.dart'
    show FinanceCategorySyncMapper, isPristineSeed;
import '../../features/finance/data/sync/finance_entry_audit_sync_mapper.dart';
import '../../features/finance/data/sync/finance_entry_sync_mapper.dart';
import '../../features/people/data/sync/person_sync_mapper.dart';
import '../../features/transactions/data/sync/money_transaction_sync_mapper.dart';
import '../../features/transactions/data/sync/transaction_audit_sync_mapper.dart';
import '../database/app_database.dart';
import '../date/app_clock.dart';
import '../money/egp_formatter.dart';
import '../sync/local/sync_applier.dart';
import '../sync/remote/supabase_initializer.dart';
import '../sync/sync_bootstrap.dart';
import '../sync/sync_logger.dart';
import '../sync/sync_mapper_registry.dart';
import '../../features/budgets/data/sync/budget_sync_mapper.dart';
import '../../features/occasions/data/sync/occasion_sync_mapper.dart';
import '../../features/savings/data/sync/savings_contribution_audit_sync_mapper.dart';
import '../../features/savings/data/sync/savings_contribution_sync_mapper.dart';
import '../../features/savings/data/sync/savings_goal_sync_mapper.dart';

/// Registers third-party/leaf dependencies that aren't themselves annotated
/// with `@injectable` (research.md Decision 11: the DB file lives in the
/// app's sandboxed documents directory, opened lazily by [AppDatabase]'s
/// own default constructor).
@module
abstract class RegisterModule {
  /// 021: opened with the sync bootstrap, which queues the pre-existing
  /// data for upload once, in `beforeOpen` (T063).
  @lazySingleton
  AppDatabase appDatabase(SyncBootstrap bootstrap) =>
      AppDatabase(syncBootstrap: bootstrap);

  /// 021: queues the pre-existing data once (T063), and re-queues it all
  /// when the account changes (T069). The pristine-seed rule lives in the
  /// finance feature, so it is supplied here.
  @lazySingleton
  SyncBootstrap syncBootstrap(
    SyncMapperRegistry mappers,
    SyncLogger logger,
    AppClock clock,
  ) => SyncBootstrap(mappers, logger, clock, isPristineSeed: isPristineSeed);

  /// 021: writes downloaded rows without recording outbox entries (T068).
  @lazySingleton
  SyncApplier syncApplier(
    AppDatabase db,
    SyncMapperRegistry mappers,
    AppClock clock,
  ) => DriftSyncApplier(db, mappers, clock, isPristineSeed: isPristineSeed);

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
  /// (constitution XII), shared with 014's API key and 015's PIN hash —
  /// each feature namespaces its own keys and reaches storage only through
  /// its own data source. `SupabaseClient` itself is registered later, and
  /// only once Supabase is initialized (T061).
  ///
  /// iOS: `first_unlock_this_device` keeps the session out of iCloud/iTunes
  /// backups and device-to-device transfers, while still readable by
  /// background work after the first unlock. The plugin finds items written
  /// under the previous (default) accessibility and rewrites them with this
  /// one on the next write, so existing sessions carry over.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 021: the cloud client (T061). Resolve it only after
  /// `SupabaseInitializer.ensureInitialized()` has returned true — before
  /// that (and always when `CloudConfig.isConfigured` is false) resolving it
  /// throws. The sync data sources reach it through the initializer.
  @lazySingleton
  SupabaseClient supabaseClient(SupabaseInitializer supabase) =>
      supabase.client;

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
    OccasionSyncMapper occasion,
    BudgetSyncMapper budget,
    BudgetAllocationSyncMapper budgetAllocation,
    SavingsGoalSyncMapper savingsGoal,
    SavingsContributionSyncMapper savingsContribution,
    SavingsContributionAuditSyncMapper savingsContributionAudit,
    FinanceEntryAuditSyncMapper financeEntryAudit,
  ) => SyncMapperRegistry([
    person,
    moneyTransaction,
    transactionAudit,
    financeCategory,
    financeEntry,
    exchangeRate,
    primaryCurrency,
    conflictResolution,
    occasion,
    budget,
    budgetAllocation,
    savingsGoal,
    savingsContribution,
    savingsContributionAudit,
    financeEntryAudit,
  ]);

  @lazySingleton
  ImagePicker get imagePicker => ImagePicker();
}
