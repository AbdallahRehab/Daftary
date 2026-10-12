import 'dart:convert';

import '../../../../core/confidence/field_confidence.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/money.dart';
import '../../domain/entities/parse_confidence.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_enums.dart';

/// Maps `pending_sms_imports` rows to [PendingSmsImport] and back
/// (data-model §3.1, §4.1).
///
/// The sealed `raw_blob` never enters the entity: [PendingSmsImportRowMapper.toDomain]
/// only derives `hasRawText` from `raw_blob IS NOT NULL`, and
/// [pendingImportToCompanion] never writes the blob (the repository seals
/// and writes it itself).
///
/// Every decode is total: a malformed JSON column or an unknown enum string
/// maps to the conservative default of its type and never throws, so one
/// bad row can never break the pending list.
extension PendingSmsImportRowMapper on db.PendingSmsImportRow {
  PendingSmsImport toDomain() {
    final extras = decodeWarningsJson(warningsJson);
    final currency = currencyCode == null
        ? null
        : Currency.tryFromCode(currencyCode!);
    final minor = amountMinorUnits;
    return PendingSmsImport(
      id: id,
      parentImportId: parentImportId,
      fingerprint: fingerprint,
      status: SmsImportStatus.fromDb(status),
      source: SmsSource.fromDb(origin),
      senderId: senderId,
      bankId: bankId,
      parserId: parserId,
      ruleVersion: ruleVersion,
      kind: SmsKind.fromDb(kind),
      direction: SmsDirection.fromDb(direction),
      amount: minor == null || currency == null
          ? null
          : Money.fromMinorUnits(minor, currency),
      amountCandidates: extras.amountCandidates,
      foreignAmountText: extras.foreignAmountText,
      foreignAmount: extras.foreignAmount,
      occurredOn: occurredOn == null ? null : _fromMillis(occurredOn!),
      timeMinutes: timeMinutes,
      merchant: merchant,
      merchantKey: merchantKey,
      counterparty: counterparty,
      cardLast4: cardLast4,
      suggestedCategoryId: suggestedCategoryId,
      suggestedPersonId: suggestedPersonId,
      suggestedType: SuggestedRecordType.fromDb(suggestedAction),
      confidence: decodeConfidenceJson(confidenceJson),
      warnings: extras.warnings,
      refHash: refHash,
      refAmountHash: refAmountHash,
      receivedAt: receivedAt == null ? null : _fromMillis(receivedAt!),
      createdAt: _fromMillis(createdAt),
      expiresAt: _fromMillis(expiresAt),
      decidedAt: decidedAt == null ? null : _fromMillis(decidedAt!),
      savedRecordId: savedRecordId,
      savedRecordType: SavedRecordType.fromDb(savedRecordType),
      hasRawText: rawBlob != null,
    );
  }
}

/// The insert companion for [item]. The blob is set by the repository
/// after sealing; it is never part of the entity.
db.PendingSmsImportsCompanion pendingImportToCompanion(PendingSmsImport item) {
  return db.PendingSmsImportsCompanion.insert(
    id: item.id,
    fingerprint: item.fingerprint,
    parentImportId: db.Value(item.parentImportId),
    status: db.Value(item.status.dbValue),
    origin: item.source.dbValue,
    senderId: db.Value(item.senderId),
    bankId: item.bankId,
    parserId: item.parserId,
    ruleVersion: item.ruleVersion,
    kind: item.kind.dbValue,
    direction: item.direction.dbValue,
    amountMinorUnits: db.Value(item.amount?.minorUnits),
    currencyCode: db.Value(item.amount?.currency.code),
    occurredOn: db.Value(
      item.occurredOn == null ? null : dateOnlyMillis(item.occurredOn!),
    ),
    timeMinutes: db.Value(item.timeMinutes),
    merchant: db.Value(item.merchant),
    merchantKey: db.Value(item.merchantKey),
    counterparty: db.Value(item.counterparty),
    cardLast4: db.Value(item.cardLast4),
    suggestedCategoryId: db.Value(item.suggestedCategoryId),
    suggestedPersonId: db.Value(item.suggestedPersonId),
    suggestedAction: db.Value(item.suggestedType.dbValue),
    confidenceJson: encodeConfidenceJson(item.confidence),
    warningsJson: db.Value(
      encodeWarningsJson(
        warnings: item.warnings,
        amountCandidates: item.amountCandidates,
        foreignAmountText: item.foreignAmountText,
        foreignAmount: item.foreignAmount,
      ),
    ),
    refHash: db.Value(item.refHash),
    refAmountHash: db.Value(item.refAmountHash),
    receivedAt: db.Value(item.receivedAt?.millisecondsSinceEpoch),
    createdAt: item.createdAt.millisecondsSinceEpoch,
    expiresAt: item.expiresAt.millisecondsSinceEpoch,
    decidedAt: db.Value(item.decidedAt?.millisecondsSinceEpoch),
    savedRecordId: db.Value(item.savedRecordId),
    savedRecordType: db.Value(item.savedRecordType?.dbValue),
  );
}

