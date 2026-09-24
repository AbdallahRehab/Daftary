import 'package:injectable/injectable.dart';

import '../../domain/services/ai_provider_catalog.dart';
import '../services/ai_provider_registry.dart';

/// [AIProviderCatalog] backed by [AIProviderRegistry], the single source of
/// truth for which provider ids exist and how a custom one is encoded
/// (`custom:<baseUrl>|<model>`).
@LazySingleton(as: AIProviderCatalog)
class AIProviderCatalogImpl implements AIProviderCatalog {
  const AIProviderCatalogImpl();

  @override
  List<AIProviderOption> get presets => [
    for (final preset in AIProviderRegistry.presets)
      AIProviderOption(id: preset.id, displayName: preset.displayName),
  ];

  @override
  AIProviderOption? presetById(String providerId) {
    for (final option in presets) {
      if (option.id == providerId) return option;
    }
    return null;
  }

  @override
  bool isRecognized(String providerId) =>
      AIProviderRegistry.resolve(providerId) != null;

  @override
  bool isCustom(String providerId) => AIProviderRegistry.isCustom(providerId);

  @override
  String? encodeCustom({required String baseUrl, required String model}) =>
      AIProviderRegistry.encodeCustom(baseUrl: baseUrl, model: model);

  @override
  AICustomProviderSpec? decodeCustom(String providerId) {
    if (!isCustom(providerId) || !isRecognized(providerId)) return null;
    final spec = providerId.substring(AIProviderRegistry.customPrefix.length);
    final sep = spec.lastIndexOf('|');
    return AICustomProviderSpec(
      baseUrl: spec.substring(0, sep).trim(),
      model: spec.substring(sep + 1).trim(),
    );
  }
}
