import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/ai_assistant_repository.dart';

/// Turns the assistant off (User Story 5, FR-014/FR-016): `isEnabled` →
/// `false`, consent cleared, and the stored key deleted — one atomic
/// repository operation. Because the key itself is gone, re-enabling can
/// only happen through the full [EnableAIAssistant] flow (key + consent)
/// again; there is nothing left to silently resume with. The conversation
/// history is kept (data-model.md) — only an explicit clear removes it.
@injectable
class DisableAIAssistant {
  const DisableAIAssistant(this._repository);

  final AIAssistantRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.disable();
}
