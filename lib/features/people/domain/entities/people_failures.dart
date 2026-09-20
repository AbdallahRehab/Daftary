import '../../../../core/error/failure.dart';
import 'person.dart';

/// Returned instead of inserting when a new person's name exactly matches,
/// prefixes, or is contained within an existing person's name (FR-003).
/// Never a silent auto-merge — the caller decides whether to pick one of
/// [matches] or proceed via `confirmCreateDespiteDuplicate`.
class PossibleDuplicateFailure extends Failure {
  const PossibleDuplicateFailure(this.matches)
    : super('A similar person already exists');

  final List<Person> matches;

  @override
  List<Object?> get props => [message, matches];
}

/// Returned when a permanent delete is attempted on a person who has any
/// recorded transaction, including soft-deleted ones (data-model.md: kept
/// to preserve audit-history attribution). The caller should offer
/// archiving instead (FR-017).
class PersonHasTransactionsFailure extends Failure {
  const PersonHasTransactionsFailure()
    : super('This person has recorded transactions and cannot be deleted');
}
