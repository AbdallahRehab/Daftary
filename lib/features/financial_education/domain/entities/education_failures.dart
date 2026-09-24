import '../../../../core/error/failure.dart';

/// The requested category or article id is not part of the bundled content
/// for the active language. Ids are internal navigation constants, so this
/// indicates a stale deep link or a content-authoring mismatch.
class ContentNotFoundFailure extends Failure {
  const ContentNotFoundFailure(super.message);
}

/// A bundled content asset was missing or could not be parsed — a
/// build-time authoring bug surfaced as a typed failure rather than a crash
/// (constitution Principle VII).
class ContentAssetLoadFailure extends Failure {
  const ContentAssetLoadFailure(super.message);
}
