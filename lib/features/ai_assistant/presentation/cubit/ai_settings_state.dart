import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_assistant_settings.dart';
import '../../domain/services/ai_provider_catalog.dart';

enum AISettingsStatus {
  loading,

  /// The settings could not be read at all.
  loadFailure,

  /// Settings loaded; the form (or the enabled summary) is interactive.
  ready,

  /// A provider and a well-formed key were entered and the user asked to
  /// turn the assistant on — the consent disclosure must now be shown and
  /// accepted. The assistant is still disabled in this state (FR-003).
  awaitingConsent,

  /// An enable / update / disable call is in flight. Every action is
  /// refused while in this state (Duplicate Action Protection).
  submitting,
}

/// Why the provider part of the form was refused. A reason, not a message,
/// so the page localizes it (FR-021).
enum AIProviderInputError { required, invalidBaseUrl, modelRequired }

/// Why the API key field was refused.
enum AIApiKeyInputError { required, malformed }

/// A one-shot outcome the page reports (snackbar) after a successful
/// action.
enum AISettingsOutcome { enabled, credentialsUpdated, disabled }

/// Immutable state for `AISettingsCubit` (constitution Principle IV).
///
/// Deliberately holds **no API key**: the key the user types lives only in
/// the page's text field and a private cubit field until it is handed to
/// the use case, then is dropped. State only knows [hasApiKeyInput], so a
/// logged or printed state (Equatable's debug `toString`) can never leak
/// it (FR-004).
class AISettingsState extends Equatable {
  const AISettingsState({
    this.status = AISettingsStatus.loading,
    this.presets = const [],
    this.settings,
    this.selectedPresetId,
    this.isCustomSelected = false,
    this.customBaseUrl = '',
    this.customModel = '',
    this.hasApiKeyInput = false,
    this.isEditingCredentials = false,
    this.providerError,
    this.apiKeyError,
    this.failure,
    this.outcome,
  });

  final AISettingsStatus status;

  /// The one-tap provider presets offered next to the custom option.
  final List<AIProviderOption> presets;

  /// `null` only before the first successful load.
  final AIAssistantSettings? settings;

  /// The chosen preset, when [isCustomSelected] is `false`.
  final String? selectedPresetId;
  final bool isCustomSelected;
  final String customBaseUrl;
  final String customModel;

  /// Whether the key field currently holds anything — never the key.
  final bool hasApiKeyInput;

  /// The enabled assistant's "change provider or key" form is open.
  final bool isEditingCredentials;
  final AIProviderInputError? providerError;
  final AIApiKeyInputError? apiKeyError;

  /// The last action's failure, cleared by the next action.
  final Failure? failure;

  /// Set only on the emission that completes an action; cleared by the
  /// next emission of any kind.
  final AISettingsOutcome? outcome;

  bool get isEnabled => settings?.isEnabled ?? false;
  bool get isSubmitting => status == AISettingsStatus.submitting;
  bool get isAwaitingConsent => status == AISettingsStatus.awaitingConsent;

  /// The credential form is shown: always while disabled, and on request
  /// while enabled.
  bool get showsCredentialForm => !isEnabled || isEditingCredentials;

  AISettingsState copyWith({
    AISettingsStatus? status,
    AIAssistantSettings? settings,
    String? selectedPresetId,
    bool clearSelectedPreset = false,
    bool? isCustomSelected,
    String? customBaseUrl,
    String? customModel,
    bool? hasApiKeyInput,
    bool? isEditingCredentials,
    AIProviderInputError? providerError,
    bool clearProviderError = false,
    AIApiKeyInputError? apiKeyError,
    bool clearApiKeyError = false,
    Failure? failure,
    bool clearFailure = false,
    AISettingsOutcome? outcome,
  }) {
    return AISettingsState(
      status: status ?? this.status,
      presets: presets,
      settings: settings ?? this.settings,
      selectedPresetId: clearSelectedPreset
          ? null
          : (selectedPresetId ?? this.selectedPresetId),
      isCustomSelected: isCustomSelected ?? this.isCustomSelected,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      customModel: customModel ?? this.customModel,
      hasApiKeyInput: hasApiKeyInput ?? this.hasApiKeyInput,
      isEditingCredentials: isEditingCredentials ?? this.isEditingCredentials,
      providerError: clearProviderError
          ? null
          : (providerError ?? this.providerError),
      apiKeyError: clearApiKeyError ? null : (apiKeyError ?? this.apiKeyError),
      failure: clearFailure ? null : (failure ?? this.failure),
      // Never carried over: an outcome describes one emission only.
      outcome: outcome,
    );
  }

  @override
  List<Object?> get props => [
    status,
    presets,
    settings,
    selectedPresetId,
    isCustomSelected,
    customBaseUrl,
    customModel,
    hasApiKeyInput,
    isEditingCredentials,
    providerError,
    apiKeyError,
    failure,
    outcome,
  ];
}
