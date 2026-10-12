import 'sms_currency_table.dart';
import 'sms_date_reader.dart';
import 'sms_parser_registry.dart';
import 'sms_text_normalizer.dart';

/// The kind of envelope header a line is (spikes/S5 rule classes E1-E3).
enum EnvelopeHeader {
  none,

  /// E1: a registered sender ID or a short-code / phone-number shape.
  sender,

  /// E1, weaker: an unregistered upper-case alphanumeric sender shape
  /// (at most 11 characters, the SMS sender-ID limit). Accepted only
  /// directly before a date/time line.
  senderShape,

  /// E2: only a date and/or time stamp.
  stamp,

  /// E3: a sender and a stamp on one line, in either order.
  senderStamp,
}

/// The app-level envelope table for paste and share (FR-017a,
/// parser-contract §3 step 0, research Spike addendum).
///
/// UNVERIFIED: the S5 device spike has not run. These rules implement the
/// designated defaults (classes E0-E5) with the conservative safety rules:
/// - E1-E3 apply only in header position (the first one or two lines of a
///   chunk, or of a message whose chunk began with the same header shape);
/// - a line holding a currency token, a profile signature or a profile
///   `messageStart` is never stripped;
/// - an unknown shape is left alone: under-stripping is the safe failure
///   (duplicate tiers 2-3 still catch the duplicate), over-stripping could
///   drop body text.
///
/// Shapes are matched on a shadow copy (no bidi or zero-width marks,
/// Western digits, folded, lower-case); the kept text is the original.
class SmsEnvelopeRules {
  const SmsEnvelopeRules._();

  /// Bumped on any rule change. Stored fingerprints never change with it:
  /// hashes are immutable on the row.
  static const int version = 1;

  static final RegExp _separator = RegExp(r'^[\-—–_=*•~ ]+$');
  static final RegExp _numericSender = RegExp(r'^\+?\d[\d \-]{1,16}\d:?$');
  static final RegExp _upperSender = RegExp(r'^[A-Z][A-Z0-9._\-]{1,10}:?$');
  static final RegExp _numericDate = RegExp(
    r'^\d{1,4}[/.\-]\d{1,2}(?:[/.\-]\d{2,4})?$',
  );
  static final RegExp _time = RegExp(r'^\d{1,2}:\d{2}(?::\d{2})?$');
  static final RegExp _shortNumber = RegExp(r'^\d{1,4}$');
  static final RegExp _bracketSenderName = RegExp(r'^[^\d:\[\]]{1,30}$');

  static const Set<String> _suffixes = {
    'am', 'pm', 'a.m.', 'p.m.', 'ص', 'م', 'صباحا', 'مساء', 'مساءا', //
  };
  static final Set<String> _weekdays = {
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', //
    'sunday', 'mon', 'tue', 'tues', 'wed', 'thu', 'thur', 'thurs', 'fri',
    'sat', 'sun',
    for (final day in const [
      'السبت', 'الأحد', 'الإثنين', 'الاثنين', 'الثلاثاء', 'الأربعاء', //
      'الخميس', 'الجمعة',
    ])
      SmsTextNormalizerImpl.fold(day),
  };
  static final Set<String> _relative = {
    'today',
    'yesterday',
    SmsTextNormalizerImpl.fold('اليوم'),
    SmsTextNormalizerImpl.fold('أمس'),
  };
  static const Set<String> _joiners = {'-', '·', '|', 'at', '@'};

  static final Set<String> _months = SmsDateReader.foldedMonthNames.toSet();
  static final List<String> _twoWordMonths = [
    for (final m in _months)
      if (m.contains(' ')) m,
  ];

  /// A line that is empty after removing whitespace and invisible marks.
  static bool isBlank(String line) =>
      SmsTextNormalizerImpl.displayForm(line).isEmpty;

  /// E5: three or more of `- — – _ = * • ~` (spaces allowed): a boundary.
  static bool isSeparator(String line) {
    final shadow = SmsTextNormalizerImpl.displayForm(line);
    if (!_separator.hasMatch(shadow)) return false;
    return shadow.replaceAll(' ', '').length >= 3;
  }

  /// Whether a folded line must never be stripped (safety rule 2).
  static bool isProtected(
    String folded, {
    required SmsParserRegistry registry,
  }) {
    if (SmsCurrencyTable.containsMarker(folded)) return true;
    for (final profile in registry.profiles) {
      if (profile.signatures.any((s) => s.matches(folded))) return true;
      if (profile.messageStart?.hasMatch(folded) ?? false) return true;
    }
    return false;
  }

