import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/ai_api_key_rules.dart';
import '../../domain/services/ai_provider_catalog.dart';
import '../../domain/usecases/disable_ai_assistant.dart';
import '../../domain/usecases/enable_ai_assistant.dart';
import '../../domain/usecases/get_ai_assistant_settings.dart';
import '../../domain/usecases/update_provider_credentials.dart';
import 'ai_settings_state.dart';

/// Drives the AI assistant setup screen (User Story 1): provider selection
/// → key entry → consent acceptance → enable; plus update-credentials and
/// disable for an enabled assistant.
///
/// Consent gating (FR-003) is a state machine, not a UI rule:
/// [requestEnable] never enables anything — it only validates and moves to
/// [AISettingsStatus.awaitingConsent]. The only path that calls
/// [EnableAIAssistant] is [acceptConsent], and only from that state.
///
/// Duplicate Action Protection: every action checks [AISettingsState.isSubmitting]
/// synchronously, before its first `await`, and the submitting state is
/// emitted before the use case is called — so the Save button is disabled
/// on the very tap that submits.
///
/// Key hygiene (FR-004): the typed key is held in [_apiKeyDraft], a private
/// field that is never emitted, logged or included in [toString], and is
/// dropped as soon as it has been handed to a use case.
@injectable
class AISettingsCubit extends Cubit<AISettingsState> {
  AISettingsCubit(
    this._getSettings,
    this._enable,
    this._disable,
    this._updateCredentials,
    this._catalog,
  ) : super(AISettingsState(presets: _catalog.presets));

  final GetAIAssistantSettings _getSettings;
  final EnableAIAssistant _enable;
  final DisableAIAssistant _disable;
  final UpdateProviderCredentials _updateCredentials;
  final AIProviderCatalog _catalog;

  String _apiKeyDraft = '';

