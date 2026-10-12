import 'package:equatable/equatable.dart';

/// The READ_SMS permission state the UI acts on (research Decision 2,
/// data-model §2.9). Output of `classifySmsPermission`.
enum SmsPermissionStatus {
  granted,

  /// Can ask again, once, never silently (FR-012).
  denied,
  permanentlyDenied,

  /// Inferred: Android 15+ restricted settings blocked the dialog (FR-072).
  restrictedBlocked,

  /// Was granted, now off (detected on resume, FR-070).
  revoked,

  /// Capability off or not Android.
  unavailable,
}

/// How the app was installed, as reported by the platform
/// (sms-platform-channel §2.3).
enum SmsInstallSource {
  store,
  notStore,
  unknown;

  /// Unknown or null -> [unknown].
  static SmsInstallSource fromWire(String? value) => switch (value) {
    'store' => store,
    'notStore' => notStore,
    _ => unknown,
  };
}

/// The facts the platform reports after a permission request
/// (sms-platform-channel §2.3). The decision is made in Dart by
/// `classifySmsPermission`.
class SmsPermissionResult extends Equatable {
  const SmsPermissionResult({
    required this.granted,
    required this.shouldShowRationale,
    required this.dialogShown,
    required this.sdkInt,
    required this.installSource,
  });

  final bool granted;
  final bool shouldShowRationale;

  /// The activity paused between the request and the result, so the system
  /// dialog was on screen.
  final bool dialogShown;
  final int sdkInt;
  final SmsInstallSource installSource;

  @override
  List<Object?> get props => [
    granted,
    shouldShowRationale,
    dialogShown,
    sdkInt,
    installSource,
  ];
}
