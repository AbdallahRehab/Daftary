import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_assistant_failures.dart';
import '../../domain/services/ai_service.dart';
import 'adapters/ai_provider_adapter.dart';
import 'adapters/anthropic_messages_adapter.dart';
import 'adapters/openai_chat_adapter.dart';
import 'ai_provider_registry.dart';

/// `http`-based [AIService] (research.md Decisions 1, 2, 6).
///
/// Resolves `providerId` through [AIProviderRegistry], lets the matching
/// [AIProviderAdapter] build the request / read the response, and maps
/// every outcome to exactly one of the five [AIAssistantFailure]s:
///
/// | outcome | failure |
/// |---|---|
/// | unknown/invalid `providerId`, empty key, 401, 403, invalid-key envelope | [InvalidApiKeyFailure] |
/// | 429, rate-limit envelope | [RateLimitFailure] |
/// | `SocketException`/`ClientException`/timeout/any send error | [AINetworkFailure] |
/// | 5xx, other non-2xx, provider-error envelope (even with 200) | [AIProviderFailure] |
/// | 2xx body not JSON / unexpected shape / tool outside `availableTools` | [UnrecognizedAIResponseFailure] |
///
/// An unusable provider configuration maps to [InvalidApiKeyFailure]
/// because its only fix is the same one: re-enter the provider/key in
/// settings.
///
/// Failure messages are fixed, English, developer-facing strings: they
/// never contain the API key, the request, or the provider's raw error
/// text. Nothing here is logged. One request per call — no silent retry.
@LazySingleton(as: AIService)
class AIServiceImpl implements AIService {
  AIServiceImpl(this._client) : _timeout = defaultTimeout;

  @visibleForTesting
  AIServiceImpl.withTimeout(this._client, this._timeout);

  /// Upper bound for one provider round-trip.
  static const Duration defaultTimeout = Duration(seconds: 60);

  final http.Client _client;
  final Duration _timeout;

  static const _openAi = OpenAIChatAdapter();
  static const _anthropic = AnthropicMessagesAdapter();

  static AIProviderAdapter _adapterFor(AIProviderProtocol protocol) =>
      switch (protocol) {
        AIProviderProtocol.openAiChatCompletions => _openAi,
        AIProviderProtocol.anthropicMessages => _anthropic,
      };

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
    final config = AIProviderRegistry.resolve(providerId);
    if (config == null) {
      return const Left(
        InvalidApiKeyFailure('AI provider configuration is not usable'),
      );
    }
    if (apiKey.trim().isEmpty) {
      return const Left(InvalidApiKeyFailure('No API key configured'));
    }
    final adapter = _adapterFor(config.protocol);

    final String requestBody;
    try {
      requestBody = jsonEncode(
        adapter.buildBody(
          model: config.model,
          systemPrompt: systemPrompt,
          messages: [...context, AITurnMessage.user(question), ...toolExchange],
          tools: availableTools,
        ),
      );
    } on Object {
      // A tool result/argument that is not JSON-encodable is a caller bug;
      // no request is sent.
      return const Left(
        UnrecognizedAIResponseFailure('Turn could not be encoded for sending'),
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            config.endpoint,
            headers: adapter.headers(apiKey.trim()),
            body: requestBody,
            encoding: utf8,
          )
          .timeout(_timeout);
    } on TimeoutException {
      return const Left(AINetworkFailure('AI provider request timed out'));
    } on SocketException {
      return const Left(AINetworkFailure('No connection to the AI provider'));
    } on http.ClientException {
      return const Left(AINetworkFailure('AI provider request failed to send'));
    } on Object {
      return const Left(AINetworkFailure('AI provider request failed to send'));
    }

    return _mapResponse(
      response,
      adapter,
      availableTools.map((t) => t.name).toSet(),
    );
  }

  Either<Failure, AITurnResult> _mapResponse(
    http.Response response,
    AIProviderAdapter adapter,
    Set<String> allowedTools,
  ) {
    final status = response.statusCode;
    if (status == 401 || status == 403) {
      return Left(
        InvalidApiKeyFailure('AI provider rejected the key ($status)'),
      );
    }
    if (status == 429) {
      return const Left(RateLimitFailure('AI provider rate limit (429)'));
    }
    if (status >= 500) {
      return Left(AIProviderFailure('AI provider server error ($status)'));
    }

    final Object? decoded = _tryDecode(response);

    if (status < 200 || status >= 300) {
      final kind = decoded == null ? null : _safeClassify(adapter, decoded);
      return Left(
        _envelopeFailure(kind ?? AIErrorEnvelopeKind.providerError, status),
      );
    }

    if (decoded == null) {
      return const Left(
        UnrecognizedAIResponseFailure('AI provider response is not JSON'),
      );
    }
    final kind = _safeClassify(adapter, decoded);
    if (kind != null) return Left(_envelopeFailure(kind, status));

    try {
      return Right(adapter.parseResponse(decoded, allowedTools));
    } on AIResponseFormatException catch (e) {
      return Left(
        UnrecognizedAIResponseFailure('Unrecognized AI response: ${e.reason}'),
      );
    } on Object {
      return const Left(
        UnrecognizedAIResponseFailure('Unrecognized AI response'),
      );
    }
  }

  static Object? _tryDecode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on Object {
      return null;
    }
  }

  static AIErrorEnvelopeKind? _safeClassify(
    AIProviderAdapter adapter,
    Object decoded,
  ) {
    try {
      return adapter.classifyErrorEnvelope(decoded);
    } on Object {
      return AIErrorEnvelopeKind.providerError;
    }
  }

  static AIAssistantFailure _envelopeFailure(
    AIErrorEnvelopeKind kind,
    int status,
  ) => switch (kind) {
    AIErrorEnvelopeKind.invalidKey => InvalidApiKeyFailure(
      'AI provider rejected the key ($status)',
    ),
    AIErrorEnvelopeKind.rateLimited => RateLimitFailure(
      'AI provider rate limit ($status)',
    ),
    AIErrorEnvelopeKind.providerError => AIProviderFailure(
      'AI provider returned an error ($status)',
    ),
  };
}
