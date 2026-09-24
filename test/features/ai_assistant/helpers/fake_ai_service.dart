import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/domain/entities/tool_result.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool.dart';
import 'package:fpdart/fpdart.dart';

/// One recorded [AIService.sendTurn] call.
class RecordedTurn {
  RecordedTurn({
    required this.providerId,
    required this.apiKey,
    required this.context,
    required this.question,
    required this.availableTools,
    required this.toolExchange,
    required this.systemPrompt,
  });

  final String providerId;
  final String apiKey;
  final List<AITurnMessage> context;
  final String question;
  final List<AIToolDeclaration> availableTools;
  final List<AITurnMessage> toolExchange;
  final String systemPrompt;
}

/// A scripted [AIService]: answers each call with the next queued response
/// and records every call's arguments.
class FakeAIService implements AIService {
  FakeAIService([Iterable<Either<Failure, AITurnResult>> responses = const []])
    : _responses = [...responses];

  final List<Either<Failure, AITurnResult>> _responses;
  final List<RecordedTurn> calls = [];

  void enqueue(Either<Failure, AITurnResult> response) =>
      _responses.add(response);

  @override
  Future<Either<Failure, AITurnResult>> sendTurn({
    required String providerId,
    required String apiKey,
    required List<AITurnMessage> context,
    required String question,
    required List<AIToolDeclaration> availableTools,
    List<AITurnMessage> toolExchange = const [],
    String systemPrompt = '',
  }) async {
    calls.add(
      RecordedTurn(
        providerId: providerId,
        apiKey: apiKey,
        context: List.of(context),
        question: question,
        availableTools: availableTools,
        toolExchange: List.of(toolExchange),
        systemPrompt: systemPrompt,
      ),
    );
    if (_responses.isEmpty) {
      throw StateError('FakeAIService: no response queued');
    }
    return _responses.removeAt(0);
  }
}

/// An [AITool] returning a fixed outcome and recording its arguments.
class FakeAITool extends AITool {
  FakeAITool(this.name, this.outcome);

  @override
  final String name;
  final Either<Failure, ToolResult> outcome;
  final List<Map<String, Object?>> calls = [];

  @override
  Future<Either<Failure, ToolResult>> call(
    Map<String, Object?> arguments,
  ) async {
    calls.add(arguments);
    return outcome;
  }
}
