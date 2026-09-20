import 'package:injectable/injectable.dart';

import '../entities/person.dart';

/// Pure domain function implementing the clarified FR-003 duplicate-name
/// rule: case/whitespace-insensitive, bidirectional exact/prefix/contains
/// match (research.md Decision 8) — no fuzzy/edit-distance matching.
@injectable
class FindPossibleDuplicatePerson {
  const FindPossibleDuplicatePerson();

  /// Returns every person in [existingPeople] whose normalized name exactly
  /// matches, contains, or is contained within [candidateName]'s normalized
  /// form. A prefix match and an exact match are both special cases of
  /// "contains", so a single bidirectional substring check covers all three
  /// (e.g. "Ahmed" vs. "Ahmed Ali" matches in either direction).
  List<Person> call(String candidateName, List<Person> existingPeople) {
    final normalizedCandidate = normalize(candidateName);
    if (normalizedCandidate.isEmpty) return const [];
    return existingPeople.where((person) {
      final normalizedExisting = normalize(person.name);
      return normalizedExisting.contains(normalizedCandidate) ||
          normalizedCandidate.contains(normalizedExisting);
    }).toList();
  }

  /// Lowercases and collapses runs of whitespace to a single space, after
  /// trimming — the normalization FR-003 requires before any comparison.
  static String normalize(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
