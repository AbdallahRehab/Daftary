import 'package:equatable/equatable.dart';

/// One provider the setup screen can offer as a one-tap preset
/// (research.md Decision 7). Metadata only — never a key.
class AIProviderOption extends Equatable {
  const AIProviderOption({required this.id, required this.displayName});

  /// The value persisted as `AIAssistantSettings.providerId`.
  final String id;

  /// A brand name, shown untranslated in both locales.
  final String displayName;

  @override
  List<Object?> get props => [id, displayName];
}

/// A decoded custom (OpenAI-compatible) provider id.
class AICustomProviderSpec extends Equatable {
  const AICustomProviderSpec({required this.baseUrl, required this.model});

  final String baseUrl;
  final String model;

  /// What the UI shows for this provider: the endpoint's host.
  String get host => Uri.tryParse(baseUrl)?.host ?? baseUrl;

  @override
  List<Object?> get props => [baseUrl, model];
}

/// Domain view of the provider catalog, so Domain use cases and
/// Presentation can list presets, validate a `providerId` and build a
/// custom one without depending on the Data layer's concrete registry
/// (`AIProviderRegistry`, which also knows endpoints/models/protocols).
abstract class AIProviderCatalog {
  /// The curated presets, in display order.
  List<AIProviderOption> get presets;

  /// The preset with [providerId], or `null` (custom/unknown id).
  AIProviderOption? presetById(String providerId);

  /// Whether [providerId] is a preset or a well-formed custom id.
  bool isRecognized(String providerId);

  bool isCustom(String providerId);

  /// Encodes a custom provider; `null` when [baseUrl]/[model] are not
  /// acceptable (e.g. a non-https URL, a blank model).
  String? encodeCustom({required String baseUrl, required String model});

  /// Decodes a custom provider id; `null` for a preset or malformed id.
  AICustomProviderSpec? decodeCustom(String providerId);
}
