import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/acknowledge_expired_notice.dart';
import 'package:daftary/features/sms_import/domain/usecases/disable_sms_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/enable_sms_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_expired_notice.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_scan_counts.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/open_sms_app_info.dart';
import 'package:daftary/features/sms_import/domain/usecases/request_sms_permission.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:daftary/features/sms_import/domain/usecases/update_sms_import_preferences.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_pending_import_count.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_sms_import_settings.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_home_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_settings_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/enable_flow_cubit.dart';
import 'package:fpdart/fpdart.dart';

import 'fakes.dart';

/// A `RunInboxScan` with a scripted outcome, for presentation tests: it
/// reports [progress] steps, then waits on [gate] (when set) and returns
/// [result]. A cancelled token yields a cancelled summary.
class ScriptedRunInboxScan implements RunInboxScan {
  ScriptedRunInboxScan({Either<Failure, ScanSummary>? result})
    : result = result ?? Right(ScanSummary());

  Either<Failure, ScanSummary> result;
  List<int> progress = const [];
  Completer<void>? gate;
  final List<ScanWindow> windows = [];
  ScanCancellationToken? lastToken;

  int get calls => windows.length;

  @override
  Future<Either<Failure, ScanSummary>> call({
    required ScanWindow window,
    required ScanCancellationToken token,
    void Function(ScanProgress)? onProgress,
  }) async {
    windows.add(window);
    lastToken = token;
    for (final processed in progress) {
      onProgress?.call(ScanProgress(processed: processed));
    }
    final wait = gate;
    if (wait != null) await wait.future;
    if (token.isCancelled) {
      return Right(ScanSummary(cancelled: true));
    }
    return result;
  }
}

/// The ports behind the hub's scan state, all fakes. Capability off by
/// default, so the hub is the paste-only list.
class HubScanDeps {
  HubScanDeps({
    bool capability = false,
    FakeSmsPermissionService? permissions,
    FakeSmsImportSettingsRepository? settings,
    ScriptedRunInboxScan? scan,
    FakeSmsImportRepository? pending,
  }) : pending = pending ?? FakeSmsImportRepository(),
       gateway = FakeSmsInboxGateway(
         capability: SmsCapability(
           readSmsDeclared: capability,
           isAndroid: capability,
         ),
       ),
       permissions = permissions ?? FakeSmsPermissionService(),
       settings = settings ?? FakeSmsImportSettingsRepository(),
       scan = scan ?? ScriptedRunInboxScan();

  final FakeSmsInboxGateway gateway;
  final FakeSmsPermissionService permissions;
  final FakeSmsImportSettingsRepository settings;
  final ScriptedRunInboxScan scan;

  /// The pending items Turn off may delete (Settings, T142).
  final FakeSmsImportRepository pending;

  GetSmsCapability get capability => GetSmsCapability(gateway);

  GetSmsPermissionStatus get permissionStatus =>
      GetSmsPermissionStatus(capability, permissions);

  OpenSmsAppInfo get openAppInfo => OpenSmsAppInfo(permissions);

  WatchSmsImportSettings get watchSettings => WatchSmsImportSettings(settings);
}

/// A `BankMessagesCubit` over [repository] and [deps].
BankMessagesCubit buildBankMessagesCubit(
  FakeSmsImportRepository repository,
  FixedClock clock, {
  HubScanDeps? deps,
}) {
  final d = deps ?? HubScanDeps();
  return BankMessagesCubit(
    WatchPendingImports(repository),
    ExpirePendingImports(repository, clock),
    GetExpiredNotice(repository),
    AcknowledgeExpiredNotice(repository),
    d.capability,
    d.permissionStatus,
    d.watchSettings,
    d.scan,
    d.openAppInfo,
    IgnoreImport(repository),
  );
}

/// An `EnableFlowCubit` over [deps] (real use cases, fake ports).
EnableFlowCubit buildEnableFlowCubit(
  HubScanDeps deps, {
  FakeSmsImportRepository? repository,
  FakeExternalActivityRunner? runner,
}) {
  final requestPermission = RequestSmsPermission(
    deps.capability,
    deps.permissions,
    deps.settings,
    runner ?? FakeExternalActivityRunner(),
  );
  return EnableFlowCubit(
    deps.capability,
    deps.permissionStatus,
    EnableSmsImport(deps.permissionStatus, requestPermission, deps.settings),
    deps.openAppInfo,
    UpdateSmsImportPreferences(deps.settings),
    deps.scan,
    GetPendingImports(repository ?? FakeSmsImportRepository()),
  );
}

/// A `BankMessagesSettingsCubit` over [deps].
BankMessagesSettingsCubit buildSettingsCubit(HubScanDeps deps) =>
    BankMessagesSettingsCubit(
      deps.capability,
      deps.permissionStatus,
      deps.watchSettings,
      GetScanCounts(deps.settings),
      UpdateSmsImportPreferences(deps.settings),
      deps.openAppInfo,
      DisableSmsImport(deps.settings, deps.pending),
    );

/// A `BankMessagesHomeCubit` over [deps]; the pending count comes from
/// [repository] (an empty one by default).
BankMessagesHomeCubit buildHomeCubit(
  HubScanDeps deps, {
  FakeSmsImportRepository? repository,
}) => BankMessagesHomeCubit(
  deps.watchSettings,
  UpdateSmsImportPreferences(deps.settings),
  WatchPendingImportCount(repository ?? FakeSmsImportRepository()),
);
