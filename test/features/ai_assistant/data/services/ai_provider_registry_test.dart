import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every preset resolves to https with its default model', () {
    for (final preset in AIProviderRegistry.presets) {
      final config = AIProviderRegistry.resolve(preset.id)!;
      expect(config.endpoint.scheme, 'https');
      expect(config.model, preset.defaultModel);
      expect(config.protocol, preset.protocol);
    }
    expect(
      AIProviderRegistry.presets.map((p) => p.id).toSet(),
      hasLength(AIProviderRegistry.presets.length),
    );
  });

  test('preset endpoints', () {
    expect(
      AIProviderRegistry.resolve('openai')!.endpoint.toString(),
      'https://api.openai.com/v1/chat/completions',
    );
    expect(
      AIProviderRegistry.resolve('anthropic')!.endpoint.toString(),
      'https://api.anthropic.com/v1/messages',
    );
    expect(
      AIProviderRegistry.resolve('anthropic')!.protocol,
      AIProviderProtocol.anthropicMessages,
    );
  });

  test('unknown id does not resolve', () {
    expect(AIProviderRegistry.resolve('nope'), isNull);
    expect(AIProviderRegistry.resolve(''), isNull);
  });

  group('custom encoding', () {
    test('round-trips through encodeCustom/resolve', () {
      final id = AIProviderRegistry.encodeCustom(
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'llama-3.3',
      )!;
      expect(id, 'custom:https://api.groq.com/openai/v1/|llama-3.3');
      expect(AIProviderRegistry.isCustom(id), isTrue);
      final config = AIProviderRegistry.resolve(id)!;
      expect(
        config.endpoint.toString(),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(config.model, 'llama-3.3');
      expect(config.protocol, AIProviderProtocol.openAiChatCompletions);
    });

    test('a full chat/completions URL is used as-is', () {
      final config = AIProviderRegistry.resolve(
        'custom:https://x.example/v1/chat/completions|m',
      )!;
      expect(
        config.endpoint.toString(),
        'https://x.example/v1/chat/completions',
      );
    });

    test('allows plain http only to loopback hosts', () {
      expect(
        AIProviderRegistry.resolve('custom:http://localhost:11434/v1|m'),
        isNotNull,
      );
      expect(
        AIProviderRegistry.resolve('custom:http://10.0.2.2:1234/v1|m'),
        isNotNull,
      );
      expect(
        AIProviderRegistry.resolve('custom:http://evil.example/v1|m'),
        isNull,
      );
    });

    test('rejects malformed custom ids', () {
      for (final id in [
        'custom:',
        'custom:https://x.example/v1',
        'custom:https://x.example/v1|',
        'custom:|model',
        'custom:not a url|m',
        'custom:ftp://x.example|m',
        'custom:https://x.example/v1?key=1|m',
        'custom:https://user:pw@x.example/v1|m',
      ]) {
        expect(AIProviderRegistry.resolve(id), isNull, reason: id);
      }
      expect(
        AIProviderRegistry.encodeCustom(
          baseUrl: 'https://x.example',
          model: 'a|b',
        ),
        isNull,
      );
    });
  });
}
