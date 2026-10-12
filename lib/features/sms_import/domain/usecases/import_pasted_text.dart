import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_value_types.dart';
import '../services/sms_ingestion_service.dart';
import '../services/sms_message_splitter.dart';

/// Stages pasted or shared text as pending suggestions (domain-interfaces
/// §5.2, FR-017, FR-018, US4).
///
/// 1. [SmsMessageSplitter.split] enforces the bounds (10,000 characters,
///    50 messages) and strips the envelope lines; a bound exceeded is
///    `Left(InputTooLargeFailure)` and nothing is stored.
/// 2. Every message is ingested with `sender = null` and
///    `receivedAt = null`: a paste or a share has no trusted sender, so the
///    pipeline caps its confidence at Medium (`SmsSource.paste`/`share`).
/// 3. When no message was recognized and none was unreadable, the result
///    is `Left(NotRecognizedFailure)`. Nothing is stored in that case: the
///    ingestion stores only recognized transactions.
///
/// An unreadable-only paste (a bank message whose amount could not be
/// read) is `Right` with no new item, so the screen can offer manual
/// entry. Never creates a transaction (FR-022).
@injectable
class ImportPastedText {
  ImportPastedText(this._splitter, this._ingestion);

  final SmsMessageSplitter _splitter;
  final SmsIngestionService _ingestion;

  Future<Either<Failure, PasteImportResult>> call({
    required String text,
    required SmsSource source,
  }) async {
    // Only paste and share reach here; any other source is treated as the
    // most restrictive one (no sender, no receipt time, capped at Medium).
    final effective = source.capsConfidenceAtMedium ? source : SmsSource.paste;

    final split = _splitter.split(text);
    if (split case Left(:final value)) return Left(value);
    final messages = split.getOrElse((_) => const []);
    if (messages.isEmpty) return const Left(NotRecognizedFailure());

    var newIds = const <String>[];
    final ingested = await _ingestion.ingest(
      messages: [
        for (final message in messages) RawIncoming(text: message.text),
      ],
      source: effective,
      token: ScanCancellationToken(),
      onCreated: (ids) => newIds = ids,
    );
    return ingested.flatMap((summary) {
      if (summary.recognized == 0 && summary.unreadable == 0) {
        return const Left(NotRecognizedFailure());
      }
      return Right(PasteImportResult(summary: summary, newIds: newIds));
    });
  }
}
