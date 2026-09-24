import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_lock_config.dart';

enum AppLockSettingsStatus {
  loading,

  /// The configuration could not be read at all.
  loadFailure,

  /// Loaded; every control is interactive.
  ready,

  /// A settings change is in flight. Every action is refused while in this
  /// state (Duplicate Action Protection).
  submitting,
}

/// A one-shot outcome the page reports (snackbar) after a successful
/// action.
enum AppLockSettingsOutcome { enabled, disabled, pinChanged }

/// Immutable state for `AppLockSettingsCubit` (constitution Principle IV).
///
/// Holds no PIN material of any kind — PINs only ever pass straight through
/// to a use case.
class AppLockSettingsState extends Equatable {
  const AppLockSettingsState({
    this.status = AppLockSettingsStatus.loading,
    this.config = const AppLockConfig.initial(),
    this.isBiometricAvailable = false,
    this.failure,
    this.outcome,
  });

  final AppLockSettingsStatus status;
  final AppLockConfig config;

  /// Whether the device has biometric hardware with something enrolled —
  /// queried live on every load, never cached across visits.
  final bool isBiometricAvailable;

  /// The last action's failure, cleared by the next action.
  final Failure? failure;

  /// Set only on the emission that completes an action; cleared by the
  /// next emission of any kind.
  final AppLockSettingsOutcome? outcome;

  bool get isEnabled => config.isEnabled;
  bool get isSubmitting => status == AppLockSettingsStatus.submitting;
  bool get isReady => status == AppLockSettingsStatus.ready;

  AppLockSettingsState copyWith({
    AppLockSettingsStatus? status,
    AppLockConfig? config,
    bool? isBiometricAvailable,
    Failure? failure,
    bool clearFailure = false,
    AppLockSettingsOutcome? outcome,
  }) {
    return AppLockSettingsState(
      status: status ?? this.status,
      config: config ?? this.config,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      failure: clearFailure ? null : (failure ?? this.failure),
      // Never carried over: an outcome describes one emission only.
      outcome: outcome,
    );
  }

  @override
  List<Object?> get props => [
    status,
    config,
    isBiometricAvailable,
    failure,
    outcome,
  ];
}
