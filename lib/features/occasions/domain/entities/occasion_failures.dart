import '../../../../core/error/failure.dart';

/// No active occasion exists with the requested id — it was never created,
/// or it has since been deleted. Distinguished from a bare [NotFoundFailure]
/// so the UI can say "this occasion is gone" rather than the generic
/// "not found", and so a caller can tell an unknown occasion apart from an
/// unknown contribution in the same flow.
class OccasionNotFoundFailure extends NotFoundFailure {
  const OccasionNotFoundFailure(super.message);
}

/// No active participant contribution exists with the requested transaction
/// id — most often because the same row was already removed from the
/// person's own profile screen while this occasion screen was open (FR-010:
/// both screens act on one row).
class ParticipantNotFoundFailure extends NotFoundFailure {
  const ParticipantNotFoundFailure(super.message);
}