/// Local midnight of [date], as epoch millis (the repo's date-only
/// convention).
int dateOnlyMillis(DateTime date) =>
    DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;

DateTime _fromMillis(int millis) => DateTime.fromMillisecondsSinceEpoch(millis);

// --------------------------------------------------------------- confidence

/// `{"overall":"high","fields":{"amount":"read:high","date":"inferred"}}`
/// (data-model §2.6).
String encodeConfidenceJson(ParseConfidence confidence) {
  return jsonEncode({
    'overall': confidence.overall.dbValue,
    'fields': {
      for (final field in SmsField.values)
        if (confidence.fields[field] != null)
          field.name: _fieldToken(confidence.fields[field]!),
    },
  });
}

/// Total decode: anything unreadable gives Low with no fields.
ParseConfidence decodeConfidenceJson(String? json) {
  final map = _decodeObject(json);
  final fields = <SmsField, FieldConfidence>{};
  final rawFields = map['fields'];
  if (rawFields is Map) {
    for (final field in SmsField.values) {
      final token = rawFields[field.name];
      final value = token is String ? _fieldFromToken(token) : null;
      if (value != null) fields[field] = value;
    }
  }
  final overall = map['overall'];
  return ParseConfidence(
    fields: fields,
    overall: OverallConfidence.fromDb(overall is String ? overall : null),
  );
}

String _fieldToken(FieldConfidence confidence) =>
    confidence.isInferred ? 'inferred' : 'read:${confidence.level.name}';

FieldConfidence? _fieldFromToken(String token) {
  if (token == 'inferred') return const FieldConfidence.inferred();
  return switch (token) {
    'read:low' => FieldConfidence.read(FieldConfidenceLevel.low),
    'read:medium' => FieldConfidence.read(FieldConfidenceLevel.medium),
    'read:high' => FieldConfidence.read(FieldConfidenceLevel.high),
    _ => null,
  };
}

// ----------------------------------------------------------------- warnings

/// What `warnings_json` carries besides the warning codes (data-model §4.1).
class PendingImportExtras {
  const PendingImportExtras({
    this.warnings = const {},
    this.amountCandidates = const [],
    this.foreignAmountText,
    this.foreignAmount,
  });

  final Set<SmsWarning> warnings;
  final List<int> amountCandidates;
  final String? foreignAmountText;
  final Money? foreignAmount;
}

/// Neutral when there is nothing to store: `'{}'`, the column default.
String encodeWarningsJson({
  Set<SmsWarning> warnings = const {},
  List<int> amountCandidates = const [],
  String? foreignAmountText,
  Money? foreignAmount,
}) {
  final map = <String, Object?>{
    if (warnings.isNotEmpty)
      'warnings': [
        for (final warning in SmsWarning.values)
          if (warnings.contains(warning)) warning.dbValue,
      ],
    if (amountCandidates.isNotEmpty) 'amountCandidates': amountCandidates,
    'foreignAmountText': ?foreignAmountText,
    if (foreignAmount != null) ...{
      'foreignAmountMinor': foreignAmount.minorUnits,
      'foreignCurrency': foreignAmount.currency.code,
    },
  };
  return jsonEncode(map);
}

/// Total decode: unknown warnings are dropped, malformed parts ignored.
PendingImportExtras decodeWarningsJson(String? json) {
  final map = _decodeObject(json);
  final warnings = <SmsWarning>{};
  final rawWarnings = map['warnings'];
  if (rawWarnings is List) {
    for (final value in rawWarnings) {
      final warning = value is String ? SmsWarning.fromDb(value) : null;
      if (warning != null) warnings.add(warning);
    }
  }
  final candidates = <int>[];
  final rawCandidates = map['amountCandidates'];
  if (rawCandidates is List) {
    for (final value in rawCandidates) {
      if (value is int && value > 0) candidates.add(value);
    }
  }
  final text = map['foreignAmountText'];
  final foreignMinor = map['foreignAmountMinor'];
  final foreignCode = map['foreignCurrency'];
  final foreignCurrency = foreignCode is String
      ? Currency.tryFromCode(foreignCode)
      : null;
  return PendingImportExtras(
    warnings: warnings,
    amountCandidates: candidates,
    foreignAmountText: text is String ? text : null,
    foreignAmount:
        foreignMinor is int && foreignMinor > 0 && foreignCurrency != null
        ? Money.fromMinorUnits(foreignMinor, foreignCurrency)
        : null,
  );
}

Map<String, Object?> _decodeObject(String? json) {
  if (json == null || json.isEmpty) return const {};
  try {
    final decoded = jsonDecode(json);
    return decoded is Map<String, Object?> ? decoded : const {};
  } on FormatException {
    // The column is ours; a malformed value reads as empty. The exception
    // text is never inspected or kept.
    return const {};
  }
}
