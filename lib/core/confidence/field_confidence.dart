import 'package:equatable/equatable.dart';

/// Where a candidate field's value came from: straight off the page, or
/// derived by the parser.
///
/// The distinction is the whole point of the type. A defaulted direction and
/// a crisply recognized amount must never look equally trustworthy on the
/// review screen (009 FR-013, research.md Decision 4).
enum FieldConfidenceKind { read, inferred }

/// A coarse three-step confidence signal for a [FieldConfidenceKind.read]
/// field, plus [none] for everything that was inferred.
///
/// Coarse on purpose: the on-device recognizer does not expose a meaningful
/// per-token numeric score, and inventing a precise-looking percentage from
/// something else (region size, contrast) would be dishonest about how much
/// the app actually knows (research.md Decision 4).
enum FieldConfidenceLevel { low, medium, high, none }

/// How much the app trusts one field of one [CandidateEntry].
///
/// The "an inferred field never carries a confidence level" rule from
/// data-model.md is enforced by construction: the only two ways to build
/// one are [FieldConfidence.read] and [FieldConfidence.inferred], and the
/// latter always produces [FieldConfidenceLevel.none]. No caller has to
/// remember the rule, and no UI can accidentally render a guess as a
/// confident read.
class FieldConfidence extends Equatable {
  const FieldConfidence._(this.kind, this.level);

  /// A value read directly from a recognized token, at [level] confidence.
  ///
  /// Passing [FieldConfidenceLevel.none] is rejected: a read with no
  /// confidence at all is an inferred value wearing the wrong label.
  factory FieldConfidence.read(FieldConfidenceLevel level) {
    assert(
      level != FieldConfidenceLevel.none,
      'A read field must carry low/medium/high confidence; use '
      'FieldConfidence.inferred() for a derived value.',
    );
    if (level == FieldConfidenceLevel.none) {
      return const FieldConfidence.inferred();
    }
    return FieldConfidence._(FieldConfidenceKind.read, level);
  }

  /// A value the parser derived or defaulted rather than read — a batch
  /// default direction, a date falling back to the scan's own date, an
  /// occasion guessed from a heading.
  const FieldConfidence.inferred()
    : kind = FieldConfidenceKind.inferred,
      level = FieldConfidenceLevel.none;

  final FieldConfidenceKind kind;
  final FieldConfidenceLevel level;

  bool get isInferred => kind == FieldConfidenceKind.inferred;
  bool get isRead => kind == FieldConfidenceKind.read;

  /// Whether this field is worth drawing the reviewer's eye to first: a
  /// low-confidence read is the likeliest place for a wrong number to hide.
  bool get isLowConfidenceRead => isRead && level == FieldConfidenceLevel.low;

  @override
  List<Object?> get props => [kind, level];
}
