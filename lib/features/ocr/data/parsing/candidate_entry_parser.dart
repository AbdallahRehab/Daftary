import 'package:injectable/injectable.dart';

import '../../../../core/money/numeral_parser.dart';
import '../../domain/entities/candidate_entry.dart';
import '../../domain/entities/field_confidence.dart';
import '../../domain/entities/parsed_scan.dart';
import '../../domain/repositories/text_recognition_service.dart';

/// Turns recognized page text into reviewable candidate entries.
///
/// Deterministic text-pattern parsing, never an LLM (research.md Decision 3,
/// constitution Principle VIII/IX): every field this produces is traceable to
/// a specific token on a specific line, which is exactly what lets
/// [FieldConfidence] record honest provenance instead of a made-up score.
///
/// Pure Dart by construction — no plugin type, no `dart:io`, no Flutter
/// import — so the whole rule set is exercisable from a fixture table with no
/// device and no ML runtime (research.md Decision 6).
@lazySingleton
class CandidateEntryParser {
  const CandidateEntryParser();

  /// The page ceiling from FR-024. Lines past this are ignored rather than
  /// producing a review screen no one can realistically get through.
  static const int maxEntries = 50;

  /// Characters that separate a name from its amount on a handwritten list.
  /// Stripped from the edges of the name so "Ahmed — " reads as "Ahmed".
  static const String _separatorChars = '-—:.|=,\t ';

  /// Latin words that mark a line as bookkeeping furniture rather than a
  /// person's row. Matched whole-word, so "Total" is noise but "Totally" is
  /// not.
  static const Set<String> _noiseWords = {
    'total',
    'totals',
    'subtotal',
    'sum',
    'grand',
    'name',
    'names',
    'amount',
    'amounts',
    'المجموع',
    'مجموع',
    'الاجمالي',
    'اجمالي',
    'الجمله',
    'الجملة',
    'الاسم',
    'اسم',
    'المبلغ',
    'مبلغ',
  };

  /// Occasion-type cues (008's occasion kinds, in both languages). A line
  /// carrying one and no amount is offered as the batch's occasion heading.
  static const Set<String> _latinOccasionWords = {
    'wedding',
    'engagement',
    'birth',
    'graduation',
    'funeral',
    'condolence',
    'condolences',
    'other',
    'occasion',
  };

  static const List<String> _arabicOccasionWords = [
    'زفاف',
    'فرح',
    'افراح',
    'خطوبه',
    'خطوبة',
    'سبوع',
    'تخرج',
    'عزاء',
  ];

  /// A leading list index: the "1." in "1. Ahmed 500". Left in place it would
  /// be read as the line's amount, which is the single most damaging
  /// misparse this feature can make.
  static final RegExp _listIndexPattern = RegExp(r'^\d{1,2}\s*[.)]\s+');

  /// DD/MM/YYYY and friends. The lookarounds keep it from biting a chunk out
  /// of a longer digit run.
  static final RegExp _datePattern = RegExp(
    r'(?<!\d)(\d{1,2})\s*[/-]\s*(\d{1,2})\s*[/-]\s*(\d{2,4})(?!\d)',
  );

  /// A fully numeric amount word: optional thousands groups, optional decimal
  /// part of at most two places (piastres — a third place is noise, not
  /// money).
  static final RegExp _amountPattern = RegExp(
    r'^\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?$|^\d+(?:\.\d{1,2})?$',
  );

  /// Glyphs the recognizer routinely confuses with digits. Their presence in
  /// an amount is what downgrades that read to [FieldConfidenceLevel.low]
  /// (research.md Decision 4): the value is usable, but it is the first thing
  /// the reviewer should look at.
  static const Map<String, String> _confusableGlyphs = {
    'O': '0',
    'o': '0',
    'D': '0',
    'l': '1',
    'I': '1',
    'i': '1',
    '|': '1',
    'S': '5',
    's': '5',
    'B': '8',
    'Z': '2',
  };

  /// Parses one recognized page.
  ///
  /// [generateId] is injected rather than called for internally so entry ids
  /// are deterministic under test; [now] stamps `createdAt`; [scanCreatedAt]
  /// only resolves two-digit years (see [_parseDateAt]).
  ParsedScan parse(
    RecognizedText recognized, {
    required String scanId,
    required DateTime scanCreatedAt,
    required DateTime now,
    required String Function() generateId,
  }) {
    final lines = recognized.lines;
    final scans = [for (final line in lines) _scanLine(line, scanCreatedAt)];

    // Whole-page hints are read once, before any line becomes an entry, so a
    // line spent as a heading or a bare date is not also spent as a row
    // (research.md Decision 3).
    final batchDate = scans
        .map((scan) => scan.date)
        .firstWhere((date) => date != null, orElse: () => null);
    final headingIndex = _findHeadingIndex(scans);

    final entries = <CandidateEntry>[];
    for (var i = 0; i < scans.length; i++) {
      if (entries.length >= maxEntries) break;
      if (i == headingIndex) continue;
      final scan = scans[i];
      if (!scan.producesEntry) continue;
      entries.add(
        _buildEntry(
          scan,
          scanId: scanId,
          batchDate: batchDate,
          now: now,
          id: generateId(),
        ),
      );
    }

    return ParsedScan(
      entries: entries,
      occasionHeading: headingIndex == null
          ? null
          : scans[headingIndex].rawText.trim(),
      batchDate: batchDate,
    );
  }

