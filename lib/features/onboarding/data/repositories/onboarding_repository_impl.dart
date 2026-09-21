import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_dao.dart';

@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._dao);

  final OnboardingDao _dao;

  @override
  Future<Either<Failure, bool>> isOnboardingComplete() async {
    try {
      final row = await _dao.getStatus();
      return Right(row?.isComplete ?? false);
    } catch (e) {
      return Left(CacheFailure('Failed to load onboarding status: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> completeOnboarding() async {
    try {
      final row = await _dao.getStatus();
      if (row?.isComplete ?? false) {
        return const Right(unit);
      }
      await _dao.markComplete(DateTime.now().millisecondsSinceEpoch);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save onboarding status: $e'));
    }
  }
}
