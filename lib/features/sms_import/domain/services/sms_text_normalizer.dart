import 'package:equatable/equatable.dart';

/// The parser's normalization pipeline (parser-contract §3). Pure.
///
/// Never used for the fingerprint: that is the frozen
/// `FingerprintNormalizer` (FR-023).
abstract class SmsTextNormalizer {
  NormalizedText normalize(String text);
}

/// The two normalized forms of one message.
class NormalizedText extends Equatable {
  const NormalizedText({required this.forMatching, required this.forDisplay});

  /// Bidi and zero-width removed, whitespace collapsed, digits normalized,
  /// Arabic letters folded, Latin lower-cased. Matching only.
  final String forMatching;

  /// Steps 1-3 only: what merchant text and amounts are read from.
  final String forDisplay;

  @override
  List<Object?> get props => [forMatching, forDisplay];

  @override
  String toString() => 'NormalizedText(length: ${forDisplay.length})';
}
