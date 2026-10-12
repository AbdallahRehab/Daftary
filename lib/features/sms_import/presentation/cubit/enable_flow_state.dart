import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_value_types.dart';

/// The steps of the enable flow (ui-contract §3.2): a linear state
/// machine on one page. The system prompt is only reachable after
/// [explain] was acknowledged (FR-005).
enum EnableFlowStep {
  /// Reading the capability.
  loading,

  /// No inbox access here (iOS, macOS, an SMS-free build): paste only.
  unavailable,

  /// What is read, what is never done, how to turn it off.
  explain,

  /// The system dialog is up; every button is disabled.
  requesting,

  /// Denied, can ask again once (FR-012).
  denied,

  /// Denied for good: App info is the way out (FR-070).
  permanentlyDenied,

  /// Inferred Android restricted-settings block (FR-072).
  restricted,

  /// Granted and enabled: choose 7 / 30 / 90 days.
  window,

  /// The inbox scan is running (FR-007).
  scanning,

  /// The content-free summary (FR-097).
  done,

  /// Enabling or scanning failed.
  error,
}

/// Immutable state of `EnableFlowCubit`. It holds counts, codes and the
/// in-memory scan summary only, never message content.
class EnableFlowState extends Equatable {
  const EnableFlowState({
    this.step = EnableFlowStep.loading,
    this.window = ScanWindow.defaultWindow,
    this.triedAgain = false,
    this.processed = 0,
    this.summary,
    this.failure,
    this.failedWhileScanning = false,
  });

  final EnableFlowStep step;
  final ScanWindow window;

  /// The denied step offers "Try again" once (FR-012).
  final bool triedAgain;

  /// Messages processed so far while scanning.
  final int processed;

  /// The finished scan's summary (counts and the Skipped list).
  final ScanSummary? summary;
  final Failure? failure;

  /// The error came from the scan, so partial results were kept.
  final bool failedWhileScanning;

  /// Buttons are disabled while the system dialog is up.
  bool get isBusy => step == EnableFlowStep.requesting;

  /// "Try again" on the denied step, once; always on the restricted step,
  /// where step 4 of the guidance tells the user to tap it.
  bool get canTryAgain => switch (step) {
    EnableFlowStep.denied => !triedAgain,
    EnableFlowStep.restricted => true,
    _ => false,
  };

  EnableFlowState copyWith({
    EnableFlowStep? step,
    ScanWindow? window,
    bool? triedAgain,
    int? processed,
    ScanSummary? summary,
    bool clearSummary = false,
    Failure? failure,
    bool clearFailure = false,
    bool? failedWhileScanning,
  }) {
    return EnableFlowState(
      step: step ?? this.step,
      window: window ?? this.window,
      triedAgain: triedAgain ?? this.triedAgain,
      processed: processed ?? this.processed,
      summary: clearSummary ? null : (summary ?? this.summary),
      failure: clearFailure ? null : (failure ?? this.failure),
      failedWhileScanning: failedWhileScanning ?? this.failedWhileScanning,
    );
  }

  @override
  List<Object?> get props => [
    step,
    window,
    triedAgain,
    processed,
    summary,
    failure,
    failedWhileScanning,
  ];

  /// Redacted: codes and counts only (FR-097).
  @override
  String toString() =>
      'EnableFlowState(step: ${step.name}, window: ${window.days}, '
      'processed: $processed, hasSummary: ${summary != null}, '
      'failure: ${failure.runtimeType})';
}
