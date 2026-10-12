import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';

/// A fixed creation time for builders.
final DateTime kBuilderCreatedAt = DateTime(2026, 3, 4, 10, 15);

/// All four required fields read at high confidence.
ParseConfidence highConfidence() => ParseConfidence(
  fields: {
    for (final field in SmsField.required)
      field: FieldConfidence.read(FieldConfidenceLevel.high),
  },
  overall: OverallConfidence.high,
);

/// A valid synthetic pending import. Every value is invented.
PendingSmsImport buildPendingImport({
  String id = 'pending-1',
  String fingerprint = 'fp-1',
  SmsImportStatus status = SmsImportStatus.pending,
  SmsSource source = SmsSource.inboxScan,
  String? senderId = 'BANKX',
  String bankId = 'nbe',
  SmsKind kind = SmsKind.cardPurchase,
  SmsDirection direction = SmsDirection.debit,
  Money? amount = const Money.egp(12550),
  Money? foreignAmount,
  DateTime? occurredOn,
  int? timeMinutes = 615,
  String? merchant = 'Example Cafe',
  String? merchantKey = 'example cafe',
  String? counterparty,
  String? cardLast4 = '0000',
  SuggestedRecordType suggestedType = SuggestedRecordType.expense,
  ParseConfidence? confidence,
  Set<SmsWarning> warnings = const {},
  String? refHash,
  String? refAmountHash,
  DateTime? createdAt,
  DateTime? expiresAt,
  DateTime? decidedAt,
  String? savedRecordId,
  SavedRecordType? savedRecordType,
  String? parentImportId,
  bool withoutDate = false,
  bool hasRawText = true,
  List<int> candidates = const [],
  String? suggestedCategoryId,
  String? suggestedPersonId,
  String? foreignAmountText,
}) {
  final created = createdAt ?? kBuilderCreatedAt;
  return PendingSmsImport(
    id: id,
    fingerprint: fingerprint,
    status: status,
    source: source,
    senderId: senderId,
    bankId: bankId,
    parserId: bankId,
    ruleVersion: '$bankId@1',
    kind: kind,
    direction: direction,
    amount: amount,
    foreignAmount: foreignAmount,
    occurredOn: withoutDate ? null : occurredOn ?? DateTime(2026, 3, 4),
    timeMinutes: timeMinutes,
    merchant: merchant,
    merchantKey: merchantKey,
    counterparty: counterparty,
    cardLast4: cardLast4,
    suggestedType: suggestedType,
    confidence: confidence ?? highConfidence(),
    warnings: warnings,
    refHash: refHash,
    refAmountHash: refAmountHash,
    createdAt: created,
    expiresAt: expiresAt ?? PendingSmsImport.expiryFor(created),
    decidedAt: decidedAt,
    savedRecordId: savedRecordId,
    savedRecordType: savedRecordType,
    parentImportId: parentImportId,
    hasRawText: hasRawText,
    amountCandidates: candidates,
    suggestedCategoryId: suggestedCategoryId,
    suggestedPersonId: suggestedPersonId,
    foreignAmountText: foreignAmountText,
  );
}
