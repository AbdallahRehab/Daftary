import '../../domain/entities/parse_result.dart';
import 'bank_profile.dart';
import 'sms_parser_registry.dart';

/// Multi-parser precedence (parser-contract §7, FR-028). Pure.
///
/// 1. Candidates come from [SmsParserRegistry.candidatesFor] (sender and
///    signature; signature only when there is no sender).
/// 2. No candidate: the generic profile.
/// 3. Several candidates: each parses on its own; an OTP from any of them
///    wins (an OTP is never parsed further); otherwise a transaction beats
///    a non-transactional result, which beats an unreadable one; among
///    transactions the highest overall confidence wins, then registry
///    order. Fields are never merged between profiles.
/// 4. If every candidate is `Unreadable(noAmount)`, the generic profile
///    gets a last try; when it recognizes nothing, the first candidate's
///    result stands. A malformed amount (`amountUnreadable`) never gets a
///    second opinion: another profile could read a different number.
ParseResult selectParse({
  required SmsParserRegistry registry,
  required String? sender,
  required String folded,
  required ParseResult Function(BankProfile profile) parseWith,
}) {
  final candidates = registry.candidatesFor(sender: sender, folded: folded);
  if (candidates.isEmpty) return parseWith(registry.generic);

  final results = [for (final profile in candidates) parseWith(profile)];

  for (final result in results) {
    if (result is NonTransactional &&
        result.reason == NonTransactionalReason.otp) {
      return result;
    }
  }

  ParsedTransaction? best;
  for (final result in results) {
    if (result is! ParsedTransaction) continue;
    if (best == null ||
        result.confidence.overall.index > best.confidence.overall.index) {
      best = result;
    }
  }
  if (best != null) return best;

  for (final result in results) {
    if (result is NonTransactional) return result;
  }

  final allNoAmount = results.every(
    (r) => r is Unreadable && r.reason == UnreadableReason.noAmount,
  );
  if (allNoAmount) {
    final fallback = parseWith(registry.generic);
    if (fallback is ParsedTransaction || fallback is NonTransactional) {
      return fallback;
    }
  }
  return results.first;
}
