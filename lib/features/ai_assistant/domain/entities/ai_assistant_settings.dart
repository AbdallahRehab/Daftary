import 'package:equatable/equatable.dart';

/// The user's assistant configuration (014 data-model.md). Exactly one row
/// per installation, always under [singletonId].
///
/// Invariant, verbatim from data-model.md: "`isEnabled = true` MUST imply
/// `hasStoredCredential = true` AND `consentAcceptedAt != null`".
///
/// Enforced by construction: there is no unnamed constructor and no
/// `copyWith`. The only way to obtain an enabled instance is
/// [AIAssistantSettings.enabled], which requires a consent timestamp and
/// fixes `hasStoredCredential` to `true`.
///
/// Never holds the API key itself — that lives exclusively in secure
/// storage (research.md Decision 3).
class AIAssistantSettings extends Equatable {
  /// The assistant is off (FR-001) — the default state of a fresh install,
  /// and the state after `DisableAIAssistant`. Any provider/credential/
  /// consent metadata may be present or absent; none of it makes the
  /// assistant usable.
  const AIAssistantSettings.disabled({
    required this.updatedAt,
    this.providerId,
    this.hasStoredCredential = false,
    this.consentAcceptedAt,
  }) : id = singletonId,
       isEnabled = false;

  /// The assistant is on: a key is stored for [providerId] and the user
  /// accepted the data-sharing disclosure at [consentAcceptedAt] (FR-003).
  const AIAssistantSettings.enabled({
    required String this.providerId,
    required DateTime this.consentAcceptedAt,
    required this.updatedAt,
  }) : id = singletonId,
       isEnabled = true,
       hasStoredCredential = true;

  /// The fixed primary key of the one settings row — same `'singleton'`
  /// convention as `AppSettings`/`OnboardingStatus`.
  static const String singletonId = 'singleton';

  final String id;

  /// Default `false`. `true` only via [AIAssistantSettings.enabled].
  final bool isEnabled;

  /// Which provider adapter to use (a preset id, or the custom marker —
  /// research.md Decision 7). `null` while never configured.
  final String? providerId;

  /// Whether a key currently exists in secure storage for [providerId].
  /// Never the key value itself.
  final bool hasStoredCredential;

  /// When the user accepted the disclosure. Cleared on disable — re-enabling
  /// requires re-accepting (FR-016).
  final DateTime? consentAcceptedAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    isEnabled,
    providerId,
    hasStoredCredential,
    consentAcceptedAt,
    updatedAt,
  ];
}
