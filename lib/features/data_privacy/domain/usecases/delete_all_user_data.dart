import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart';
import '../repositories/data_wipe_repository.dart';

@injectable
class DeleteAllUserData {
  const DeleteAllUserData(
    this._dataWipeRepository,
    this._purgeAIAssistantCredentials,
  );

  final DataWipeRepository _dataWipeRepository;
  final PurgeAIAssistantCredentials _purgeAIAssistantCredentials;

  /// Forgets the AI assistant's stored API key (014 FR-004 — it lives in
  /// secure storage, which the table wipe cannot reach), then wipes every
  /// table via [DataWipeRepository.deleteAllUserData] (FR-016, atomic per
  /// FR-018).
  ///
  /// The key goes first so a keychain failure stops the deletion before
  /// any user data is touched — the "nothing was removed" error stays
  /// true. The reverse failure (key gone, table wipe rolled back) is
  /// benign: the assistant then just asks for its key again.
  ///
  /// Does NOT itself touch `OnboardingCubit` or trigger navigation — that
  /// orchestration belongs to the Presentation layer
  /// (`DeleteAccountCubit`), per research.md Decision 6, so this use case
  /// stays a pure "did the wipe succeed" answer.
  Future<Either<Failure, Unit>> call() async {
    final purged = await _purgeAIAssistantCredentials();
    if (purged case Left(value: final failure)) return Left(failure);
    return _dataWipeRepository.deleteAllUserData();
  }
}
