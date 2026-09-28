import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../data_privacy/domain/usecases/delete_all_user_data.dart';

/// The Forgot-PIN path's destructive branch (FR-018/FR-019): erases every
/// piece of local app data and returns the app to its first-launch state.
///
/// Seam with 013 (research.md Decision 4, resolved by T085): this does NOT
/// carry a wipe of its own. It delegates to 013's canonical
/// `DeleteAllUserData`, which — through the `SecureStorageWiper` that App
/// Lock binds (`AppLockSecureStorageWiper`) — already clears all three
/// `app_lock.*` secure-storage keys together with every `AppDatabase`
/// table. One implementation, one atomicity guarantee, whether the wipe
/// starts from Settings or from the lock screen (constitution Principle V).
///
/// What that covers:
/// - every table, in one drift transaction (`DataWipe.deleteAllUserData`),
///   including `onboarding_status` — so the onboarding-seen flag is reset
///   by the same commit and the app is in first-launch state (FR-019);
/// - the App Lock config, PIN credential and lockout state, snapshot-backed
///   so a failed table wipe restores them: all-or-nothing across both
///   storage mechanisms;
/// - the AI assistant's stored API key;
/// - the cloud session (021) — but not the cloud copy: it stays reachable
///   only through an email sign-in, never merely by holding the phone.
///
/// Re-resolving `OnboardingCubit`, navigating, and dismissing the lock
/// screen are Presentation concerns (`ForgotPinCubit`/`ForgotPinPage`).
@injectable
class WipeAllLocalData {
  const WipeAllLocalData(this._deleteAllUserData);

  final DeleteAllUserData _deleteAllUserData;

  /// `Right(unit)` once everything is gone; any `Left` means no user data
  /// was removed — the database and App Lock's keys are both intact.
  Future<Either<Failure, Unit>> call() =>
      _deleteAllUserData(eraseCloudCopy: false);
}
