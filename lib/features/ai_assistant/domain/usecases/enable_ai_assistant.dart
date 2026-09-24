import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_assistant_settings.dart';
import '../entities/ai_api_key_rules.dart';
import '../repositories/ai_assistant_repository.dart';

/// Turns the assistant on (User Story 1, FR-002/FR-003): stores the key,
/// records consent, and flips `isEnabled` — atomically, in the repository.
///
/// Consent is a required argument, not an optional one: there is no way to
/// call this with a key alone, which is what makes "entering a key is not
/// enough" (FR-003) structural rather than a UI rule.
///
/// An empty/malformed key is refused with [ValidationFailure] here, before
/// the repository — and therefore secure storage — is touched at all; an
/// unrecognized `providerId` is refused by the repository, also before
/// either store is written. No network call is ever made: a genuinely
/// invalid key surfaces on the first question instead
/// (contracts/ai_assistant_repository.md).
@injectable
class EnableAIAssistant {
  const EnableAIAssistant(this._repository);

  final AIAssistantRepository _repository;

  Future<Either<Failure, AIAssistantSettings>> call({
    required String providerId,
    required String apiKey,
    required DateTime consentAcceptedAt,
  }) async {
    if (AIApiKeyRules.isMalformed(apiKey)) {
      return const Left(ValidationFailure('The API key is empty or malformed'));
    }
    return _repository.enable(
      providerId: providerId,
      apiKey: apiKey,
      consentAcceptedAt: consentAcceptedAt,
    );
  }
}
