import 'dart:convert';

import '../../../domain/services/ai_service.dart';
import '../../models/tool_result_dto.dart';
import 'ai_provider_adapter.dart';

/// OpenAI-style chat completions with tool calling — used for the OpenAI,
/// Gemini (OpenAI-compatible endpoint) and OpenRouter presets and for
/// every custom provider (research.md Decision 1/7).
class OpenAIChatAdapter extends AIProviderAdapter {
  const OpenAIChatAdapter();

  @override
  Map<String, String> headers(String apiKey) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  @override
  Map<String, Object?> buildBody({
    required String model,
    required String systemPrompt,
    required List<AITurnMessage> messages,
    required List<AIToolDeclaration> tools,
  }) => {
    'model': model,
    'messages': [
      if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
      for (final m in messages) _message(m),
    ],
    if (tools.isNotEmpty)
      'tools': [
        for (final t in tools)
          {
            'type': 'function',
            'function': {
              'name': t.name,
              'description': t.description,
              'parameters': t.parametersSchema,
            },
          },
      ],
  };

  Map<String, Object?> _message(AITurnMessage m) {
    switch (m.role) {
      case AITurnRole.user:
        return {'role': 'user', 'content': m.content};
      case AITurnRole.assistant:
        if (m.toolCalls.isEmpty) {
          return {'role': 'assistant', 'content': m.content};
        }
        return {
          'role': 'assistant',
          'content': null,
          'tool_calls': [
            for (final c in m.toolCalls)
              {
                'id': c.id,
                'type': 'function',
                'function': {
                  'name': c.toolName,
                  'arguments': jsonEncode(c.arguments),
                },
              },
          ],
        };
      case AITurnRole.tool:
        return {
          'role': 'tool',
          'tool_call_id': m.toolCallId,
          'content': ToolResultDto.fromEntity(m.toolResult!).toJsonString(),
        };
    }
  }

  @override
  AITurnResult parseResponse(Object? body, Set<String> allowedToolNames) {
    final root = AdapterJson.asMap(body, 'response');
    final choices = AdapterJson.asList(root['choices'], 'choices');
    if (choices.isEmpty) {
      throw const AIResponseFormatException('choices is empty');
    }
    final choice = AdapterJson.asMap(choices.first, 'choice');
    final message = AdapterJson.asMap(choice['message'], 'message');

    final rawCalls = message['tool_calls'];
    if (rawCalls != null) {
      final calls = AdapterJson.asList(rawCalls, 'tool_calls');
      if (calls.isNotEmpty) {
        return AITurnResult.toolCalls([
          for (final raw in calls) _toolCall(raw, allowedToolNames),
        ]);
      }
    }

    final text = _text(message['content']).trim();
    if (text.isEmpty) {
      throw const AIResponseFormatException('no answer text and no tool call');
    }
    return AITurnResult.answer(text);
  }

  AIToolCallRequest _toolCall(Object? raw, Set<String> allowed) {
    final call = AdapterJson.asMap(raw, 'tool call');
    final id = AdapterJson.asNonEmptyString(call['id'], 'tool call id');
    final fn = AdapterJson.asMap(call['function'], 'tool call function');
    final name = AdapterJson.asNonEmptyString(fn['name'], 'tool name');
    AdapterJson.checkToolAllowed(name, allowed);

    final rawArgs = fn['arguments'];
    final Map<String, Object?> args;
    if (rawArgs == null || (rawArgs is String && rawArgs.trim().isEmpty)) {
      args = const {};
    } else if (rawArgs is String) {
      final Object? decoded;
      try {
        decoded = jsonDecode(rawArgs);
      } on FormatException {
        throw const AIResponseFormatException('tool arguments are not JSON');
      }
      args = AdapterJson.asMap(decoded, 'tool arguments');
    } else {
      args = AdapterJson.asMap(rawArgs, 'tool arguments');
    }
    return AIToolCallRequest(id: id, toolName: name, arguments: args);
  }

  /// `content` is a string, or (on some compatible servers) a list of
  /// `{type: text, text}` parts.
  String _text(Object? content) {
    if (content == null) return '';
    if (content is String) return content;
    if (content is List) {
      return [
        for (final part in content)
          if (part is Map && part['type'] == 'text' && part['text'] is String)
            part['text'] as String,
      ].join();
    }
    throw const AIResponseFormatException('content has an unexpected type');
  }

  /// `{"error": {...}}` (OpenAI and most compatible servers) or
  /// `[{"error": {...}}]` (Gemini's compatible endpoint).
  @override
  AIErrorEnvelopeKind? classifyErrorEnvelope(Object? body) {
    var root = body;
    if (root is List && root.isNotEmpty) root = root.first;
    if (root is! Map || !root.containsKey('error')) return null;
    final error = root['error'];
    if (error is Map) {
      return AdapterJson.classifyByText([
        error['type'],
        error['code'],
        error['status'],
        error['message'],
      ]);
    }
    return AdapterJson.classifyByText([error]);
  }
}
