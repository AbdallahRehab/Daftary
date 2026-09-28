import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_assistant_settings.dart';
import '../repositories/ai_assistant_repository.dart';

/// The current assistant settings — the default disabled singleton on a
/// fresh install (FR-001). Never exposes the API key: settings only know
/// *whether* one is stored.
@injectable
class GetAIAssistantSettings {
  const GetAIAssistantSettings(this._repository);

  final AIAssistantRepository _repository;

  Future<Either<Failure, AIAssistantSettings>> call() =>
      _repository.getSettings();
}
