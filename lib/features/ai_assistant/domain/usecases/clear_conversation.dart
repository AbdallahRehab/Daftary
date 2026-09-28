import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ai_assistant_repository.dart';

/// Permanently and irreversibly deletes every message in the conversation
/// (FR-012). The confirmation step lives in the UI (`AppConfirmDialog`);
/// this use case does not ask again. Assistant settings — enabled state,
/// provider, consent, stored key — are untouched.
@injectable
class ClearConversation {
  const ClearConversation(this._repository);

  final AIAssistantRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.clearConversation();
}
