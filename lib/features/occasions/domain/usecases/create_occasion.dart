import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/occasion.dart';
import '../repositories/occasions_repository.dart';

/// Creates a social occasion the user will then record contributions under
/// (FR-001/FR-002).
///
/// [idempotencyKey] is caller-supplied — generated once when the form opens,
/// not here — which is what turns a rapid double-tap on "Save" into a call
/// that returns the already-created occasion instead of a second one
/// (FR-019).
///
/// Name/type emptiness is validated by the repository, which owns the same
/// rule for every caller; duplicating it here would create a second place
/// for the two answers to drift apart.
@injectable
class CreateOccasion {
  const CreateOccasion(this._repository);

  final OccasionsRepository _repository;

  Future<Either<Failure, Occasion>> call({
    required String idempotencyKey,
    required String name,
    required DateTime date,
    required String type,
    String? notes,
  }) {
    return _repository.createOccasion(
      idempotencyKey: idempotencyKey,
      name: name,
      date: date,
      type: type,
      notes: notes,
    );
  }
}