  CandidateEntry _buildEntry(
    _LineScan scan, {
    required String scanId,
    required DateTime? batchDate,
    required DateTime now,
    required String id,
  }) {
    final lineLevel = scan.level;
    return CandidateEntry(
      id: id,
      scanId: scanId,
      status: CandidateEntryStatus.pendingReview,
      personName: scan.name,
      // A name carrying digits is a name the recognizer smeared into the
      // amount column; flag it rather than pretend it read cleanly.
      personNameConfidence: FieldConfidence.read(
        scan.nameHasDigits ? FieldConfidenceLevel.low : lineLevel,
      ),
      amountMinorUnits: scan.amountMinorUnits,
      amountConfidence: scan.amountMinorUnits == null
          ? const FieldConfidence.inferred()
          : FieldConfidence.read(
              scan.amountWasConfusable ? FieldConfidenceLevel.low : lineLevel,
            ),
      // Never guessed. A plain list line carries no directional cue at all,
      // and a wrong direction is a wrong sign on someone's balance
      // (research.md Decision 3, FR-005).
      direction: null,
      directionConfidence: const FieldConfidence.inferred(),
      // A page-level date applied here was derived, not read on this line, so
      // it stays inferred even though it has a value (data-model.md's Rule).
      date: scan.date ?? batchDate,
      dateConfidence: scan.date == null
          ? const FieldConfidence.inferred()
          : FieldConfidence.read(lineLevel),
      rawOcrText: scan.rawText,
      createdAt: now,
    );
  }

  /// The first line that looks like a page title: no amount on it, and either
  /// the top line of the page or an explicit occasion word.
  int? _findHeadingIndex(List<_LineScan> scans) {
    var seenContent = false;
    for (var i = 0; i < scans.length; i++) {
      final scan = scans[i];
      if (scan.isBlank) continue;
      final isFirstContentLine = !seenContent;
      seenContent = true;
      if (scan.isNoise || scan.isBareDate) continue;
      if (scan.amountMinorUnits != null) continue;
      if (scan.name.isEmpty) continue;
      if (isFirstContentLine || scan.hasOccasionWord) return i;
    }
    return null;
  }

  _LineScan _scanLine(RecognizedLine line, DateTime scanCreatedAt) {
    final raw = line.text;
    final normalized = NumeralParser.toWesternDigits(raw).trim();
    if (normalized.isEmpty) {
      return _LineScan.blank(raw, line.confidence);
    }
    if (_isNoise(normalized)) {
      return _LineScan.noise(raw, line.confidence);
    }

    var work = normalized.replaceFirst(_listIndexPattern, '');

    DateTime? date;
    final dateMatch = _datePattern.firstMatch(work);
    if (dateMatch != null) {
      date = _parseDateAt(dateMatch, scanCreatedAt);
      if (date != null) {
        work = work.replaceRange(dateMatch.start, dateMatch.end, ' ');
      }
    }

    final hasSeparator = RegExp('[${RegExp.escape('-—:|=')}\t]').hasMatch(work);
    final words = _wordsOf(work);

    int? amount;
    var amountConfusable = false;
    for (final index in _amountCandidateIndexes(words)) {
      final parsed = _parseAmount(words[index]);
      if (parsed == null) continue;
      amount = parsed.minorUnits;
      amountConfusable = parsed.usedConfusableGlyph;
      words.removeAt(index);
      break;
    }

    final name = _trimSeparators(words.join(' '));
    final leftoverDigits = RegExp(r'\d').hasMatch(name);

    return _LineScan(
      rawText: raw,
      level: line.confidence,
      name: name,
      nameHasDigits: leftoverDigits,
      amountMinorUnits: amount,
      amountWasConfusable: amountConfusable,
      date: date,
      isBareDate: date != null && name.isEmpty && amount == null,
      hasOccasionWord: _hasOccasionWord(normalized),
      // A bare name with nothing amount-shaped about it is prose — a note in
      // the margin, a stray word — not a row someone meant as an entry. It
      // only becomes an (amount-less) candidate when the line still shows the
      // shape of one: a separator, a date, or digits the parser could not
      // read as money.
      hasAmountSlot: hasSeparator || date != null || leftoverDigits,
    );
  }

  /// Word positions worth testing as the amount, nearest the edges first:
  /// real lists put the number at one end, never buried mid-name.
  Iterable<int> _amountCandidateIndexes(List<String> words) sync* {
    if (words.isEmpty) return;
    yield words.length - 1;
    if (words.length > 1) yield 0;
  }

