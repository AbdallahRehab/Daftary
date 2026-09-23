import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../repositories/data_wipe_repository.dart';

@injectable
class DeleteAllUserData {
  const DeleteAllUserData(this._dataWipeRepository);

  final DataWipeRepository _dataWipeRepository;

  /// Wipes every table via [DataWipeRepository.deleteAllUserData] (FR-016,
  /// atomic per FR-018). Does NOT itself touch `OnboardingCubit` or trigger
  /// navigation — that orchestration belongs to the Presentation layer
  /// (`DeleteAccountCubit`), per research.md Decision 6, so this use case
  /// stays a pure "did the wipe succeed" answer.
  Future<Either<Failure, Unit>> call() =>
      _dataWipeRepository.deleteAllUserData();
}
