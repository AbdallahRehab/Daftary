import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart';
import '../repositories/data_wipe_repository.dart';
import '../services/secure_storage_wiper.dart';

/// The app's one canonical "erase everything on this device" operation.
/// Both 013's Settings → "Delete my data" flow and 015's Forgot-PIN wipe
/// (`WipeAllLocalData`, which delegates here) run through it, so there is a
/// single wipe guarantee rather than two (015 T085, research.md
/// Decision 4; constitution Principle V).
@injectable
class DeleteAllUserData {
  const DeleteAllUserData(
    this._dataWipeRepository,
    this._purgeAIAssistantCredentials,
    this._secureStorageWiper,
  );

  final DataWipeRepository _dataWipeRepository;
  final PurgeAIAssistantCredentials _purgeAIAssistantCredentials;

  /// App Lock's `app_lock.*` keys (015 T085) — bound by that feature's
  /// data layer; this feature only sees the Domain abstraction.
  final SecureStorageWiper _secureStorageWiper;

  /// Forgets the AI assistant's stored API key (014 FR-004 — it lives in
  /// secure storage, which the table wipe cannot reach), clears App Lock's
  /// secure-storage keys, then wipes every table via
  /// [DataWipeRepository.deleteAllUserData] (FR-016, atomic per FR-018).
  ///
  /// Ordering, since secure storage cannot join the database transaction:
  /// - The AI key goes first so a keychain failure stops the deletion
  ///   before any user data is touched — the "nothing was removed" error
  ///   stays true. The reverse failure (key gone, table wipe rolled back)
  ///   is benign: the assistant then just asks for its key again.
  /// - App Lock's keys go next, snapshot-backed ([SecureStorageWiper]):
  ///   they are not benign to lose while the data survives (it would drop
  ///   the user's PIN protection), so if the table wipe then fails they are
  ///   restored exactly — database and App Lock both end up untouched.
  /// - The table wipe runs last: its commit is the one step that cannot be
  ///   undone, so it is the commit point of the whole operation. Nothing
  ///   after it can fail (file clean-up is best-effort).
  ///
  /// Does NOT itself touch `OnboardingCubit` or trigger navigation — that
  /// orchestration belongs to the Presentation layer
  /// (`DeleteAccountCubit`), per research.md Decision 6, so this use case
  /// stays a pure "did the wipe succeed" answer.
  Future<Either<Failure, Unit>> call() async {
    final purged = await _purgeAIAssistantCredentials();
    if (purged case Left(value: final failure)) return Left(failure);

    final SecureStorageRestore restoreSecureStorage;
    switch (await _secureStorageWiper.wipe()) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final restore):
        restoreSecureStorage = restore;
    }

    final wiped = await _dataWipeRepository.deleteAllUserData();
    if (wiped.isLeft()) {
      // The table wipe rolled back; put App Lock back to match. The
      // wipe's own failure is what gets reported either way — the data is
      // intact, which is what the "nothing was removed" message promises.
      await restoreSecureStorage();
    }
    return wiped;
  }
}
