import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/usecases/acknowledge_expired_notice.dart';
import '../../domain/usecases/expire_pending_imports.dart';
import '../../domain/usecases/get_expired_notice.dart';
import '../../domain/usecases/get_sms_capability.dart';
import '../../domain/usecases/get_sms_permission_status.dart';
import '../../domain/usecases/ignore_import.dart';
import '../../domain/usecases/open_sms_app_info.dart';
import '../../domain/usecases/run_inbox_scan.dart';
import '../../domain/usecases/watch_pending_imports.dart';
import '../../domain/usecases/watch_sms_import_settings.dart';
import 'bank_messages_state.dart';

/// The Bank messages hub, list part (T079, ui-contract §3.3): on open it
/// runs `ExpirePendingImports` (idempotent), reads the expired notice, then
/// follows the pending list live. It only reads: nothing here can create
/// a record (FR-052).
///
/// US2 (T120): the scan state. It reads the capability, the prompt-free
/// permission status and the settings, runs `RunInboxScan` on an explicit
/// tap with progress and Cancel, and keeps the content-free summary in
/// memory (CHK003). It never prompts: every permission action navigates
/// to the enable flow (FR-002, FR-012).
///
/// US6 (T132): multi-select whose only action is Ignore. The page asks
/// `showAppConfirmDialog` first (FR-064); there is no "Add all" or batch
/// Add (FR-046).
@injectable
class BankMessagesCubit extends Cubit<BankMessagesState> {
  BankMessagesCubit(
    this._watchPending,
    this._expirePending,
    this._getExpiredNotice,
    this._acknowledgeExpiredNotice,
    this._capability,
    this._permissionStatus,
    this._settings,
    this._runInboxScan,
    this._openAppInfo,
    this._ignoreImport,
  ) : super(BankMessagesState());

  final WatchPendingImports _watchPending;
  final ExpirePendingImports _expirePending;
  final GetExpiredNotice _getExpiredNotice;
  final AcknowledgeExpiredNotice _acknowledgeExpiredNotice;
  final GetSmsCapability _capability;
  final GetSmsPermissionStatus _permissionStatus;
  final WatchSmsImportSettings _settings;
  final RunInboxScan _runInboxScan;
  final OpenSmsAppInfo _openAppInfo;
  final IgnoreImport _ignoreImport;

  StreamSubscription<void>? _subscription;
  Completer<void>? _firstResult;
  ScanCancellationToken? _scanToken;

  /// Opens the list. The returned future completes once the first list
  /// result has been emitted.
  Future<void> open() async {
    _cancelSubscription();
    emit(
      state.copyWith(status: BankMessagesStatus.loading, clearFailure: true),
    );

    // Expiry first, so expired items never flash in the list. A failure
    // here is not fatal: the list still opens and expiry runs next time.
    await _expirePending();
    if (isClosed) return;
    final notice = await _getExpiredNotice();
    if (isClosed) return;
    emit(state.copyWith(expiredNoticeCount: notice.getOrElse((_) => 0)));
    await refreshScanContext();
    if (isClosed) return;

    final firstResult = _firstResult = Completer<void>();
    _subscription = _watchPending().listen((result) {
      if (isClosed) return;
      emit(
        result.match(
          (failure) => state.copyWith(
            status: BankMessagesStatus.error,
            failure: failure,
          ),
          (items) {
            // A selected item decided elsewhere leaves the selection.
            final ids = {for (final item in items) item.id};
            final selected = state.selectedIds.where(ids.contains).toSet();
            return state.copyWith(
              status: items.isEmpty
                  ? BankMessagesStatus.empty
                  : BankMessagesStatus.ready,
              items: items,
              clearFailure: true,
              selectedIds: selected,
              selectionMode: state.selectionMode && items.isNotEmpty,
            );
          },
        ),
      );
      _completeFirstResult();
    });
    return firstResult.future;
  }

  /// Retry after an error.
  Future<void> retry() => open();

  /// Dismisses the "N suggestions expired" notice (FR-025).
  Future<void> dismissExpiredNotice() async {
    emit(state.copyWith(expiredNoticeCount: 0));
    await _acknowledgeExpiredNotice();
  }

