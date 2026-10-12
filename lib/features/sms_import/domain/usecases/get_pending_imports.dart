import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/pending_sms_import.dart';
import '../repositories/sms_import_repository.dart';

/// The pending items, low confidence first, then oldest first (FR-042:
/// confidence changes the order only, never what can be added).
@injectable
class GetPendingImports {
  GetPendingImports(this._repository);

  final SmsImportRepository _repository;

  Future<Either<Failure, List<PendingSmsImport>>> call() async {
    final result = await _repository.watchPending().first;
    return result.map(sortForReview);
  }

  /// The review order: overall confidence ascending (Low first), then
  /// creation time, then id (stable).
  static List<PendingSmsImport> sortForReview(List<PendingSmsImport> items) {
    final sorted = [
      for (final item in items)
        if (item.isPending) item,
    ];
    sorted.sort((a, b) {
      final byConfidence = a.confidence.overall.index.compareTo(
        b.confidence.overall.index,
      );
      if (byConfidence != 0) return byConfidence;
      final byAge = a.createdAt.compareTo(b.createdAt);
      return byAge != 0 ? byAge : a.id.compareTo(b.id);
    });
    return List.unmodifiable(sorted);
  }
}
