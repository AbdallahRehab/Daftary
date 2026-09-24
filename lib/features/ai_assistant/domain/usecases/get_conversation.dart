import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/ai_message.dart';
import '../repositories/ai_assistant_repository.dart';

/// One page of the single continuous conversation (FR-011), oldest →
/// newest within the page.
///
/// Paging runs backwards from the newest message, as a chat screen loads
/// it: `offset: 0` is the latest [limit] messages; to load older history,
/// call again with `offset` = the number of messages already loaded. A
/// page shorter than [limit] means the start of the conversation was
/// reached.
@injectable
class GetConversation {
  const GetConversation(this._repository);

  final AIAssistantRepository _repository;

  static const int defaultPageSize = 50;

  Future<Either<Failure, List<AIMessage>>> call({
    int limit = defaultPageSize,
    int offset = 0,
  }) => _repository.getMessages(limit: limit, offset: offset);
}
