import 'bank_profile.dart';
import 'generic_profile.dart';
import 'profiles/aaib_profile.dart';
import 'profiles/banque_du_caire_profile.dart';
import 'profiles/banque_misr_profile.dart';
import 'profiles/cib_profile.dart';
import 'profiles/instapay_profile.dart';
import 'profiles/nbe_profile.dart';
import 'profiles/qnb_alahli_profile.dart';

/// The ordered bank profiles plus the generic fallback (parser-contract
/// §2, research Decision 8). Order is the final tie-break (FR-028).
///
/// v1 ships seven bank profiles (NBE, Banque Misr, CIB, QNB Alahli,
/// Banque du Caire, AAIB, InstaPay; T117), each of which passed its gate
/// test over SYNTHETIC fixtures, plus the generic fallback. Every bank
/// profile is `verified: false` until real anonymized samples exist
/// (orchestrator decision on OQ2/OQ3), so its results are capped at Medium
/// with `SmsWarning.unverifiedProfile`. Versions are pinned by
/// `test/fixtures/sms/_versions.json`.
class SmsParserRegistry {
  SmsParserRegistry({
    List<BankProfile> profiles = const [],
    BankProfile? generic,
  }) : profiles = List.unmodifiable(profiles),
       generic = generic ?? genericProfile {
    assert(
      this.profiles.every((p) => !p.isGeneric),
      'Bank profiles must not be generic',
    );
    assert(this.generic.isGeneric, 'The fallback must be generic');
  }

  /// The bank profiles the app ships, in tie-break order (T117).
  static final List<BankProfile> shippedBankProfiles = List.unmodifiable([
    nbeProfile,
    banqueMisrProfile,
    cibProfile,
    qnbAlahliProfile,
    banqueDuCaireProfile,
    aaibProfile,
    instapayProfile,
  ]);

  /// The registry the app ships.
  static final SmsParserRegistry standard = SmsParserRegistry(
    profiles: shippedBankProfiles,
  );

  /// Bank profiles, in tie-break order.
  final List<BankProfile> profiles;

  /// The fallback profile.
  final BankProfile generic;

  /// Every profile, bank profiles first.
  List<BankProfile> get all => [...profiles, generic];

  /// The union of profile senders, canonical (FR-020).
  Set<String> get allowedSenders => {
    for (final profile in profiles)
      for (final sender in profile.senders) canonicalSender(sender)!,
  };

  /// `{profileId: version}` of every profile, generic included.
  Map<String, int> get currentVersions => {
    for (final profile in all) profile.id: profile.version,
  };

  /// Canonical sender: upper-case, no whitespace. `null` stays `null`.
  static String? canonicalSender(String? sender) {
    if (sender == null) return null;
    final canonical = sender.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    return canonical.isEmpty ? null : canonical;
  }

  /// The candidate bank profiles for one message (FR-028):
  /// 1. with a sender: profiles whose senders contain it AND whose
  ///    signatures match the folded content;
  /// 2. without a sender (paste, share): profiles whose signatures match.
  ///
  /// An empty list means "generic". A recognized sender whose content
  /// matches no signature therefore falls to generic, as does a spoofed or
  /// look-alike sender.
  List<BankProfile> candidatesFor({
    required String? sender,
    required String folded,
  }) {
    final canonical = canonicalSender(sender);
    return [
      for (final profile in profiles)
        if ((canonical == null ||
                profile.senders.map(canonicalSender).contains(canonical)) &&
            profile.signatures.any((s) => s.matches(folded)))
          profile,
    ];
  }
}
