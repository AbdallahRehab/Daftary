/// The standard goal types offered by the type picker. Deliberately a
/// constant list of `String`s rather than a closed Dart `enum`, same
/// open-set pattern as `OccasionType`: `SavingsGoal.type` is cosmetic, and
/// a goal may also have no type at all (a plain custom-named goal). Adding a
/// standard type later is a data + localization change, not a migration.
abstract final class SavingsGoalType {
  static const String emergencyFund = 'emergencyFund';
  static const String newCar = 'newCar';
  static const String wedding = 'wedding';
  static const String vacation = 'vacation';
  static const String newPhone = 'newPhone';
  static const String homeFurniture = 'homeFurniture';
  static const String education = 'education';
  static const String other = 'other';

  /// Display order in the picker.
  static const List<String> standardValues = [
    emergencyFund,
    newCar,
    wedding,
    vacation,
    newPhone,
    homeFurniture,
    education,
    other,
  ];

  /// `false` for `null` (a plain custom-named goal) and for any value not
  /// in [standardValues], which has no localized label.
  static bool isStandard(String? type) =>
      type != null && standardValues.contains(type);
}
