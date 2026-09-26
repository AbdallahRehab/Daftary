import 'package:equatable/equatable.dart';

/// Where app startup is (data-model.md, 019). `ready` is terminal.
enum AppStartupStatus { idle, preparing, ready, failed }

/// Why startup failed. Both map to the same user-facing message; the
/// distinction exists only for logs and tests (data-model.md, 019).
enum StartupFailure { error, timeout }

/// Immutable state for `AppStartupCubit` (constitution Principle IV).
class AppStartupState extends Equatable {
  const AppStartupState({
    this.status = AppStartupStatus.idle,
    this.appearanceResolved = false,
    this.failure,
    this.isRetry = false,
  });

  final AppStartupStatus status;

  /// `SettingsCubit.initialize()` has completed, so language and theme are
  /// final. Gates the app's `locale` and the splash text reveal, which is
  /// why it never goes back from `true` to `false`.
  final bool appearanceResolved;

  /// Set only while [status] is [AppStartupStatus.failed].
  final StartupFailure? failure;

  /// Stored rather than derived: set by `retry()` so the error layout keeps
  /// showing (button disabled) while the retry runs, instead of flashing
  /// back to the brand layout. Not reset on `ready`, which is terminal.
  final bool isRetry;

  bool get isReady => status == AppStartupStatus.ready;

  bool get isFailed => status == AppStartupStatus.failed;

  /// [failure] is nullable, so `null` can't mean "clear it"; pass
  /// [clearFailure] to drop it explicitly.
  AppStartupState copyWith({
    AppStartupStatus? status,
    bool? appearanceResolved,
    StartupFailure? failure,
    bool clearFailure = false,
    bool? isRetry,
  }) {
    return AppStartupState(
      status: status ?? this.status,
      appearanceResolved: appearanceResolved ?? this.appearanceResolved,
      failure: clearFailure ? null : (failure ?? this.failure),
      isRetry: isRetry ?? this.isRetry,
    );
  }

  @override
  List<Object?> get props => [status, appearanceResolved, failure, isRetry];
}
