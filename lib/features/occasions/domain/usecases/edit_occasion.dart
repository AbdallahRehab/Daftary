import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion.dart';
import '../repositories/occasions_repository.dart';

/// Edits an occasion's name, date, type, and notes after creation (FR-012).
///
/// Changing [type] to or from `condolence` deliberately leaves the
/// `countsTowardBalance` flag on contributions already recorded untouched
/// (research.md Decision 3): that flag is captured per row at the moment the
/// money was entered, so correcting a typo in an occasion's type can never
/// silently move somebody's balance. This use case therefore touches nothing
/// but the occasion row itself.
@injectable
class EditOccasion {
  const EditOccasion(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Occasion>> call({
    required String occasionId,
    required String name,
    required DateTime date,
    required String type,
    String? notes,
  }) {
    return _repository.editOccasion(
      occasionId: occasionId,
      name: name,
      date: date,
      type: type,
      notes: notes,
    );
  }
}
