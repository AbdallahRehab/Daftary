import 'package:equatable/equatable.dart';

/// The two shapes an [ImportProvenance] can take.
enum ImportProvenanceKind {
  /// Saved from a bank-message import (023).
  sms,

  /// A value written by a future client. Kept and round-tripped, never
  /// interpreted.
  unknown,
}

/// Where a saved `MoneyTransaction` or `FinanceEntry` was imported from
/// (023 data-model §2.8). Shared by `transactions` and `finance`, so it lives
/// in `core` (constitution II).
///
/// `null` on a record means "not imported" (FR-057). This is deliberately
/// not a new `TransactionSource` value (FR-086): `source` keeps describing
/// the capture method, and this type describes the import origin.
///
/// The wire/DB string `'sms'` maps to [sms]. Any other non-null string maps
/// to an [ImportProvenanceKind.unknown] value that keeps the original string
/// in [wire], so a value written by a newer client survives a round trip
/// through this client unchanged. Equality compares [wire].
class ImportProvenance extends Equatable {
  const ImportProvenance._(this.kind, this.wire);

  /// The bank-message import provenance (`'sms'`).
  static const ImportProvenance sms = ImportProvenance._(
    ImportProvenanceKind.sms,
    smsWire,
  );

  /// The wire/DB string of [sms].
  static const String smsWire = 'sms';

  /// Parses a stored or synced value: `'sms'` -> [sms], any other non-null
  /// string -> an unknown provenance that preserves it, `null` -> `null`.
  /// Never throws.
  static ImportProvenance? fromWire(String? wire) {
    if (wire == null) return null;
    if (wire == smsWire) return sms;
    return ImportProvenance._(ImportProvenanceKind.unknown, wire);
  }

  final ImportProvenanceKind kind;

  /// The exact string to store or send. For an unknown provenance this is
  /// the original string, unchanged.
  final String wire;

  bool get isSms => kind == ImportProvenanceKind.sms;
  bool get isUnknown => kind == ImportProvenanceKind.unknown;

  @override
  List<Object?> get props => [wire];

  @override
  String toString() => 'ImportProvenance(${kind.name})';
}