  /// The header class of one line (E1-E3).
  static EnvelopeHeader classify(
    String line, {
    required SmsParserRegistry registry,
  }) {
    final display = SmsTextNormalizerImpl.displayForm(line);
    if (display.isEmpty) return EnvelopeHeader.none;
    final folded = SmsTextNormalizerImpl.fold(display);
    if (isProtected(folded, registry: registry)) return EnvelopeHeader.none;
    final sender = _senderKind(display, registry);
    if (sender != EnvelopeHeader.none) return sender;
    if (isStamp(folded)) return EnvelopeHeader.stamp;
    // E3: a sender token first or last, the rest a stamp.
    final tokens = display.split(' ');
    if (tokens.length >= 2) {
      final first = tokens.first;
      final rest = tokens.sublist(1).join(' ');
      if (_senderKind(first, registry) != EnvelopeHeader.none &&
          isStamp(SmsTextNormalizerImpl.fold(rest))) {
        return EnvelopeHeader.senderStamp;
      }
      final last = tokens.last;
      final head = tokens.sublist(0, tokens.length - 1).join(' ');
      if (_senderKind(last, registry) != EnvelopeHeader.none &&
          isStamp(SmsTextNormalizerImpl.fold(head))) {
        return EnvelopeHeader.senderStamp;
      }
    }
    return EnvelopeHeader.none;
  }

  /// E2: a folded line made only of date, time, weekday, relative-day and
  /// joiner tokens, with at least one date, time or relative day.
  static bool isStamp(String folded) {
    var text = folded.replaceAll('،', ' ').replaceAll(',', ' ');
    var hasMonth = false;
    for (final month in _twoWordMonths) {
      if (text.contains(month)) {
        text = text.replaceAll(month, ' § ');
        hasMonth = true;
      }
    }
    final tokens = text
        .split(' ')
        .map((t) => t.endsWith(':') ? t.substring(0, t.length - 1) : t)
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return false;
    for (final t in tokens) {
      if (t == '§' || _months.contains(t)) hasMonth = true;
    }
    var anchor = hasMonth;
    var previousWasTime = false;
    for (final t in tokens) {
      final isTime = _time.hasMatch(t);
      if (isTime || _numericDate.hasMatch(t) || _relative.contains(t)) {
        anchor = true;
      } else if (_suffixes.contains(t)) {
        if (!previousWasTime) return false;
      } else if (t == '§' || _months.contains(t)) {
        // month name
      } else if (_weekdays.contains(t) || _joiners.contains(t)) {
        // weekday or joiner
      } else if (_shortNumber.hasMatch(t)) {
        if (!hasMonth) return false;
      } else {
        return false;
      }
      previousWasTime = isTime;
    }
    return anchor;
  }

  /// E4: strips a bracketed prefix `[<stamp>] <SENDER>:` or `[<SENDER>] `
  /// at the start of [line]. Returns the kept body text (possibly empty
  /// when the body continues on the next line), or `null` when the line
  /// has no such prefix.
  static String? stripBracketPrefix(
    String line, {
    required SmsParserRegistry registry,
  }) {
    var open = 0;
    while (open < line.length &&
        (SmsTextNormalizerImpl.isInvisibleMark(line.codeUnitAt(open)) ||
            SmsTextNormalizerImpl.isWhitespace(line.codeUnitAt(open)))) {
      open++;
    }
    if (open >= line.length || line.codeUnitAt(open) != 0x5B) return null;
    final close = line.indexOf(']', open + 1);
    if (close < 0 || close - open - 1 > 40 || close == open + 1) return null;
    final content = SmsTextNormalizerImpl.displayForm(
      line.substring(open + 1, close),
    );
    final foldedContent = SmsTextNormalizerImpl.fold(content);
    if (isProtected(foldedContent, registry: registry)) return null;
    final rest = line.substring(close + 1).replaceFirst(RegExp(r'^[ \t]+'), '');
    if (isStamp(foldedContent)) {
      final sender = RegExp(r'^([^:\n]{1,30}):[ \t]*').firstMatch(rest);
      if (sender == null) return null;
      final senderFolded = SmsTextNormalizerImpl.fold(sender[1]!);
      if (isProtected(senderFolded, registry: registry)) return null;
      return rest.substring(sender.end);
    }
    final isSender =
        _senderKind(content, registry) != EnvelopeHeader.none ||
        _bracketSenderName.hasMatch(content);
    if (!isSender || rest.trim().isEmpty) return null;
    return rest;
  }

  static EnvelopeHeader _senderKind(
    String display,
    SmsParserRegistry registry,
  ) {
    final trimmed = display.endsWith(':')
        ? display.substring(0, display.length - 1)
        : display;
    final canonical = SmsParserRegistry.canonicalSender(trimmed);
    if (canonical != null && registry.allowedSenders.contains(canonical)) {
      return EnvelopeHeader.sender;
    }
    if (_numericSender.hasMatch(display)) {
      final digits = display.replaceAll(RegExp(r'[^0-9]'), '').length;
      if (digits >= 3 && digits <= 15) return EnvelopeHeader.sender;
    }
    if (_upperSender.hasMatch(display)) return EnvelopeHeader.senderShape;
    return EnvelopeHeader.none;
  }
}
