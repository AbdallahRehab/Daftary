import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/ai_assistant_settings.dart';

/// Maps the `ai_settings` singleton row to [AIAssistantSettings]. Epoch
/// millis → `DateTime` happens only here.
///
/// The entity has no unnamed constructor, so the row picks a factory: it
/// becomes [AIAssistantSettings.enabled] only when it satisfies the
/// data-model.md invariant (enabled ⇒ stored credential ∧ consent ∧
/// provider). A row claiming enabled while violating it — only possible
/// through external tampering or a half-applied write — is read as
/// disabled, never as a usable assistant.
extension AISettingsMapper on db.AiSettingsRow {
  AIAssistantSettings toDomain() {
    final updated = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    final consent = consentAcceptedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(consentAcceptedAt!);
    final provider = providerId;
    if (isEnabled &&
        hasStoredCredential &&
        consent != null &&
        provider != null) {
      return AIAssistantSettings.enabled(
        providerId: provider,
        consentAcceptedAt: consent,
        updatedAt: updated,
      );
    }
    return AIAssistantSettings.disabled(
      updatedAt: updated,
      providerId: provider,
      hasStoredCredential: hasStoredCredential,
      consentAcceptedAt: consent,
    );
  }
}
