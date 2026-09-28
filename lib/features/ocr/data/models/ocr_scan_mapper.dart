import '../../../../core/money/currency.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../domain/entities/ocr_scan.dart';

/// Maps between the `ocr_scans` row and [OcrScan]. `status` and
/// `default_direction` are plain text columns; this is the single place
/// those strings turn into enums and back.
extension OcrScanMapper on db.OcrScan {
  OcrScan toDomain() => OcrScan(
    id: id,
    idempotencyKey: idempotencyKey,
    sourceImagePath: sourceImagePath,
    cropBounds: cropBounds,
    rotationDegrees: rotationDegrees,
    status: scanStatusFromDb(status),
    occasionId: occasionId,
    defaultDirection: directionFromDbOrNull(defaultDirection),
    currency: Currency.fromCode(currencyCode),
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    completedAt: completedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(completedAt!),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}

/// Exhaustive rather than defaulting, for the same reason the 001/008
/// mappers are: a scan whose status silently read back as something else
/// could present a `failed` batch as reviewable, or a `confirmed` one as
/// still pending. A wrong value should be loud.
ScanStatus scanStatusFromDb(String value) => switch (value) {
  'processing' => ScanStatus.processing,
  'needsReview' => ScanStatus.needsReview,
  'confirmed' => ScanStatus.confirmed,
  'discarded' => ScanStatus.discarded,
  'failed' => ScanStatus.failed,
  _ => throw StateError('Unknown scan status: $value'),
};

extension ScanStatusDb on ScanStatus {
  String get dbValue => switch (this) {
    ScanStatus.processing => 'processing',
    ScanStatus.needsReview => 'needsReview',
    ScanStatus.confirmed => 'confirmed',
    ScanStatus.discarded => 'discarded',
    ScanStatus.failed => 'failed',
  };
}

/// `null` is a real, meaningful value here — "the user has not chosen a
/// batch default yet" (FR-005) — so it is preserved rather than collapsed
/// into a default direction that would silently decide which way the money
/// went.
TransactionDirection? directionFromDbOrNull(String? value) => switch (value) {
  null => null,
  'given' => TransactionDirection.given,
  'received' => TransactionDirection.received,
  _ => throw StateError('Unknown direction: $value'),
};
