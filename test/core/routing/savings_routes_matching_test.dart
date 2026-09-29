import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/savings/presentation/savings_routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// T066 — the static `/savings/...` paths are declared above
/// `/savings/:goalId` (research.md Decision 12), so `new` and `archived`
/// are never captured as a goal id; and a real goal id still reaches the
/// goal page, 017's deep-link target.
void main() {
  String matchedPath(String location) {
    final match = appRouter.configuration.findMatch(Uri.parse(location));
    return match.last.route.path;
  }

  test('/savings is the overview', () {
    expect(matchedPath(SavingsRoutes.overview), SavingsRoutes.overview);
  });

  test('/savings/new and /savings/archived never resolve to the goal page', () {
    expect(matchedPath(SavingsRoutes.newGoal), SavingsRoutes.newGoal);
    expect(matchedPath(SavingsRoutes.archived), SavingsRoutes.archived);
    expect(matchedPath(SavingsRoutes.newGoal), isNot('/savings/:goalId'));
    expect(matchedPath(SavingsRoutes.archived), isNot('/savings/:goalId'));
  });

  test('a goal id resolves to the goal page with its id', () {
    final match = appRouter.configuration.findMatch(
      Uri.parse(SavingsRoutes.goal('abc-123')),
    );
    expect(match.last.route.path, '/savings/:goalId');
    expect(match.pathParameters['goalId'], 'abc-123');
  });
}
