import 'package:drift/drift.dart';

import 'sync_entity_type.dart';

/// 021: converts between a local drift row and its cloud wire payload
/// (contracts/dart-interfaces.md §2, contracts/sync-rpc.md §1). Each
/// feature owns the mappers for its own tables, under `data/sync/`.
///
/// Wire rules (research.md Decision 17), implemented by [SyncWire]:
///
/// - field names are the cloud column names, in snake_case;
/// - money values are **strings**, so int64 amounts survive JSON;
/// - instants are ISO-8601 UTC;
/// - `occurred_on` is `yyyy-MM-dd` in device-local time, sent with
///   `tz_offset_minutes`.
abstract class SyncMapper<Row> {
  const SyncMapper();

  SyncEntityType get type;

  /// The full wire snapshot of [row]. Never includes `owner_id`, `revision`
  /// or `server_*` — the server fills those.
  Map<String, Object?> toWire(Row row);

  /// The local row for a downloaded [json]. [existingLocal] is the current
  /// local row, if any, for device-only values the wire never carries.
  Insertable<Row> fromWire(Map<String, Object?> json, {Row? existingLocal});
}

/// Resolves the [SyncMapper] for each [SyncEntityType].
class SyncMapperRegistry {
  SyncMapperRegistry(Iterable<SyncMapper<Object?>> mappers)
    : _byType = _index(mappers);

  final Map<SyncEntityType, SyncMapper<Object?>> _byType;

  static Map<SyncEntityType, SyncMapper<Object?>> _index(
    Iterable<SyncMapper<Object?>> mappers,
  ) {
    final byType = <SyncEntityType, SyncMapper<Object?>>{};
    for (final mapper in mappers) {
      if (byType.containsKey(mapper.type)) {
        throw ArgumentError('Two sync mappers registered for ${mapper.type}');
      }
      byType[mapper.type] = mapper;
    }
    return Map.unmodifiable(byType);
  }

  /// The mapper for [type]. Throws [StateError] when none is registered.
  SyncMapper<Object?> mapperFor(SyncEntityType type) {
    final mapper = _byType[type];
    if (mapper == null) {
      throw StateError('No sync mapper registered for ${type.wire}');
    }
    return mapper;
  }

  /// The typed mapper for [type]. Throws [StateError] when none is
  /// registered or its row type is not [Row].
  SyncMapper<Row> of<Row>(SyncEntityType type) {
    final mapper = mapperFor(type);
    if (mapper is! SyncMapper<Row>) {
      throw StateError('The ${type.wire} mapper does not map $Row');
    }
    return mapper;
  }

  /// Every registered type.
  Set<SyncEntityType> get types => _byType.keys.toSet();
}

/// Shared encoders/decoders for the wire rules above.
abstract final class SyncWire {
  /// Money as a decimal string (int64-safe).
  static String money(int minorUnits) => minorUnits.toString();

  /// Parses money sent as a string (the push shape) or an integer (how
  /// `jsonb` renders a `bigint` on pull).
  static int parseMoney(Object? value, String field) => switch (value) {
    final String s => int.tryParse(s) ?? _bad(field, value),
    final int i => i,
    _ => _bad(field, value),
  };

  /// Epoch milliseconds as an ISO-8601 UTC instant.
  static String instant(int epochMs) => DateTime.fromMillisecondsSinceEpoch(
    epochMs,
    isUtc: true,
  ).toIso8601String();

  static String? instantOrNull(int? epochMs) =>
      epochMs == null ? null : instant(epochMs);

  static int parseInstant(Object? value, String field) {
    if (value is! String) return _bad(field, value);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return _bad(field, value);
    return parsed.millisecondsSinceEpoch;
  }

  static int? parseInstantOrNull(Object? value, String field) =>
      value == null ? null : parseInstant(value, field);

  /// The first present instant among [fields] (e.g. `client_created_at`,
  /// then `server_created_at` for rows written before a client stamp).
  static int parseFirstInstant(Map<String, Object?> json, List<String> fields) {
    for (final field in fields) {
      final value = json[field];
      if (value != null) return parseInstant(value, field);
    }
    return _bad(fields.join('|'), null);
  }

  /// The `occurred_at`, `occurred_on` and `tz_offset_minutes` fields for a
  /// local `date` (epoch ms): the exact instant, plus the calendar day and
  /// UTC offset on this device at that instant.
  static Map<String, Object?> occurrence(int epochMs) {
    final local = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return {
      'occurred_at': instant(epochMs),
      'occurred_on': localDay(local),
      'tz_offset_minutes': local.timeZoneOffset.inMinutes,
    };
  }

  /// `yyyy-MM-dd` of [local]'s own calendar fields.
  static String localDay(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  static final _day = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// B1: the local midnight (epoch ms) of the calendar day in [dayField]
  /// (`yyyy-MM-dd`), whatever this device's time zone is. The day is what the
  /// user picked; rebuilding it from the UTC instant would shift it by the
  /// difference between the two devices' offsets. Falls back to
  /// [instantField] when the day is missing (rows written before it was
  /// sent); a malformed day is a [FormatException].
  static int parseLocalDay(
    Map<String, Object?> json, {
    String dayField = 'occurred_on',
    String instantField = 'occurred_at',
  }) {
    final value = json[dayField];
    if (value == null) return parseInstant(json[instantField], instantField);
    final match = value is String ? _day.firstMatch(value) : null;
    if (match == null) return _bad(dayField, value);
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final local = DateTime(year, month, day);
    // `DateTime` rolls an impossible day (2026-02-30) over to the next month.
    if (local.year != year || local.month != month || local.day != day) {
      return _bad(dayField, value);
    }
    return local.millisecondsSinceEpoch;
  }

  /// The latest non-null of [epochMs] — a record's last client change.
  static int latest(List<int?> epochMs) =>
      epochMs.whereType<int>().reduce((a, b) => a > b ? a : b);

  static String string(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is String ? value : _bad(field, value);
  }

  static String? stringOrNull(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value == null) return null;
    return value is String ? value : _bad(field, value);
  }

  static bool boolean(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is bool ? value : _bad(field, value);
  }

  static int integer(Map<String, Object?> json, String field) {
    final value = json[field];
    return value is int ? value : _bad(field, value);
  }

  /// [field] must be one of [allowed].
  static String oneOf(
    Map<String, Object?> json,
    String field,
    Set<String> allowed,
  ) {
    final value = string(json, field);
    return allowed.contains(value) ? value : _bad(field, value);
  }

  static Never _bad(String field, Object? value) => throw FormatException(
    'Invalid wire value for "$field"',
    value?.runtimeType.toString(),
  );
}
