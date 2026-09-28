/// The standard occasion types offered by the type picker. Deliberately a
/// constant list of `String`s rather than a closed Dart `enum`: `Occasion.type`
/// also accepts free-text custom values (FR-002), exactly like
/// `Person.relationshipTag` already does (research.md Decision 6). Adding a
/// standard type later is then a data + localization change, not a schema
/// migration.
abstract final class OccasionType {
  static const String wedding = 'wedding';
  static const String engagement = 'engagement';
  static const String birthday = 'birthday';
  static const String newbornSebou = 'newbornSebou';

  /// The one value with behavior attached: contributions recorded under a
  /// condolence occasion default to `countsTowardBalance = false`, because
  /// condolence money is not a reciprocal social debt in Egyptian custom
  /// (FR-018, research.md Decision 3).
  static const String condolence = 'condolence';
  static const String celebration = 'celebration';
  static const String other = 'other';

  /// Display order in the picker.
  static const List<String> standardValues = [
    wedding,
    engagement,
    birthday,
    newbornSebou,
    condolence,
    celebration,
    other,
  ];

  /// `false` for a user-defined custom type, which has no localized label
  /// and is rendered verbatim.
  static bool isStandard(String type) => standardValues.contains(type);
}
