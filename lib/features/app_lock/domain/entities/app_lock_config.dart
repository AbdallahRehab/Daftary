import 'package:equatable/equatable.dart';

/// The ways the lock screen can be dismissed (015 data-model.md).
enum UnlockMethod { pin, biometric }

/// How long the app may sit in the background before resuming requires
/// unlocking again (FR-011). Default [after1min] on first enable.
enum InactivityTimeout {
  immediately(Duration.zero),
  after30s(Duration(seconds: 30)),
  after1min(Duration(minutes: 1)),
  after5min(Duration(minutes: 5));

  const InactivityTimeout(this.duration);

  /// Time spent genuinely backgrounded (`AppLifecycleState.paused`) after
  /// which the app locks. [Duration.zero] locks on every backgrounding.
  final Duration duration;

  /// The value used when App Lock has never been configured.
  static const InactivityTimeout defaultTimeout = InactivityTimeout.after1min;
}

/// The user's App Lock configuration — a single record per device, held in
/// OS secure storage, never in `AppDatabase` (research.md Decision 2).
///
/// Invariant (FR-002): `isEnabled == true` implies
/// `activeUnlockMethods.contains(UnlockMethod.pin)`. Enforced by the use
/// case layer (`EnableAppLock` requires a PIN first), not by this type.
class AppLockConfig extends Equatable {
  const AppLockConfig({
    required this.isEnabled,
    required this.activeUnlockMethods,
    required this.inactivityTimeout,
    this.pinLastChangedAt,
  });

  /// Never configured: disabled, no unlock methods, 1-minute timeout
  /// (contracts/app_lock_repository.md `getConfig`).
  const AppLockConfig.initial()
    : isEnabled = false,
      activeUnlockMethods = const <UnlockMethod>{},
      inactivityTimeout = InactivityTimeout.defaultTimeout,
      pinLastChangedAt = null;

  final bool isEnabled;

  /// Subset of {pin, biometric}. Treat as immutable — always replaced via
  /// [copyWith], never mutated in place.
  final Set<UnlockMethod> activeUnlockMethods;
  final InactivityTimeout inactivityTimeout;

  /// Audit-only; never used to reconstruct the PIN.
  final DateTime? pinLastChangedAt;

  bool get isBiometricEnabled =>
      activeUnlockMethods.contains(UnlockMethod.biometric);

  bool get hasPin => activeUnlockMethods.contains(UnlockMethod.pin);

  AppLockConfig copyWith({
    bool? isEnabled,
    Set<UnlockMethod>? activeUnlockMethods,
    InactivityTimeout? inactivityTimeout,
    DateTime? pinLastChangedAt,
    bool clearPinLastChangedAt = false,
  }) {
    return AppLockConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      activeUnlockMethods: Set<UnlockMethod>.unmodifiable(
        activeUnlockMethods ?? this.activeUnlockMethods,
      ),
      inactivityTimeout: inactivityTimeout ?? this.inactivityTimeout,
      pinLastChangedAt: clearPinLastChangedAt
          ? null
          : (pinLastChangedAt ?? this.pinLastChangedAt),
    );
  }

  @override
  List<Object?> get props => [
    isEnabled,
    activeUnlockMethods,
    inactivityTimeout,
    pinLastChangedAt,
  ];
}
