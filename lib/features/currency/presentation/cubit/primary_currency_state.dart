import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

enum PrimaryCurrencyStatus { loading, ready, loadFailure }

/// The outcome of the latest change attempt, for one-shot UI feedback.
/// Reset to [none] at the start of every attempt.
enum PrimaryCurrencyChangeOutcome { none, changed, failed, invalidRate }

/// Immutable state for `PrimaryCurrencyCubit`.
class PrimaryCurrencyState extends Equatable {
  const PrimaryCurrencyState({
    this.status = PrimaryCurrencyStatus.loading,
    this.primary = Currency.egp,
    this.isSubmitting = false,
    this.pendingTarget,
    this.rateRequiredFor,
    this.outcome = PrimaryCurrencyChangeOutcome.none,
  });

  final PrimaryCurrencyStatus status;
  final Currency primary;

  /// `true` while a change is in flight — every change control is disabled
  /// so a second tap cannot start a second switch.
  final bool isSubmitting;

  /// Set when a switch was refused for want of a rate (FR-012): the
  /// currency the user asked to switch to...
  final Currency? pendingTarget;

  /// ...and the outgoing primary a rate is needed for.
  final Currency? rateRequiredFor;

  final PrimaryCurrencyChangeOutcome outcome;

  bool get isRatePromptPending =>
      pendingTarget != null && rateRequiredFor != null;

  PrimaryCurrencyState copyWith({
    PrimaryCurrencyStatus? status,
    Currency? primary,
    bool? isSubmitting,
    Currency? pendingTarget,
    Currency? rateRequiredFor,
    bool clearPending = false,
    PrimaryCurrencyChangeOutcome? outcome,
  }) {
    return PrimaryCurrencyState(
      status: status ?? this.status,
      primary: primary ?? this.primary,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingTarget: clearPending ? null : pendingTarget ?? this.pendingTarget,
      rateRequiredFor: clearPending
          ? null
          : rateRequiredFor ?? this.rateRequiredFor,
      outcome: outcome ?? this.outcome,
    );
  }

  @override
  List<Object?> get props => [
    status,
    primary,
    isSubmitting,
    pendingTarget,
    rateRequiredFor,
    outcome,
  ];
}
