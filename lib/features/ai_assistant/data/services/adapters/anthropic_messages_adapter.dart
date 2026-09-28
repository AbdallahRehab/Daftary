import '../../../domain/services/ai_service.dart';
import '../../models/tool_result_dto.dart';
import 'ai_provider_adapter.dart';

/// Anthropic Messages API with tool use (research.md Decision 1).
class AnthropicMessagesAdapter extends AIProviderAdapter {
  const AnthropicMessagesAdapter();

  static const String apiVersion = '2023-06-01';
  static const int maxTokens = 2048;

  @override
  Map<String, String> headers(String apiKey) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-api-key': apiKey,
    'anthropic-version': apiVersion,
  };

  @override
  Map<String, Object?> buildBody({
    required String model,
    required String systemPrompt,
    required List<AITurnMessage> messages,
    required List<AIToolDeclaration> tools,
  }) => {
    'model': model,
    'max_tokens': maxTokens,
    if (systemPrompt.isNotEmpty) 'system': systemPrompt,
    'messages': _messages(messages),
    if (tools.isNotEmpty)
      'tools': [
        for (final t in tools)
          {
            'name': t.name,
            'description': t.description,
            'input_schema': t.parametersSchema,
          },
      ],
  };

  /// Converts to content blocks, merging consecutive same-role messages
  /// (so all `tool_result`s of one exchange share one `user` message) and
  /// dropping any leading assistant message (the conversation must open
  /// with the user; a context window can start mid-exchange).
  List<Map<String, Object?>> _messages(List<AITurnMessage> messages) {
    final out = <Map<String, Object?>>[];
    for (final m in messages) {
      final role = m.role == AITurnRole.assistant ? 'assistant' : 'user';
      final blocks = _blocks(m);
      if (blocks.isEmpty) continue;
      if (out.isEmpty && role == 'assistant') continue;
      if (out.isNotEmpty && out.last['role'] == role) {
        (out.last['content']! as List<Map<String, Object?>>).addAll(blocks);
      } else {
        out.add({'role': role, 'content': blocks});
      }
    }
    return out;
  }

  List<Map<String, Object?>> _blocks(AITurnMessage m) {
    switch (m.role) {
      case AITurnRole.user:
        return [
          if (m.content.isNotEmpty) {'type': 'text', 'text': m.content},
        ];
      case AITurnRole.assistant:
        return [
          if (m.content.isNotEmpty) {'type': 'text', 'text': m.content},
          for (final c in m.toolCalls)
            {
              'type': 'tool_use',
              'id': c.id,
              'name': c.toolName,
              'input': c.arguments,
            },
        ];
      case AITurnRole.tool:
        return [
          {
            'type': 'tool_result',
            'tool_use_id': m.toolCallId,
            'content': ToolResultDto.fromEntity(m.toolResult!).toJsonString(),
          },
        ];
    }
  }

  @override
  AITurnResult parseResponse(Object? body, Set<String> allowedToolNames) {
    final root = AdapterJson.asMap(body, 'response');
    final content = AdapterJson.asList(root['content'], 'content');

    final calls = <AIToolCallRequest>[];
    final text = StringBuffer();
    for (final raw in content) {
      final block = AdapterJson.asMap(raw, 'content block');
      switch (block['type']) {
        case 'text':
          final t = block['text'];
          if (t is! String) {
            throw const AIResponseFormatException('text block without text');
          }
          text.write(t);
        case 'tool_use':
          final id = AdapterJson.asNonEmptyString(block['id'], 'tool_use id');
          final name = AdapterJson.asNonEmptyString(block['name'], 'name');
          AdapterJson.checkToolAllowed(name, allowedToolNames);
          final input = block['input'] == null
              ? const <String, Object?>{}
              : AdapterJson.asMap(block['input'], 'tool input');
          calls.add(
            AIToolCallRequest(id: id, toolName: name, arguments: input),
          );
        default:
          // Other block kinds (e.g. thinking) carry no answer; skip them.
          break;
      }
    }

    if (calls.isNotEmpty) return AITurnResult.toolCalls(calls);
    final answer = text.toString().trim();
    if (answer.isEmpty) {
      throw const AIResponseFormatException('no answer text and no tool call');
    }
    return AITurnResult.answer(answer);
  }

  /// `{"type": "error", "error": {"type": ..., "message": ...}}`.
  @override
  AIErrorEnvelopeKind? classifyErrorEnvelope(Object? body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (body['type'] != 'error' && error == null) return null;
    if (error is Map) {
      return AdapterJson.classifyByText([error['type'], error['message']]);
    }
    return AIErrorEnvelopeKind.providerError;
  }
}
