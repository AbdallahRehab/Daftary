import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ai_assistant_repository.dart';

/// Forgets the stored provider API key in every secure-storage slot
/// without touching the assistant's database rows — the piece of a full
/// "delete all my data" (013 FR-016) that a database wipe cannot reach,
/// because the key never lives in the database (014 FR-004). Exposed as a
/// use case so the data-privacy feature depends on this feature's Domain
/// layer only, never on its secure-storage implementation.
@injectable
class PurgeAIAssistantCredentials {
  const PurgeAIAssistantCredentials(this._repository);

  final AIAssistantRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.purgeCredentials();
}
