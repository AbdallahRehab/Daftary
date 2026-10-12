import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/usecases/enable_sms_import.dart';
import '../../domain/usecases/get_pending_imports.dart';
import '../../domain/usecases/get_sms_capability.dart';
import '../../domain/usecases/get_sms_permission_status.dart';
import '../../domain/usecases/open_sms_app_info.dart';
import '../../domain/usecases/run_inbox_scan.dart';
import '../../domain/usecases/update_sms_import_preferences.dart';
import 'enable_flow_state.dart';

/// The enable flow (T118, ui-contract §3.2): Explain -> Permission ->
/// Window -> Scanning -> Done.
///
/// - Nothing prompts before [acknowledgeAndContinue] (FR-005), and nothing
///   prompts on open, on resume or from a timer (FR-002, FR-012): the
///   Continue and Try again buttons are the only triggers of
///   `EnableSmsImport`, which is the only caller of `RequestSmsPermission`.
/// - On return from App info ([onResumed] after [openAppInfo]) the status
///   is re-checked without a prompt; when it is now granted the flow
///   enables and advances by itself (FR-072). Otherwise the user can tap
///   Try again.
/// - The scan never creates a record: it stages pending items only.
@injectable
class EnableFlowCubit extends Cubit<EnableFlowState> {
  EnableFlowCubit(
    this._capability,
    this._permissionStatus,
    this._enable,
    this._openAppInfo,
    this._preferences,
    this._runInboxScan,
    this._pendingImports,
  ) : super(const EnableFlowState());

  final GetSmsCapability _capability;
  final GetSmsPermissionStatus _permissionStatus;
  final EnableSmsImport _enable;
  final OpenSmsAppInfo _openAppInfo;
  final UpdateSmsImportPreferences _preferences;
  final RunInboxScan _runInboxScan;
  final GetPendingImports _pendingImports;

  bool _explanationAcknowledged = false;
  bool _awaitingReturn = false;
  ScanCancellationToken? _token;

  /// Reads the capability only. Never prompts.
  Future<void> open() async {
    final capability = await _capability();
    if (isClosed) return;
    emit(
      state.copyWith(
        step: capability.available
            ? EnableFlowStep.explain
            : EnableFlowStep.unavailable,
      ),
    );
  }

  /// "Continue" on the explanation: the first point where the system
  /// prompt may appear (FR-005).
  Future<void> acknowledgeAndContinue() async {
    if (state.step != EnableFlowStep.explain) return;
    _explanationAcknowledged = true;
    await _requestAndEnable();
  }

  /// "Try again": an explicit tap, never automatic. Once on the denied
  /// step; on the restricted step after the user followed the steps.
  Future<void> tryAgain() async {
    if (!state.canTryAgain || !_explanationAcknowledged) return;
    emit(state.copyWith(triedAgain: true));
    await _requestAndEnable();
  }

  /// "Open App info" (permanently denied, restricted). Prompts nothing.
  Future<void> openAppInfo() async {
    _awaitingReturn = true;
    await _openAppInfo();
  }

  /// Called by the page when the app resumes. After App info it re-checks
  /// the status without a prompt and advances when it is now granted.
  Future<void> onResumed() async {
    if (!_awaitingReturn) return;
    if (!_permissionSteps.contains(state.step)) return;
    _awaitingReturn = false;
    final status = await _permissionStatus();
    if (isClosed) return;
    if (status.getOrElse((_) => SmsPermissionStatus.denied) ==
        SmsPermissionStatus.granted) {
      // Granted: `EnableSmsImport` enables without prompting again.
      await _requestAndEnable();
    }
  }

  void selectWindow(ScanWindow window) {
    if (state.step != EnableFlowStep.window) return;
    emit(state.copyWith(window: window));
  }

  /// "Scan" on the window step, or Retry after a failed scan.
  Future<void> startScan() async {
    final canStart =
        state.step == EnableFlowStep.window ||
        (state.step == EnableFlowStep.error && state.failedWhileScanning);
    if (!canStart) return;
    final window = state.window;
    final token = _token = ScanCancellationToken();
    emit(
      state.copyWith(
        step: EnableFlowStep.scanning,
        processed: 0,
        clearSummary: true,
        clearFailure: true,
        failedWhileScanning: false,
      ),
    );
    // Best effort: the chosen window is a preference; the scan below uses
    // it either way.
    await _preferences(ScanWindowChanged(window));
    if (isClosed) return;
    final result = await _runInboxScan(
      window: window,
      token: token,
      onProgress: (progress) {
        if (isClosed || state.step != EnableFlowStep.scanning) return;
        emit(state.copyWith(processed: progress.processed));
      },
    );
    if (isClosed) return;
    _token = null;
    emit(
      result.match(
        (failure) => state.copyWith(
          step: EnableFlowStep.error,
          failure: failure,
          failedWhileScanning: true,
        ),
        (summary) => state.copyWith(
          step: EnableFlowStep.done,
          summary: summary,
          processed: summary.scanned,
        ),
      ),
    );
  }

  /// Stops the scan between messages; created items stay (FR-007).
  void cancelScan() => _token?.cancel();

  /// The first item in review order, for "Review now"; `null` when none.
  Future<String?> firstPendingId() async {
    final items = await _pendingImports();
    return items.match(
      (_) => null,
      (list) => list.isEmpty ? null : list.first.id,
    );
  }

  /// Retry after an enable failure (not a scan failure).
  Future<void> retry() async {
    if (state.step != EnableFlowStep.error) return;
    if (state.failedWhileScanning) return startScan();
    if (!_explanationAcknowledged) {
      emit(state.copyWith(step: EnableFlowStep.explain, clearFailure: true));
      return;
    }
    await _requestAndEnable();
  }

  static const _permissionSteps = {
    EnableFlowStep.denied,
    EnableFlowStep.permanentlyDenied,
    EnableFlowStep.restricted,
  };

  Future<void> _requestAndEnable() async {
    emit(state.copyWith(step: EnableFlowStep.requesting, clearFailure: true));
    final result = await _enable(
      window: state.window,
      explanationAcknowledged: _explanationAcknowledged,
    );
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(
          step: EnableFlowStep.error,
          failure: failure,
          failedWhileScanning: false,
        ),
        (outcome) => state.copyWith(
          step: outcome.enabled
              ? EnableFlowStep.window
              : _stepFor(outcome.status),
        ),
      ),
    );
  }

  static EnableFlowStep _stepFor(SmsPermissionStatus status) =>
      switch (status) {
        SmsPermissionStatus.granted => EnableFlowStep.window,
        SmsPermissionStatus.permanentlyDenied =>
          EnableFlowStep.permanentlyDenied,
        SmsPermissionStatus.restrictedBlocked => EnableFlowStep.restricted,
        SmsPermissionStatus.unavailable => EnableFlowStep.unavailable,
        SmsPermissionStatus.denied ||
        SmsPermissionStatus.revoked => EnableFlowStep.denied,
      };

  @override
  Future<void> close() {
    _token?.cancel();
    return super.close();
  }
}