  List<String> _wordsOf(String work) {
    // Split separators off their neighbours, but only where they are acting
    // as separators: "Ahmed:500" is two tokens, while "Abd-Allah" is one name
    // and "150.50" is one amount.
    final spaced = work
        .replaceAll(RegExp('[—:|=\t]'), ' ')
        .replaceAllMapped(RegExp(r'([^\d\s])-(?=\d)'), (m) => '${m[1]} ')
        .replaceAllMapped(RegExp(r'(\d)-(?=[^\d\s])'), (m) => '${m[1]} ');
    return spaced
        .split(RegExp(r'\s+'))
        .map(_trimSeparators)
        .where((word) => word.isNotEmpty)
        .toList();
  }

  String _trimSeparators(String value) {
    var start = 0;
    var end = value.length;
    while (start < end && _separatorChars.contains(value[start])) {
      start++;
    }
    while (end > start && _separatorChars.contains(value[end - 1])) {
      end--;
    }
    return value.substring(start, end);
  }

  /// Reads one word as an amount in minor units (piastres), repairing
  /// digit-shaped letters and reporting whether it had to.
  _AmountRead? _parseAmount(String word) {
    if (!RegExp(r'\d').hasMatch(word)) return null;

    var usedConfusable = false;
    final repaired = StringBuffer();
    for (final char in word.split('')) {
      final replacement = _confusableGlyphs[char];
      if (replacement != null) {
        usedConfusable = true;
        repaired.write(replacement);
      } else {
        repaired.write(char);
      }
    }

    final candidate = repaired.toString();
    if (!_amountPattern.hasMatch(candidate)) return null;

    final parts = candidate.replaceAll(',', '').split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    final piastres = int.tryParse(fraction);
    if (piastres == null) return null;
    return _AmountRead(whole * 100 + piastres, usedConfusable);
  }

  /// Day-first, per Egyptian convention on paper lists.
  DateTime? _parseDateAt(RegExpMatch match, DateTime scanCreatedAt) {
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) {
      // "5/9/26" on a page scanned in 2026 means 2026, not year 26.
      year = scanCreatedAt.year - (scanCreatedAt.year % 100) + year;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  bool _isNoise(String normalized) {
    final words = _letterWordsOf(normalized);
    if (words.isEmpty) return false;
    return words.every(_noiseWords.contains);
  }

  bool _hasOccasionWord(String normalized) {
    final folded = _foldArabic(normalized.toLowerCase());
    for (final arabic in _arabicOccasionWords) {
      if (folded.contains(_foldArabic(arabic))) return true;
    }
    // Whole-word for Latin: "other" is an occasion cue, "mother" is a name.
    return _letterWordsOf(normalized).any(_latinOccasionWords.contains);
  }

  List<String> _letterWordsOf(String value) {
    return _foldArabic(value.toLowerCase())
        .split(RegExp(r'[^\p{L}]+', unicode: true))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Folds the alef/teh-marbuta spelling variants people and recognizers use
  /// interchangeably, so keyword matching does not hinge on a hamza.
  String _foldArabic(String value) => value
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}

class _AmountRead {
  const _AmountRead(this.minorUnits, this.usedConfusableGlyph);

  final int minorUnits;
  final bool usedConfusableGlyph;
}

/// Everything the parser worked out about one line, before page-level hints
/// decide whether that line becomes an entry.
class _LineScan {
  const _LineScan({
    required this.rawText,
    required this.level,
    required this.name,
    required this.nameHasDigits,
    required this.amountMinorUnits,
    required this.amountWasConfusable,
    required this.date,
    required this.isBareDate,
    required this.hasOccasionWord,
    required this.hasAmountSlot,
  }) : isBlank = false,
       isNoise = false;

  _LineScan.blank(this.rawText, this.level)
    : name = '',
      nameHasDigits = false,
      amountMinorUnits = null,
      amountWasConfusable = false,
      date = null,
      isBareDate = false,
      hasOccasionWord = false,
      hasAmountSlot = false,
      isBlank = true,
      isNoise = false;

  _LineScan.noise(this.rawText, this.level)
    : name = '',
      nameHasDigits = false,
      amountMinorUnits = null,
      amountWasConfusable = false,
      date = null,
      isBareDate = false,
      hasOccasionWord = false,
      hasAmountSlot = false,
      isBlank = false,
      isNoise = true;

  final String rawText;
  final FieldConfidenceLevel level;
  final String name;
  final bool nameHasDigits;
  final int? amountMinorUnits;
  final bool amountWasConfusable;
  final DateTime? date;
  final bool isBareDate;
  final bool hasOccasionWord;
  final bool hasAmountSlot;
  final bool isBlank;
  final bool isNoise;

  bool get producesEntry {
    if (isBlank || isNoise || isBareDate) return false;
    if (name.isEmpty) return false;
    return amountMinorUnits != null || hasAmountSlot;
  }
}
