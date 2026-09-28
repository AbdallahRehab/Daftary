/// Which wire protocol an AI provider speaks (research.md Decision 1).
enum AIProviderProtocol {
  /// OpenAI-style `POST {baseUrl}/chat/completions` with `tools` /
  /// `tool_calls` — the de-facto common denominator, also used for every
  /// custom provider.
  openAiChatCompletions,

  /// Anthropic Messages API (`POST {baseUrl}/messages`, `tool_use` /
  /// `tool_result` content blocks).
  anthropicMessages,
}

/// One curated, one-tap provider preset (research.md Decision 7).
class AIProviderPreset {
  const AIProviderPreset({
    required this.id,
    required this.displayName,
    required this.protocol,
    required this.baseUrl,
    required this.defaultModel,
  });

  /// Stable id persisted as `AIAssistantSettings.providerId`.
  final String id;

  /// Brand name shown as-is in the settings UI (not localized).
  final String displayName;
  final AIProviderProtocol protocol;

  /// API base URL, without a trailing slash.
  final String baseUrl;
  final String defaultModel;
}

/// The curated preset list plus the custom-provider encoding.
///
/// A preset's `providerId` is its [AIProviderPreset.id]. A custom
/// (OpenAI-compatible) provider is encoded into the single `providerId`
/// string as:
///
/// `custom:<baseUrl>|<model>`
///
/// e.g. `custom:https://api.groq.com/openai/v1|llama-3.3-70b-versatile`.
/// `<baseUrl>` is the API root the request path `/chat/completions` is
/// appended to (a URL already ending in `/chat/completions` is used as-is);
/// it must be `https`, except `http` to a loopback/emulator host for a
/// local server. Use [encodeCustom] / [resolve] rather than building or
/// parsing the string by hand.
abstract final class AIProviderRegistry {
  static const String openAiId = 'openai';
  static const String anthropicId = 'anthropic';
  static const String geminiId = 'gemini';
  static const String openRouterId = 'openrouter';

  /// Prefix marking a custom provider id.
  static const String customPrefix = 'custom:';

  static const AIProviderPreset openAi = AIProviderPreset(
    id: openAiId,
    displayName: 'OpenAI',
    protocol: AIProviderProtocol.openAiChatCompletions,
    baseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-5-mini',
  );

  static const AIProviderPreset anthropic = AIProviderPreset(
    id: anthropicId,
    displayName: 'Anthropic (Claude)',
    protocol: AIProviderProtocol.anthropicMessages,
    baseUrl: 'https://api.anthropic.com/v1',
    defaultModel: 'claude-sonnet-5',
  );

  /// Google Gemini through its OpenAI-compatible endpoint (bearer-token
  /// auth, so the key never travels in a URL query string).
  static const AIProviderPreset gemini = AIProviderPreset(
    id: geminiId,
    displayName: 'Google Gemini',
    protocol: AIProviderProtocol.openAiChatCompletions,
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
    defaultModel: 'gemini-2.5-flash',
  );

  static const AIProviderPreset openRouter = AIProviderPreset(
    id: openRouterId,
    displayName: 'OpenRouter',
    protocol: AIProviderProtocol.openAiChatCompletions,
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: 'openai/gpt-5-mini',
  );

  /// Every preset, in display order — what the settings UI lists before
  /// its "custom provider" option.
  static const List<AIProviderPreset> presets = [
    openAi,
    anthropic,
    gemini,
    openRouter,
  ];

  static bool isCustom(String providerId) =>
      providerId.startsWith(customPrefix);

  /// Encodes a custom OpenAI-compatible provider into a `providerId`.
  /// Returns `null` when [baseUrl]/[model] would not [resolve].
  static String? encodeCustom({
    required String baseUrl,
    required String model,
  }) {
    if (model.contains('|')) return null;
    final id = '$customPrefix${baseUrl.trim()}|${model.trim()}';
    return resolve(id) == null ? null : id;
  }

  /// Resolves a `providerId` to the concrete endpoint/model/protocol, or
  /// `null` when it is neither a known preset nor a valid custom id.
  static AIProviderConfig? resolve(String providerId) {
    for (final preset in presets) {
      if (preset.id == providerId) {
        return AIProviderConfig(
          protocol: preset.protocol,
          endpoint: _endpoint(preset.protocol, preset.baseUrl),
          model: preset.defaultModel,
        );
      }
    }
    if (!isCustom(providerId)) return null;

    final spec = providerId.substring(customPrefix.length);
    final sep = spec.lastIndexOf('|');
    if (sep <= 0) return null;
    final baseUrl = spec.substring(0, sep).trim();
    final model = spec.substring(sep + 1).trim();
    if (model.isEmpty) return null;

    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    final secure = uri.scheme == 'https';
    final local = uri.scheme == 'http' && _loopbackHosts.contains(uri.host);
    if (!secure && !local) return null;
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      return null;
    }

    return AIProviderConfig(
      protocol: AIProviderProtocol.openAiChatCompletions,
      endpoint: _endpoint(AIProviderProtocol.openAiChatCompletions, baseUrl),
      model: model,
    );
  }

  static const Set<String> _loopbackHosts = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2', // Android emulator's alias for the host machine.
  };

  static Uri _endpoint(AIProviderProtocol protocol, String baseUrl) {
    final path = switch (protocol) {
      AIProviderProtocol.openAiChatCompletions => '/chat/completions',
      AIProviderProtocol.anthropicMessages => '/messages',
    };
    var base = baseUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse(base.endsWith(path) ? base : '$base$path');
  }
}

/// A resolved provider: where to POST, which model, which protocol.
class AIProviderConfig {
  const AIProviderConfig({
    required this.protocol,
    required this.endpoint,
    required this.model,
  });

  final AIProviderProtocol protocol;
  final Uri endpoint;
  final String model;
}
