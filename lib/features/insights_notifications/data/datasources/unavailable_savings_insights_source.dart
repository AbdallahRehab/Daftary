import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/ports/savings_insights_source.dart';

/// Placeholder while 011 Savings Goals is not implemented in code: no goals
/// exist, so there is never anything to check in about. Replaced by an
/// adapter over 011's `SavingsRepository` once that feature ships.
@LazySingleton(as: SavingsInsightsSource)
class UnavailableSavingsInsightsSource implements SavingsInsightsSource {
  const UnavailableSavingsInsightsSource();

  @override
  Future<Either<Failure, List<SavingsGoalSnapshot>>> activeGoals() async =>
      const Right([]);

  @override
  Future<bool> goalExists(String goalId) async => false;
}
