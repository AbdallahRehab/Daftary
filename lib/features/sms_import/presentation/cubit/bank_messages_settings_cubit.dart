import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/usecases/disable_sms_import.dart';
import '../../domain/usecases/get_scan_counts.dart';
import '../../domain/usecases/get_sms_capability.dart';
import '../../domain/usecases/get_sms_permission_status.dart';
import '../../domain/usecases/open_sms_app_info.dart';
import '../../domain/usecases/update_sms_import_preferences.dart';
import '../../domain/usecases/watch_sms_import_settings.dart';
import 'bank_messages_settings_state.dart';

/// Settings -> Bank messages (T118, ui-contract §3.1). Reads the
/// capability, the prompt-free permission status, the settings and the
/// content-free counters; writes only the preferences. It never prompts:
/// "Turn on" navigates to the enable flow (FR-002). "Turn off" goes
/// through `DisableSmsImport` after the page asked whether to also delete
/// the pending items (FR-078, T142).
@injectable
class BankMessagesSettingsCubit extends Cubit<BankMessagesSettingsState> {
  BankMessagesSettingsCubit(
    this._capability,
    this._permissionStatus,
    this._settings,
    this._counts,
    this._preferences,
    this._openAppInfo,
    this._disable,
  ) : super(const BankMessagesSettingsState());

  final GetSmsCapability _capability;
  final GetSmsPermissionStatus _permissionStatus;
  final WatchSmsImportSettings _settings;
  final GetScanCounts _counts;
  final UpdateSmsImportPreferences _preferences;
  final OpenSmsAppInfo _openAppInfo;
  final DisableSmsImport _disable;

  StreamSubscription<void>? _subscription;

  Future<void> open() async {
    _cancelSubscription();
    emit(
      state.copyWith(
        status: BankMessagesSettingsStatus.loading,
        clearFailure: true,
      ),
    );
    final capability = await _capability();
    if (isClosed) return;
    var permission = SmsPermissionStatus.unavailable;
    if (capability.available) {
      final status = await _permissionStatus();
      if (isClosed) return;
      permission = status.getOrElse((_) => SmsPermissionStatus.denied);
    }
    emit(
      state.copyWith(
        capabilityAvailable: capability.available,
        permission: permission,
      ),
    );

    final first = Completer<void>();
    _subscription = _settings()
        .asyncMap((result) async {
          final counts = result.isRight() ? await _counts() : null;
          return (result, counts);
        })
        .listen((event) {
          if (isClosed) return;
          final (result, counts) = event;
          emit(
            result.match(
              (failure) => state.copyWith(
                status: BankMessagesSettingsStatus.error,
                failure: failure,
              ),
              (settings) => state.copyWith(
                status: BankMessagesSettingsStatus.ready,
                settings: settings,
                counts: counts?.getOrElse((_) => state.counts),
                clearFailure: true,
              ),
            ),
          );
          if (!first.isCompleted) first.complete();
        });
    return first.future;
  }

  Future<void> retry() => open();

  /// Prompt-free; for the page's resume handling (FR-070).
  Future<void> refreshPermission() async {
    if (!state.capabilityAvailable) return;
    final status = await _permissionStatus();
    if (isClosed) return;
    emit(state.copyWith(permission: status.getOrElse((_) => state.permission)));
  }

  Future<void> setWindow(ScanWindow window) => _write(
    BankMessagesSettingsControl.window,
    ScanWindowChanged(window),
    skip: window == state.settings.scanWindow,
  );

  Future<void> setCountCashWithdrawals(bool value) => _write(
    BankMessagesSettingsControl.countCash,
    CountCashChanged(value),
    skip: value == state.settings.countCashWithdrawals,
  );

  /// "Turn off" after the page's question (FR-078): the feature is switched
  /// off first, so a running scan or catch-up stops at its next page; then
  /// the pending items are deleted only when [deletePending]. Muted
  /// senders, learned categories, tombstones and saved records are kept.
  /// Single-flight; a failure raises the one-shot save failure.
  Future<void> turnOff({required bool deletePending}) async {
    if (state.submitting != null || !state.isEnabled) return;
    emit(
      state.copyWith(
        submitting: BankMessagesSettingsControl.turnOff,
        saveFailed: false,
        turnedOff: false,
        clearDeletedPendingCount: true,
      ),
    );
    final result = await _disable(deletePending: deletePending);
    if (isClosed) return;
    emit(
      result.match(
        (_) => state.copyWith(clearSubmitting: true, saveFailed: true),
        (deleted) => state.copyWith(
          clearSubmitting: true,
          // Off now; the settings stream confirms it on its next event.
          settings: state.settings.copyWith(isEnabled: false),
          turnedOff: true,
          deletedPendingCount: deletePending ? deleted : null,
          clearDeletedPendingCount: !deletePending,
        ),
      ),
    );
  }

  /// Clears the one-shot Turn off outcome after the page showed it.
  void turnedOffShown() {
    if (state.turnedOff) {
      emit(state.copyWith(turnedOff: false, clearDeletedPendingCount: true));
    }
  }

  /// "Open App info" on the permission banner. Prompts nothing.
  Future<void> openAppInfo() async {
    await _openAppInfo();
  }

  /// Clears the one-shot save failure after the page showed it.
  void saveFailureShown() {
    if (state.saveFailed) emit(state.copyWith(saveFailed: false));
  }

  Future<void> _write(
    BankMessagesSettingsControl control,
    SmsPreferenceChange change, {
    required bool skip,
  }) async {
    // Double taps and concurrent writes are ignored.
    if (skip || state.submitting != null) return;
    emit(state.copyWith(submitting: control, saveFailed: false));
    final Either<Failure, Unit> result = await _preferences(change);
    if (isClosed) return;
    emit(state.copyWith(clearSubmitting: true, saveFailed: result.isLeft()));
  }

  /// Not awaited: an `async*` source that is suspended in `await for`
  /// only finishes its cancel on its next event, so awaiting it here
  /// could hang `close` (same pattern as `BankMessagesCubit`).
  void _cancelSubscription() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
