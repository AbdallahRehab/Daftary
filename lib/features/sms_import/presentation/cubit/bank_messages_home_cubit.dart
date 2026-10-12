import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/sms_value_types.dart';
import '../../domain/usecases/update_sms_import_preferences.dart';
import '../../domain/usecases/watch_pending_import_count.dart';
import '../../domain/usecases/watch_sms_import_settings.dart';

/// What the Home bank-messages card shows. Flags and a count only, never
/// content (FR-050).
class BankMessagesHomeState extends Equatable {
  const BankMessagesHomeState({
    this.showOnboarding = false,
    this.dismissing = false,
    this.pendingCount = 0,
  });

  /// The FR-004 onboarding variant: not enabled and not dismissed.
  final bool showOnboarding;
  final bool dismissing;

  /// How many items wait for review (T129). A failed read counts as 0.
  final int pendingCount;

  /// The count variant is rendered only while something waits.
  bool get showCount => pendingCount > 0;

  BankMessagesHomeState copyWith({
    bool? showOnboarding,
    bool? dismissing,
    int? pendingCount,
  }) => BankMessagesHomeState(
    showOnboarding: showOnboarding ?? this.showOnboarding,
    dismissing: dismissing ?? this.dismissing,
    pendingCount: pendingCount ?? this.pendingCount,
  );

  @override
  List<Object?> get props => [showOnboarding, dismissing, pendingCount];
}

/// The Home card's cubit (T122, ui-contract §2). Home creates it only
/// when the feature flag is on; without the SMS capability the card shows
/// only the pending count (paste-only platforms, CHK036). The dashboard
/// cubit is untouched. It never prompts: "Set up" navigates to the enable
/// flow.
@injectable
class BankMessagesHomeCubit extends Cubit<BankMessagesHomeState> {
  BankMessagesHomeCubit(this._settings, this._preferences, this._count)
    : super(const BankMessagesHomeState());

  final WatchSmsImportSettings _settings;
  final UpdateSmsImportPreferences _preferences;
  final WatchPendingImportCount _count;

  StreamSubscription<void>? _subscription;
  StreamSubscription<void>? _countSubscription;

  /// Follows the settings and the pending count; a failed read hides the
  /// variant it feeds.
  void open() {
    _cancelSubscription();
    _subscription = _settings().listen((result) {
      if (isClosed) return;
      final show = result.match(
        (_) => false,
        (s) => !s.isEnabled && !s.onboardingDismissed,
      );
      emit(state.copyWith(showOnboarding: show, dismissing: false));
    });
    _countSubscription = _count().listen((result) {
      if (isClosed) return;
      emit(state.copyWith(pendingCount: result.getOrElse((_) => 0)));
    });
  }

  /// "Dismiss" is permanent (FR-004).
  Future<void> dismiss() async {
    if (state.dismissing || !state.showOnboarding) return;
    emit(state.copyWith(dismissing: true));
    final result = await _preferences(const OnboardingDismissed());
    if (isClosed) return;
    if (result.isLeft()) {
      emit(state.copyWith(showOnboarding: true, dismissing: false));
    }
    // On success the settings stream hides the card.
  }

  /// Not awaited: an `async*` source suspended in `await for` only
  /// finishes its cancel on its next event, so awaiting it could hang
  /// `close` (same pattern as `BankMessagesCubit`).
  void _cancelSubscription() {
    unawaited(_subscription?.cancel());
    unawaited(_countSubscription?.cancel());
    _subscription = null;
    _countSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