  Future<void> load() async {
    emit(state.copyWith(status: AISettingsStatus.loading, clearFailure: true));
    final result = await _getSettings();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AISettingsStatus.loadFailure, failure: failure),
      ),
      (settings) => emit(
        state.copyWith(status: AISettingsStatus.ready, settings: settings),
      ),
    );
  }

  // ------------------------------------------------------------ form input

  void presetSelected(String presetId) {
    if (state.isSubmitting || _catalog.presetById(presetId) == null) return;
    emit(
      state.copyWith(
        selectedPresetId: presetId,
        isCustomSelected: false,
        clearProviderError: true,
      ),
    );
  }

  void customProviderSelected() {
    if (state.isSubmitting) return;
    emit(
      state.copyWith(
        clearSelectedPreset: true,
        isCustomSelected: true,
        clearProviderError: true,
      ),
    );
  }

  void customBaseUrlChanged(String value) =>
      emit(state.copyWith(customBaseUrl: value, clearProviderError: true));

  void customModelChanged(String value) =>
      emit(state.copyWith(customModel: value, clearProviderError: true));

  void apiKeyChanged(String value) {
    _apiKeyDraft = value;
    emit(
      state.copyWith(
        hasApiKeyInput: value.trim().isNotEmpty,
        clearApiKeyError: true,
      ),
    );
  }

  // ---------------------------------------------------------------- enable

  /// Step 1 of enabling: validates the provider and key and, if both are
  /// fine, asks for consent. The assistant stays disabled (FR-003).
  void requestEnable() {
    if (state.isSubmitting || state.isAwaitingConsent || state.isEnabled) {
      return;
    }
    if (!_validate()) return;
    emit(
      state.copyWith(
        status: AISettingsStatus.awaitingConsent,
        clearFailure: true,
      ),
    );
  }

  /// The user closed the disclosure without accepting: nothing is stored,
  /// the assistant stays off, and the form keeps what was typed.
  void declineConsent() {
    if (!state.isAwaitingConsent) return;
    emit(state.copyWith(status: AISettingsStatus.ready));
  }

  /// Step 2: the user accepted the disclosure. Stores the key, records the
  /// consent time and enables the assistant — atomically, in one use case.
  Future<void> acceptConsent() async {
    if (!state.isAwaitingConsent) return;
    final providerId = draftProviderId;
    if (providerId == null) {
      emit(state.copyWith(status: AISettingsStatus.ready));
      return;
    }
    emit(
      state.copyWith(status: AISettingsStatus.submitting, clearFailure: true),
    );
    final apiKey = _apiKeyDraft;
    final result = await _enable(
      providerId: providerId,
      apiKey: apiKey,
      consentAcceptedAt: DateTime.now(),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AISettingsStatus.ready, failure: failure),
      ),
      (settings) {
        _clearForm();
        emit(
          AISettingsState(presets: state.presets).copyWith(
            status: AISettingsStatus.ready,
            settings: settings,
            outcome: AISettingsOutcome.enabled,
          ),
        );
      },
    );
  }

  // ----------------------------------------------------- update credentials

  /// Opens the "change provider or key" form of an enabled assistant,
  /// preselecting the current provider. The key is never prefilled — the
  /// stored one is never read back for display (FR-004).
  void startEditingCredentials() {
    if (!state.isEnabled || state.isSubmitting) return;
    _apiKeyDraft = '';
    final providerId = state.settings?.providerId;
    final custom = providerId == null
        ? null
        : _catalog.decodeCustom(providerId);
    emit(
      AISettingsState(
        status: AISettingsStatus.ready,
        presets: state.presets,
        settings: state.settings,
        isEditingCredentials: true,
        selectedPresetId: custom == null ? providerId : null,
        isCustomSelected: custom != null,
        customBaseUrl: custom?.baseUrl ?? '',
        customModel: custom?.model ?? '',
      ),
    );
  }

  void cancelEditingCredentials() {
    if (state.isSubmitting) return;
    _clearForm();
    emit(
      AISettingsState(
        status: AISettingsStatus.ready,
        presets: state.presets,
        settings: state.settings,
      ),
    );
  }

  Future<void> submitCredentialsUpdate() async {
    if (state.isSubmitting || !state.isEnabled || !state.isEditingCredentials) {
      return;
    }
    if (!_validate()) return;
    final providerId = draftProviderId!;
    emit(
      state.copyWith(status: AISettingsStatus.submitting, clearFailure: true),
    );
    final apiKey = _apiKeyDraft;
    final result = await _updateCredentials(
      providerId: providerId,
      apiKey: apiKey,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: AISettingsStatus.ready, failure: failure),
      ),
      (settings) {
        _clearForm();
        emit(
          AISettingsState(presets: state.presets).copyWith(
            status: AISettingsStatus.ready,
            settings: settings,
            outcome: AISettingsOutcome.credentialsUpdated,
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------- disable

  /// Turns the assistant off (the page confirms first). On success the
  /// form is reset to empty: the key was deleted and consent cleared, so
  /// turning it back on needs the whole flow again (FR-016, T063).
  Future<void> disable() async {
    if (state.isSubmitting || !state.isEnabled) return;
    emit(
      state.copyWith(status: AISettingsStatus.submitting, clearFailure: true),
    );
    final result = await _disable();
    if (isClosed) return;
    if (result.isLeft()) {
      emit(
        state.copyWith(
          status: AISettingsStatus.ready,
          failure: result.getLeft().toNullable(),
        ),
      );
      return;
    }
    final reloaded = await _getSettings();
    if (isClosed) return;
    _clearForm();
    reloaded.fold(
      (failure) => emit(
        AISettingsState(
          status: AISettingsStatus.loadFailure,
          presets: state.presets,
          failure: failure,
        ),
      ),
      (settings) => emit(
        AISettingsState(
          status: AISettingsStatus.ready,
          presets: state.presets,
          settings: settings,
          outcome: AISettingsOutcome.disabled,
        ),
      ),
    );
  }

  // --------------------------------------------------------------- helpers

  /// The provider id the form currently describes, or `null` when it does
  /// not describe a valid one yet.
  String? get draftProviderId {
    if (state.isCustomSelected) {
      return _catalog.encodeCustom(
        baseUrl: state.customBaseUrl,
        model: state.customModel,
      );
    }
    return state.selectedPresetId;
  }

  /// How the page names [providerId]: a preset's brand name, or — for a
  /// custom provider — its endpoint host (the page wraps that in localized
  /// "your custom provider (…)" copy).
  ({bool isCustom, String name}) describeProvider(String providerId) {
    final preset = _catalog.presetById(providerId);
    if (preset != null) return (isCustom: false, name: preset.displayName);
    return (
      isCustom: true,
      name: _catalog.decodeCustom(providerId)?.host ?? '',
    );
  }

  bool _validate() {
    AIProviderInputError? providerError;
    if (state.isCustomSelected) {
      // Checked with a placeholder model first, so a bad URL is reported
      // as such even while the model field is still empty.
      final urlAcceptable =
          _catalog.encodeCustom(baseUrl: state.customBaseUrl, model: 'm') !=
          null;
      if (!urlAcceptable) {
        providerError = AIProviderInputError.invalidBaseUrl;
      } else if (draftProviderId == null) {
        providerError = AIProviderInputError.modelRequired;
      }
    } else if (state.selectedPresetId == null) {
      providerError = AIProviderInputError.required;
    }

    AIApiKeyInputError? keyError;
    if (_apiKeyDraft.trim().isEmpty) {
      keyError = AIApiKeyInputError.required;
    } else if (AIApiKeyRules.isMalformed(_apiKeyDraft)) {
      keyError = AIApiKeyInputError.malformed;
    }

    if (providerError == null && keyError == null) return true;
    emit(
      state.copyWith(
        providerError: providerError,
        clearProviderError: providerError == null,
        apiKeyError: keyError,
        clearApiKeyError: keyError == null,
      ),
    );
    return false;
  }

  void _clearForm() => _apiKeyDraft = '';

  @override
  String toString() => 'AISettingsCubit(${state.status})';
}
