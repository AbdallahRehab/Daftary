import '../entities/sms_permission_status.dart';

/// Classifies a READ_SMS permission result (research Decision 2,
/// sms-platform-channel §2.3, FR-072). Pure; the platform only reports
/// facts.
///
/// In order, the first match decides:
/// 1. granted -> [SmsPermissionStatus.granted];
/// 2. not granted after a prior grant ([previouslyGranted]) ->
///    [SmsPermissionStatus.revoked] (FR-070). Restricted settings block a
///    grant from ever happening, so a prior grant rules them out;
/// 3. not granted, no dialog shown, Android 15+ (`sdkInt >= 35`) and not a
///    store install -> [SmsPermissionStatus.restrictedBlocked] (inferred: no
///    public API reports it);
/// 4. not granted, no rationale, and the app had asked before
///    ([previouslyRequested]) -> [SmsPermissionStatus.permanentlyDenied];
/// 5. otherwise [SmsPermissionStatus.denied]: the app may ask again, once,
///    never silently (FR-012).
///
/// [previouslyGranted] is for the prompt-free resume check; the request
/// path passes `false`, because a fresh request is classified on its own
/// result.
SmsPermissionStatus classifySmsPermission(
  SmsPermissionResult result, {
  required bool previouslyRequested,
  bool previouslyGranted = false,
}) {
  if (result.granted) return SmsPermissionStatus.granted;
  if (previouslyGranted) return SmsPermissionStatus.revoked;
  if (!result.dialogShown &&
      result.sdkInt >= 35 &&
      result.installSource != SmsInstallSource.store) {
    return SmsPermissionStatus.restrictedBlocked;
  }
  if (!result.shouldShowRationale && previouslyRequested) {
    return SmsPermissionStatus.permanentlyDenied;
  }
  return SmsPermissionStatus.denied;
}
