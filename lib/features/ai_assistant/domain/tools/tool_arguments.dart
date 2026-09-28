import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../budgets/domain/entities/budget_month.dart';
import '../../../finance/domain/entities/finance_history_filter.dart';
import 'tool_catalog.dart';

/// Typed reads of model-supplied tool arguments. The provider's JSON is
/// untrusted input (constitution Principle IX): anything of the wrong type
/// is a [ValidationFailure], never coerced into a guess.
abstract final class AIToolArgumentReader {
  /// A required, non-blank string.
  static Either<Failure, String> requiredString(
    Map<String, Object?> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value is! String || value.trim().isEmpty) {
      return Left(ValidationFailure('"$key" must be a non-empty string'));
    }
    return Right(value.trim());
  }

  /// An optional string; absent, `null` and blank all mean "not given".
  static Either<Failure, String?> optionalString(
    Map<String, Object?> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value == null) return const Right(null);
    if (value is! String) {
      return Left(ValidationFailure('"$key" must be a string'));
    }
    final trimmed = value.trim();
    return Right(trimmed.isEmpty ? null : trimmed);
  }

  /// A required period object (`tool_catalog.dart`'s period schema).
  static Either<Failure, Map<String, Object?>> periodObject(
    Map<String, Object?> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value is! Map) {
      return Left(ValidationFailure('"$key" must be a period object'));
    }
    if (value.keys.any((k) => k is! String)) {
      return Left(ValidationFailure('"$key" has a non-string key'));
    }
    return Right(value.cast<String, Object?>());
  }
}

/// Resolves a period argument into the [DateRange] 007's use cases take,
/// using 007's own presets ([DateRange.thisMonth]/[DateRange.lastMonth]) —
/// the model never does date math, and neither do the tools.
///
/// Also the tools' single source of "now", so tests can pin the clock.
@injectable
class AIPeriodResolver {
  AIPeriodResolver() : _now = DateTime.now;

  /// A pinned clock — for tests and deterministic callers.
  AIPeriodResolver.withClock(DateTime Function() now) : _now = now;

  final DateTime Function() _now;

  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  DateTime now() => _now();

  /// The current `'YYYY-MM'` budget month, per this resolver's clock.
  String currentMonth() => BudgetMonth.fromDate(_now());

  DateRange thisMonth() => DateRange.thisMonth(_now());

  DateRange lastMonth() => DateRange.lastMonth(_now());

  /// The full calendar month before [lastMonth] — 007's own `lastMonth`
  /// preset applied to the first day of last month.
  DateRange monthBeforeLast() => DateRange.lastMonth(lastMonth().start);

  /// Reads [key] from [arguments] as a period object and resolves it.
  Either<Failure, DateRange> resolveArgument(
    Map<String, Object?> arguments,
    String key,
  ) => AIToolArgumentReader.periodObject(
    arguments,
    key,
  ).flatMap((period) => resolve(period, key: key));

  /// Resolves one period object: `preset` is required; `custom` also
  /// requires `startDate` <= `endDate`, both real `YYYY-MM-DD` dates.
  Either<Failure, DateRange> resolve(
    Map<String, Object?> period, {
    String key = AIToolArgs.period,
  }) {
    final preset = period[AIToolArgs.preset];
    switch (preset) {
      case AIPeriodPresets.thisMonth:
        return Right(thisMonth());
      case AIPeriodPresets.lastMonth:
        return Right(lastMonth());
      case AIPeriodPresets.custom:
        final start = _parseDate(period[AIToolArgs.startDate]);
        final end = _parseDate(period[AIToolArgs.endDate]);
        if (start == null || end == null) {
          return Left(
            ValidationFailure(
              '"$key" custom period needs valid startDate and endDate '
              '(YYYY-MM-DD)',
            ),
          );
        }
        if (end.isBefore(start)) {
          return Left(
            ValidationFailure('"$key" endDate is before its startDate'),
          );
        }
        return Right(DateRange(start: start, end: end));
      default:
        return Left(
          ValidationFailure(
            '"$key".preset must be one of ${AIPeriodPresets.all}',
          ),
        );
    }
  }

  /// A strict `YYYY-MM-DD` parse that rejects impossible dates (e.g.
  /// `2026-02-30`) instead of letting `DateTime` roll them over.
  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    final match = _datePattern.firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}

/// The outcome of matching a model-supplied name against a list of
/// records. Never a silent best guess (contracts/financial_query_tools.md
/// cross-cutting rule): only an unambiguous match resolves.
sealed class AINameMatch<T> {
  const AINameMatch();
}

class AINameMatched<T> extends AINameMatch<T> {
  const AINameMatched(this.item);
  final T item;
}

class AINameNotFound<T> extends AINameMatch<T> {
  const AINameNotFound();
}

class AINameAmbiguous<T> extends AINameMatch<T> {
  const AINameAmbiguous(this.candidateNames);
  final List<String> candidateNames;
}

/// Case/whitespace-insensitive name resolution, the same normalization the
/// people feature applies (`FindPossibleDuplicatePerson.normalize`):
///
/// 1. exactly one record whose normalized name equals [query] → matched;
/// 2. otherwise exactly one record whose normalized name contains [query]
///    (or is contained in it) → matched — the result carries the record's
///    real name, so the substitution is visible to the model and the user;
/// 3. more than one → ambiguous (the candidate names are returned);
/// 4. none → not found.
AINameMatch<T> matchByName<T>(
  String query,
  Iterable<T> items,
  String Function(T) nameOf,
) {
  final needle = normalizeAIName(query);
  if (needle.isEmpty) return AINameNotFound<T>();
  final exact = [
    for (final item in items)
      if (normalizeAIName(nameOf(item)) == needle) item,
  ];
  if (exact.length == 1) return AINameMatched(exact.single);
  if (exact.length > 1) {
    return AINameAmbiguous([for (final item in exact) nameOf(item)]);
  }
  final partial = [
    for (final item in items)
      if (normalizeAIName(nameOf(item)).contains(needle) ||
          needle.contains(normalizeAIName(nameOf(item))))
        item,
  ];
  if (partial.length == 1) return AINameMatched(partial.single);
  if (partial.length > 1) {
    return AINameAmbiguous([for (final item in partial) nameOf(item)]);
  }
  return AINameNotFound<T>();
}

/// Trim, lowercase, collapse whitespace runs.
String normalizeAIName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// `'YYYY-MM-DD'` — how resolved periods are echoed back to the model.
String formatAIDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// The resolved period as `{startDate, endDate}`, so the model narrates
/// the exact dates the figures cover.
Map<String, Object?> aiPeriodData(DateRange range) => {
  AIToolArgs.startDate: formatAIDate(range.start),
  AIToolArgs.endDate: formatAIDate(range.end),
};
