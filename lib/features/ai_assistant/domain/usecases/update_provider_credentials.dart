import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_assistant_settings.dart';
import '../entities/ai_api_key_rules.dart';
import '../repositories/ai_assistant_repository.dart';

/// Replaces the provider and/or key of an enabled assistant (FR-005)
/// without touching `isEnabled` or `consentAcceptedAt`. The previous key is
/// discarded by the repository once replaced.
///
/// An empty/malformed key is refused with [ValidationFailure] before the
/// repository is touched; an unrecognized `providerId` is refused by the
/// repository before either store is written.
@injectable
class UpdateProviderCredentials {
  const UpdateProviderCredentials(this._repository);

  final AIAssistantRepository _repository;

  Future<Either<Failure, AIAssistantSettings>> call({
    required String providerId,
    required String apiKey,
  }) async {
    if (AIApiKeyRules.isMalformed(apiKey)) {
      return const Left(ValidationFailure('The API key is empty or malformed'));
    }
    return _repository.updateCredentials(
      providerId: providerId,
      apiKey: apiKey,
    );
  }
}
