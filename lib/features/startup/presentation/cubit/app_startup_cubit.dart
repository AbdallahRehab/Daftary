import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import 'app_startup_state.dart';

/// Orchestrates the startup I/O that used to be awaited in `main.dart`
/// before `runApp`, so the branded splash can show immediately while it
/// runs (FR-011). Root-scoped (like [SettingsCubit] and [OnboardingCubit])
/// because `main.dart`, the splash gate and integration tests all share one
/// startup run.
@lazySingleton
class AppStartupCubit extends Cubit<AppStartupState> {
  AppStartupCubit(
    this._settings,
    this._onboarding, {
    @ignoreParam Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout,
       super(const AppStartupState());

  final SettingsCubit _settings;
  final OnboardingCubit _onboarding;

  /// Budget per `start`/`retry` attempt (FR-015). A constructor parameter
  /// rather than a constant so tests can use a short budget.
  final Duration _timeout;

  /// The latest attempt's future, returned to repeated [start] callers so
  /// initialization never runs twice (FR-012).
  Future<void>? _run;

  /// Memoized step futures. A completed step stays here so retry never
  /// re-runs it; an errored step is cleared so retry re-runs it; a step still
  /// pending after a timeout stays so retry joins it rather than starting
  /// the same I/O a second time (FR-016).
  Future<void>? _settingsStep;
  Future<void>? _onboardingStep;

  /// Incremented per attempt. A timed-out attempt keeps running in the
  /// background (its steps can't be cancelled), so only the current attempt
  /// may emit; otherwise a stale attempt could flip a failed or retrying
  /// state to ready behind the current attempt's back.
  int _attemptId = 0;

  /// Runs startup once. Safe to call repeatedly: later calls return the
  /// in-flight (or finished) future and emit nothing (FR-012).
  Future<void> start() {
    if (state.status != AppStartupStatus.idle) {
      return _run ?? Future<void>.value();
    }
    return _run = _attempt(state.copyWith(status: AppStartupStatus.preparing));
  }

  /// Re-attempts startup after a failure (FR-016). Ignored unless the state
  /// is failed, which absorbs duplicate taps on the retry button.
  Future<void> retry() {
    if (!state.isFailed) return _run ?? Future<void>.value();
    return _run = _attempt(
      state.copyWith(
        status: AppStartupStatus.preparing,
        isRetry: true,
        clearFailure: true,
      ),
    );
  }

  /// Completes when the state first becomes ready, immediately if it
  /// already is. Never completes with an error: if the cubit closes first,
  /// `orElse` completes it with the last state instead of throwing
  /// `StateError`, so callers must still check `state.isReady`.
  Future<void> get whenReady => state.isReady
      ? Future<void>.value()
      : stream.firstWhere((s) => s.isReady, orElse: () => state).then((_) {});

  Future<void> _attempt(AppStartupState preparing) async {
    final attemptId = ++_attemptId;
    emit(preparing);
    try {
      await _runSteps(attemptId).timeout(_timeout);
    } on TimeoutException catch (e, s) {
      _fail(attemptId, StartupFailure.timeout, e, s);
    } catch (e, s) {
      // Any step failure becomes a recoverable failed state instead of an
      // exception escaping into `main.dart`'s unawaited call (FR-015).
      _fail(attemptId, StartupFailure.error, e, s);
    }
  }

  Future<void> _runSteps(int attemptId) async {
    await (_settingsStep ??= _settings.initialize().catchError((
      Object e,
      StackTrace s,
    ) {
      _settingsStep = null;
      Error.throwWithStackTrace(e, s);
    }));
    if (!_isCurrent(attemptId)) return;
    emit(state.copyWith(appearanceResolved: true));

    await (_onboardingStep ??= _onboarding.initialize().catchError((
      Object e,
      StackTrace s,
    ) {
      _onboardingStep = null;
      Error.throwWithStackTrace(e, s);
    }));
    if (!_isCurrent(attemptId)) return;
    emit(state.copyWith(status: AppStartupStatus.ready));
  }

  void _fail(
    int attemptId,
    StartupFailure failure,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      'startup failed',
      name: 'daftary.startup',
      error: error,
      stackTrace: stackTrace,
    );
    if (!_isCurrent(attemptId)) return;
    emit(state.copyWith(status: AppStartupStatus.failed, failure: failure));
  }

  bool _isCurrent(int attemptId) => !isClosed && attemptId == _attemptId;
}
