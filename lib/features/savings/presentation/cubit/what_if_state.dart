import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/savings_goal_detail.dart';
import '../../domain/entities/what_if_mode.dart';
import '../../domain/entities/what_if_result.dart';

enum WhatIfStatus {
  loading,
  ready,

  /// The goal is achieved: nothing left to plan for (FR-016).
  achieved,

  /// The goal could not be loaded.
  failure,
}

enum WhatIfApplyStatus { idle, applying, applied, failed }

/// Immutable state for `WhatIfCubit` (constitution Principle IV — updated
/// exclusively via [copyWith]).
///
/// The real goal ([detail]) and the hypothetical answer ([result]) are
/// deliberately separate fields: exploring only ever sets [result], and
/// [detail] is exactly what was read when the calculator opened (FR-015).
class WhatIfState extends Equatable {
  const WhatIfState({
    required this.goalId,
    this.status = WhatIfStatus.loading,
    this.detail,
    this.mode = WhatIfMode.monthlyContribution,
    this.monthlyInput = '',
    this.targetDate,
    this.monthlyInvalid = false,
    this.targetDateInvalid = false,
    this.isCalculating = false,
    this.result,
    this.resultMode,
    this.applyStatus = WhatIfApplyStatus.idle,
    this.appliedGoal,
    this.failure,
  });

  final String goalId;
  final WhatIfStatus status;

  /// The real goal and its progress — never changed by exploring.
  final SavingsGoalDetail? detail;
  final WhatIfMode mode;

  /// The hypothetical monthly contribution, as typed.
  final String monthlyInput;

  /// The hypothetical target date.
  final DateTime? targetDate;
  final bool monthlyInvalid;
  final bool targetDateInvalid;
  final bool isCalculating;

  /// The hypothetical answer for the current input; cleared whenever the
  /// input or [mode] changes, so it never describes inputs no longer shown.
  final WhatIfResult? result;

  /// The mode [result] was calculated in — what applying it changes.
  final WhatIfMode? resultMode;
  final WhatIfApplyStatus applyStatus;

  /// The goal as saved by a successful apply.
  final SavingsGoal? appliedGoal;
  final Failure? failure;

  bool get isApplying => applyStatus == WhatIfApplyStatus.applying;
  bool get canApply => result != null && !isApplying && !isCalculating;

  WhatIfState copyWith({
    WhatIfStatus? status,
    SavingsGoalDetail? detail,
    WhatIfMode? mode,
    String? monthlyInput,
    DateTime? targetDate,
    bool? monthlyInvalid,
    bool? targetDateInvalid,
    bool? isCalculating,
    WhatIfResult? result,
    WhatIfMode? resultMode,
    bool clearResult = false,
    WhatIfApplyStatus? applyStatus,
    SavingsGoal? appliedGoal,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return WhatIfState(
      goalId: goalId,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      mode: mode ?? this.mode,
      monthlyInput: monthlyInput ?? this.monthlyInput,
      targetDate: targetDate ?? this.targetDate,
      monthlyInvalid: monthlyInvalid ?? this.monthlyInvalid,
      targetDateInvalid: targetDateInvalid ?? this.targetDateInvalid,
      isCalculating: isCalculating ?? this.isCalculating,
      result: clearResult ? null : (result ?? this.result),
      resultMode: clearResult ? null : (resultMode ?? this.resultMode),
      applyStatus: applyStatus ?? this.applyStatus,
      appliedGoal: appliedGoal ?? this.appliedGoal,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    goalId,
    status,
    detail,
    mode,
    monthlyInput,
    targetDate,
    monthlyInvalid,
    targetDateInvalid,
    isCalculating,
    result,
    resultMode,
    applyStatus,
    appliedGoal,
    failure,
  ];
}