  /// Re-reads the capability, the settings and the permission status,
  /// all prompt-free. Called on open and after returning from the enable
  /// flow, Settings or App info.
  Future<void> refreshScanContext() async {
    final capability = await _capability();
    if (isClosed) return;
    if (!capability.available) {
      emit(state.copyWith(scanAvailable: false));
      return;
    }
    final settings = await _settings.current();
    if (isClosed) return;
    final status = await _permissionStatus();
    if (isClosed) return;
    emit(
      state.copyWith(
        scanAvailable: true,
        isEnabled: settings.match((_) => false, (s) => s.isEnabled),
        scanWindow: settings.match(
          (_) => state.scanWindow,
          (s) => s.scanWindow,
        ),
        permission: status.getOrElse((_) => SmsPermissionStatus.denied),
      ),
    );
  }

  /// "Scan now" (FR-006, FR-007). Ignored while a scan runs or when the
  /// scan is not allowed. The list stays interactive.
  Future<void> scan() async {
    if (isClosed) return;
    if (state.scanning || !state.canScan) return;
    final token = _scanToken = ScanCancellationToken();
    emit(
      state.copyWith(
        scanning: true,
        scanProcessed: 0,
        clearScanSummary: true,
        clearScanFailure: true,
      ),
    );
    final result = await _runInboxScan(
      window: state.scanWindow,
      token: token,
      onProgress: (progress) {
        if (isClosed || !state.scanning) return;
        emit(state.copyWith(scanProcessed: progress.processed));
      },
    );
    if (isClosed) return;
    _scanToken = null;
    emit(
      result.match(
        (failure) => state.copyWith(
          scanning: false,
          scanFailure: failure,
          // A revoked or denied permission shows its banner (FR-070).
          permission: failure is SmsPermissionFailure ? failure.status : null,
        ),
        (summary) => state.copyWith(scanning: false, scanSummary: summary),
      ),
    );
  }

  /// Stops the scan between messages; created items stay (FR-007).
  void cancelScan() => _scanToken?.cancel();

  /// Hides the summary card. The summary is gone for good (in memory
  /// only, CHK003).
  void dismissScanSummary() =>
      emit(state.copyWith(clearScanSummary: true, clearScanFailure: true));

  /// "Open App info" on the banner. Prompts nothing.
  Future<void> openAppInfo() async {
    await _openAppInfo();
  }

  // ------------------------------------------------------------ selection

  /// Enters selection mode, optionally selecting [id] (long-press).
  void startSelection([String? id]) {
    if (state.ignoring || state.items.isEmpty) return;
    emit(
      state.copyWith(
        selectionMode: true,
        selectedIds: {...state.selectedIds, ?id},
        clearIgnoreFailure: true,
      ),
    );
  }

  /// Selects or unselects [id] while in selection mode.
  void toggleSelected(String id) {
    if (!state.selectionMode || state.ignoring) return;
    final selected = {...state.selectedIds};
    if (!selected.remove(id)) selected.add(id);
    emit(state.copyWith(selectedIds: selected));
  }

  /// Leaves selection mode and clears the selection.
  void cancelSelection() {
    if (state.ignoring) return;
    emit(
      state.copyWith(
        selectionMode: false,
        selectedIds: const {},
        clearIgnoreFailure: true,
      ),
    );
  }

  /// Ignores every selected item in one action (FR-064). The page has
  /// already confirmed. All or nothing: on failure the selection stays.
  /// Single-flight.
  Future<void> ignoreSelected() async {
    final ids = state.selectedIds;
    if (state.ignoring || ids.isEmpty) return;
    emit(state.copyWith(ignoring: true, clearIgnoreFailure: true));
    final result = await _ignoreImport(ids: ids);
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(ignoring: false, ignoreFailure: failure),
        (_) => state.copyWith(
          ignoring: false,
          selectionMode: false,
          selectedIds: const {},
          ignoredCount: ids.length,
        ),
      ),
    );
  }

  /// The page announced the "N ignored" result.
  void consumeIgnoredCount() => emit(state.copyWith(clearIgnoredCount: true));

  void _completeFirstResult() {
    final firstResult = _firstResult;
    if (firstResult != null && !firstResult.isCompleted) {
      firstResult.complete();
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
    _completeFirstResult();
  }

  @override
  Future<void> close() {
    _scanToken?.cancel();
    _cancelSubscription();
    return super.close();
  }
}
