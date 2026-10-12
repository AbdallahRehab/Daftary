import 'sms_template.dart';
import 'sms_text_normalizer.dart';

/// Reads dates and times from folded text (FR-036, FR-038,
/// parser-contract §5).
///
/// Regex plus manual `DateTime(y, m, d)` construction with a round-trip
/// validity check (the `SyncWire.parseLocalDay` idiom); no `intl` parsing,
/// which is locale-dependent. Month names: English (full and 3-letter) and
/// Arabic in Egyptian and Levantine spellings, keyed after folding.
///
/// Year inference (orchestrator decision CHK050): a date without a year
/// takes the current year of the injected clock; if that date is more than
/// one day after "now", the previous year. The result is always marked
/// inferred.
class SmsDateReader {
  const SmsDateReader._();

  static const Map<String, int> _englishMonths = {
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, //
    'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10,
    'november': 11, 'december': 12, 'jan': 1, 'feb': 2, 'mar': 3,
    'apr': 4, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'sept': 9,
    'oct': 10, 'nov': 11, 'dec': 12,
  };

  static const Map<String, int> _arabicMonths = {
    // Egyptian
    'يناير': 1, 'فبراير': 2, 'مارس': 3, 'أبريل': 4, 'إبريل': 4, //
    'مايو': 5, 'يونيو': 6, 'يونية': 6, 'يوليو': 7, 'يولية': 7,
    'أغسطس': 8, 'سبتمبر': 9, 'أكتوبر': 10, 'نوفمبر': 11, 'ديسمبر': 12,
    // Levantine
    'كانون الثاني': 1, 'شباط': 2, 'آذار': 3, 'نيسان': 4, 'أيار': 5,
    'حزيران': 6, 'تموز': 7, 'آب': 8, 'أيلول': 9, 'تشرين الأول': 10,
    'تشرين الثاني': 11, 'كانون الأول': 12,
  };

  /// Folded month name -> month number.
  static final Map<String, int> _months = {
    for (final e in _englishMonths.entries) e.key: e.value,
    for (final e in _arabicMonths.entries)
      SmsTextNormalizerImpl.fold(e.key): e.value,
  };

  static final String _monthAlternation = () {
    final names = _months.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return names.map(RegExp.escape).join('|');
  }();

  static final String _englishMonthAlternation = () {
    final names = _englishMonths.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return names.join('|');
  }();

  /// `d/m/yyyy`, `d-m-yy`, `d.m.yyyy` (the separator repeats).
  static final RegExp _numericWithYear = RegExp(
    r'(?<![0-9/.\-])(\d{1,2})([/.\-])(\d{1,2})\2(\d{4}|\d{2})(?![0-9]|[/.\-:]\d)',
  );

  /// `yyyy-mm-dd`.
  static final RegExp _iso = RegExp(
    r'(?<![0-9/.\-])(\d{4})-(\d{1,2})-(\d{1,2})(?![0-9]|[/.\-]\d)',
  );

  /// `d/m` with no year.
  static final RegExp _numericNoYear = RegExp(
    r'(?<![0-9/.\-])(\d{1,2})/(\d{1,2})(?![0-9]|[/.]\d)',
  );

  /// `4 mar 2026`, `04-mar-26`, `4 مارس`.
  static final RegExp _dayMonthName = RegExp(
    '(?<![0-9])(\\d{1,2})(?:st|nd|rd|th)?[ \\-]?($_monthAlternation)'
    '(?![a-z\u{0621}-\u{064A}])(?:[ \\-,]{1,2}(\\d{4}|\\d{2})(?![0-9:]))?',
  );

  /// `mar 4, 2026`, `march 4` (English only).
  static final RegExp _monthNameDay = RegExp(
    '(?<![a-z])($_englishMonthAlternation)[ \\-]?(\\d{1,2})(?:st|nd|rd|th)?'
    '(?![0-9:])(?:,? (\\d{4})(?![0-9:]))?',
  );

  /// Times: `10:15`, `10:15:30`, `9:05 pm`, `9:05 م`.
  static final RegExp _time = RegExp(
    '(?<![0-9:])([01]?\\d|2[0-3]):([0-5]\\d)(?::[0-5]\\d)?(?![0-9])'
    '(?: ?(a\\.m\\.|p\\.m\\.|am|pm|صباحا|مساءا|مساء|ص|م)'
    '(?![a-z\u{0621}-\u{064A}]))?',
  );

  /// A date context keyword right before a year-less `d/m`.
  static final RegExp _dateKeywordBefore = RegExp(
    r'(?:on|date|dated|في|بتاريخ|تاريخ|يوم)[ :]{1,2}$',
  );

  /// Every folded month name (English and Arabic), for the envelope rules.
  static Iterable<String> get foldedMonthNames => _months.keys;

  /// Every pattern, for the backtracking guard test.
  static List<RegExp> get patternsForTest => [
    _numericWithYear,
    _iso,
    _numericNoYear,
    _dayMonthName,
    _monthNameDay,
    _time,
    _dateKeywordBefore,
    _modalVerbAfter,
  ];

