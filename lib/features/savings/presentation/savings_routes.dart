/// The savings feature's route paths (research.md Decision 12), built in
/// one place so no page assembles a savings URL by hand. Registered in the
/// People branch of `app_router.dart`; `/savings/:goalId` is also 017's
/// notification deep-link target (`savingsGoalPath`), so it must not move.
abstract final class SavingsRoutes {
  /// The goals overview (US4) — the section's entry point, e.g. from
  /// Home's Savings card.
  static const String overview = '/savings';

  /// Archived goals (FR-020). A static segment, declared above
  /// `/savings/:goalId` like [newGoal].
  static const String archived = '/savings/archived';

  static const String newGoal = '/savings/new';

  static String goal(String goalId) => '/savings/$goalId';

  static String editGoal(String goalId) => '/savings/$goalId/edit';

  /// The what-if calculator (FR-013-FR-016).
  static String whatIf(String goalId) => '/savings/$goalId/what-if';

  /// The log form: a contribution by default, a withdrawal with
  /// [withdrawal].
  static String log(String goalId, {bool withdrawal = false}) => withdrawal
      ? '/savings/$goalId/log?type=withdrawal'
      : '/savings/$goalId/log';

  /// The same form, editing entry [contributionId].
  static String editEntry(String goalId, String contributionId) =>
      '/savings/$goalId/log?entry=$contributionId';

  /// `type` query value selecting a withdrawal on [log].
  static const String withdrawalType = 'withdrawal';
}