  /// The earliest valid date in [folded], or `null`.
  static DateRead? findDate(
    String folded, {
    required DateOrder order,
    required DateTime now,
  }) {
    final found = <DateRead>[];
    for (final m in _numericWithYear.allMatches(folded)) {
      final read = _numeric(m[1]!, m[3]!, m[4], order, now, m.start, m.end);
      if (read != null) found.add(read);
    }
    for (final m in _iso.allMatches(folded)) {
      final read = _build(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
        m.start,
        m.end,
      );
      if (read != null) found.add(read);
    }
    for (final m in _numericNoYear.allMatches(folded)) {
      if (!_yearlessContext(folded, m.start, m.end)) continue;
      final read = _numeric(m[1]!, m[2]!, null, order, now, m.start, m.end);
      if (read != null) found.add(read);
    }
    for (final m in _dayMonthName.allMatches(folded)) {
      if (_modalMay(folded, m)) continue;
      final read = _named(m[1]!, m[2]!, m[3], now, m.start, m.end);
      if (read != null) found.add(read);
    }
    for (final m in _monthNameDay.allMatches(folded)) {
      final read = _named(m[2]!, m[1]!, m[3], now, m.start, m.end);
      if (read != null) found.add(read);
    }
    if (found.isEmpty) return null;
    found.sort((a, b) => a.start.compareTo(b.start));
    return found.first;
  }

  /// Parses a template `date` group (the whole text is one date).
  static DateRead? parseDate(
    String text, {
    required DateOrder order,
    required DateTime now,
  }) {
    final folded = SmsTextNormalizerImpl.fold(text).trim();
    final read = findDate(folded, order: order, now: now);
    if (read != null) return read;
    // A template may capture a year-less `d/m` without a keyword.
    final m = _numericNoYear.firstMatch(folded);
    if (m == null) return null;
    return _numeric(m[1]!, m[2]!, null, order, now, m.start, m.end);
  }

  /// The earliest valid time in [folded] as minutes since midnight.
  static int? findTime(String folded) {
    for (final m in _time.allMatches(folded)) {
      final minutes = _minutes(m[1]!, m[2]!, m[3]);
      if (minutes != null) return minutes;
    }
    return null;
  }

  /// Parses a template `time` group.
  static int? parseTime(String text) =>
      findTime(SmsTextNormalizerImpl.fold(text).trim());

  /// Year inference (CHK050): the current year, or the previous year when
  /// that date would be more than one day after [now].
  static int inferYear(int month, int day, DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (tomorrow.year > now.year) return now.year;
    final isAfter =
        month > tomorrow.month ||
        (month == tomorrow.month && day > tomorrow.day);
    return isAfter ? now.year - 1 : now.year;
  }

  /// `may` without a year, followed by a verb, is the modal verb (`a fee
  /// of EGP 10 may apply`), not the month.
  static final RegExp _modalVerbAfter = RegExp(
    r'^ (?:apply|applies|be|been|have|not|vary|change|incur|take|occur|'
    r'differ|charge|reflect|include|appear)(?![a-z])',
  );

  static bool _modalMay(String folded, RegExpMatch m) {
    if (m[2] != 'may' || m[3] != null) return false;
    final end = m.end + 12 > folded.length ? folded.length : m.end + 12;
    return _modalVerbAfter.hasMatch(folded.substring(m.end, end));
  }

  static bool _yearlessContext(String folded, int start, int end) {
    final before = folded.substring(start < 12 ? 0 : start - 12, start);
    if (_dateKeywordBefore.hasMatch(before)) return true;
    final after = folded.substring(
      end,
      end + 9 > folded.length ? folded.length : end + 9,
    );
    return RegExp(r'^(?: at)? \d{1,2}:\d{2}').hasMatch(after);
  }

  static DateRead? _numeric(
    String first,
    String second,
    String? yearText,
    DateOrder order,
    DateTime now,
    int start,
    int end,
  ) {
    final a = int.parse(first);
    final b = int.parse(second);
    final day = order == DateOrder.dayMonth ? a : b;
    final month = order == DateOrder.dayMonth ? b : a;
    return _withYear(day, month, yearText, now, start, end);
  }

  static DateRead? _named(
    String dayText,
    String monthName,
    String? yearText,
    DateTime now,
    int start,
    int end,
  ) {
    final month = _months[monthName];
    if (month == null) return null;
    return _withYear(int.parse(dayText), month, yearText, now, start, end);
  }

  static DateRead? _withYear(
    int day,
    int month,
    String? yearText,
    DateTime now,
    int start,
    int end,
  ) {
    if (yearText == null) {
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      final year = inferYear(month, day, now);
      return _build(year, month, day, start, end, yearInferred: true);
    }
    var year = int.parse(yearText);
    if (yearText.length == 2) year += 2000;
    return _build(year, month, day, start, end);
  }

  static DateRead? _build(
    int year,
    int month,
    int day,
    int start,
    int end, {
    bool yearInferred = false,
  }) {
    if (year < 1900 || year > 2100) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return DateRead(date, yearInferred: yearInferred, start: start, end: end);
  }

  static int? _minutes(String hourText, String minuteText, String? suffix) {
    var hour = int.parse(hourText);
    final minute = int.parse(minuteText);
    if (suffix != null) {
      if (hour < 1 || hour > 12) return null;
      final pm =
          suffix == 'pm' ||
          suffix == 'p.m.' ||
          suffix == 'م' ||
          suffix.startsWith('مساء');
      if (pm && hour != 12) hour += 12;
      if (!pm && hour == 12) hour = 0;
    }
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }
}

/// A date found in text: date-only local midnight.
class DateRead {
  const DateRead(
    this.date, {
    required this.yearInferred,
    required this.start,
    required this.end,
  });

  final DateTime date;

  /// The year was not stated (FR-036): the field is inferred.
  final bool yearInferred;
  final int start;
  final int end;
}
