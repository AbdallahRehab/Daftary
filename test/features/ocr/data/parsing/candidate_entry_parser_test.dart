import 'package:daftary/features/ocr/data/parsing/candidate_entry_parser.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/entities/parsed_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = CandidateEntryParser();
  final scanCreatedAt = DateTime.utc(2026, 5, 20, 9);
  final now = DateTime.utc(2026, 5, 20, 9, 30);

  /// Builds a single-block page. One block is enough for every rule under
  /// test: the parser reads `RecognizedText.lines`, which flattens blocks in
  /// reading order anyway.
  RecognizedText page(
    List<String> lines, {
    FieldConfidenceLevel level = FieldConfidenceLevel.medium,
  }) {
    return RecognizedText(
      blocks: [
        RecognizedBlock(
          lines: [
            for (final line in lines)
              RecognizedLine(text: line, confidence: level),
          ],
        ),
      ],
    );
  }

  ParsedScan run(
    List<String> lines, {
    FieldConfidenceLevel level = FieldConfidenceLevel.medium,
  }) {
    var counter = 0;
    return parser.parse(
      page(lines, level: level),
      scanId: 'scan-1',
      scanCreatedAt: scanCreatedAt,
      now: now,
      generateId: () => 'entry-${++counter}',
    );
  }

  group('line fixtures (research.md Decision 3)', () {
    final fixtures = <_Fixture>[
      const _Fixture(
        'clean printed English name and trailing amount',
        ['Ahmed Hassan 500'],
        [_Expected('Ahmed Hassan', 50000)],
      ),
      const _Fixture(
        'amount leads the line instead of trailing it',
        ['500 محمد سعيد'],
        [_Expected('محمد سعيد', 50000)],
      ),
      const _Fixture(
        'dash separator between name and amount',
        ['Ahmed - 500'],
        [_Expected('Ahmed', 50000)],
      ),
      const _Fixture(
        'colon separator with no surrounding spaces',
        ['Ahmed:500'],
        [_Expected('Ahmed', 50000)],
      ),
      const _Fixture(
        'Arabic-Indic numerals are equivalent to Western ones',
        ['أحمد ٥٠٠'],
        [_Expected('أحمد', 50000)],
      ),
      const _Fixture(
        'mixed Arabic and English text on one line',
        ['Ahmed محمد 250'],
        [_Expected('Ahmed محمد', 25000)],
      ),
      const _Fixture(
        'decimal amount keeps its piastres',
        ['Sara 150.50'],
        [_Expected('Sara', 15050)],
      ),
      const _Fixture(
        'single decimal place pads to piastres',
        ['Sara 150.5'],
        [_Expected('Sara', 15050)],
      ),
      const _Fixture(
        'thousands separator',
        ['Khaled 1,500'],
        [_Expected('Khaled', 150000)],
      ),
      const _Fixture(
        'thousands separator with decimals',
        ['Khaled 12,000.25'],
        [_Expected('Khaled', 1200025)],
      ),
      const _Fixture(
        'leading list index is stripped, not read as the amount',
        ['1. Ahmed 500'],
        [_Expected('Ahmed', 50000)],
      ),
      const _Fixture(
        'list index written with a bracket',
        ['2) Mona 300'],
        [_Expected('Mona', 30000)],
      ),
      const _Fixture(
        'character-confusion in the amount still parses',
        ['Ahmed 1O00'],
        [_Expected('Ahmed', 100000)],
      ),
      const _Fixture(
        'another confusable glyph shape',
        ['Mona 5S0'],
        [_Expected('Mona', 55000)],
      ),
      const _Fixture(
        'a total line is bookkeeping furniture, not a person',
        ['Ahmed 500', 'Total 500'],
        [_Expected('Ahmed', 50000)],
      ),
      const _Fixture(
        'an Arabic column header produces no entry',
        ['الاسم   المبلغ', 'أحمد ٥٠٠'],
        [_Expected('أحمد', 50000)],
      ),
      const _Fixture(
        'an Arabic total line produces no entry',
        ['أحمد ٥٠٠', 'المجموع ٥٠٠'],
        [_Expected('أحمد', 50000)],
      ),
      const _Fixture(
        'empty and whitespace-only lines are ignored',
        ['Ahmed 500', '', '   ', 'Mona 300'],
        [_Expected('Ahmed', 50000), _Expected('Mona', 30000)],
      ),
      _Fixture(
        'a standalone date becomes the batch date and no entry',
        const ['12/05/2026', 'Ahmed 500'],
        const [_Expected('Ahmed', 50000)],
        batchDate: DateTime(2026, 5, 12),
      ),
      _Fixture(
        'a two-digit year resolves against the scan year',
        const ['5-9-26', 'Ahmed 500'],
        const [_Expected('Ahmed', 50000)],
        batchDate: DateTime(2026, 9, 5),
      ),
      const _Fixture(
        'an occasion keyword heading becomes the heading, not an entry',
        ['فرح محمد', 'أحمد ٥٠٠'],
        [_Expected('أحمد', 50000)],
        heading: 'فرح محمد',
      ),
      const _Fixture(
        'the first non-empty line is offered as the heading',
        ['Kotb Family List', 'Ahmed 500'],
        [_Expected('Ahmed', 50000)],
        heading: 'Kotb Family List',
      ),
      const _Fixture(
        'a name with no amount still becomes a reviewable row',
        ['Ahmed 500', 'Mona -'],
        [_Expected('Ahmed', 50000), _Expected('Mona', null)],
      ),
      const _Fixture(
        'an amount with no name is dropped',
        ['Ahmed 500', '750'],
        [_Expected('Ahmed', 50000)],
      ),
      _Fixture(
        'a date on the row does not become its amount',
        const ['Ahmed 500 12/05/2026'],
        const [_Expected('Ahmed', 50000)],
        batchDate: DateTime(2026, 5, 12),
      ),
      const _Fixture(
        'three decimal places is noise, not money — the digits stay in the '
        'name for the reviewer to sort out',
        ['Ali 100', 'Ahmed 500.123'],
        [_Expected('Ali', 10000), _Expected('Ahmed 500.123', null)],
      ),
    ];

    for (final fixture in fixtures) {
      test(fixture.description, () {
        final parsed = run(fixture.lines);

        expect(
          parsed.entries.map((entry) => entry.personName).toList(),
          fixture.expected.map((e) => e.name).toList(),
        );
        expect(
          parsed.entries.map((entry) => entry.amountMinorUnits).toList(),
          fixture.expected.map((e) => e.amountMinorUnits).toList(),
        );
        expect(parsed.occasionHeading, fixture.heading);
        expect(parsed.batchDate, fixture.batchDate);
      });
    }
  });

  group('page-level rules', () {
    test('entries are capped at 50 lines (FR-024)', () {
      final lines = [for (var i = 1; i <= 80; i++) 'Person$i ${i * 10}'];

      final parsed = run(lines);

      expect(parsed.entries, hasLength(CandidateEntryParser.maxEntries));
      expect(parsed.entries.last.personName, 'Person50');
    });

    test('an entirely blank page parses to nothing', () {
      final parsed = run(['', '   ']);

      expect(parsed.entries, isEmpty);
      expect(parsed.occasionHeading, isNull);
      expect(parsed.batchDate, isNull);
    });

    test('ids come from the injected generator, in page order', () {
      final parsed = run(['Ahmed 500', 'Mona 300']);

      expect(parsed.entries.map((entry) => entry.id).toList(), [
        'entry-1',
        'entry-2',
      ]);
    });

    test('every entry carries the scan id, review status and raw line', () {
      final parsed = run(['  Ahmed - 500  ']);
      final entry = parsed.entries.single;

      expect(entry.scanId, 'scan-1');
      expect(entry.status, CandidateEntryStatus.pendingReview);
      expect(entry.editedAt, isNull);
      expect(entry.createdAt, now);
      // The untouched original, so review can compare it against the page.
      expect(entry.rawOcrText, '  Ahmed - 500  ');
    });

    test('a name-only row cannot be confirmed (FR-008)', () {
      final parsed = run(['Ahmed 500', 'Mona -']);

      expect(parsed.entries.last.amountMinorUnits, isNull);
      expect(
        parsed.entries.last.isConfirmEligible(null),
        isFalse,
        reason: 'no amount and no direction resolvable',
      );
    });

    test('the batch date fills in rows that carried no date of their own', () {
      final parsed = run(['12/05/2026', 'Ahmed 500']);

      expect(parsed.entries.single.date, DateTime(2026, 5, 12));
    });
  });

  group('confidence provenance (T052, data-model.md Rule)', () {
    test('direction is never guessed: always inferred, always null', () {
      final parsed = run(['Ahmed 500', '500 Mona', 'Khaled - 1,500']);

      for (final entry in parsed.entries) {
        expect(entry.direction, isNull);
        expect(entry.directionConfidence, const FieldConfidence.inferred());
        expect(entry.directionConfidence.level, FieldConfidenceLevel.none);
      }
    });

    test('directly read name and amount carry the line confidence', () {
      final parsed = run(['Ahmed 500'], level: FieldConfidenceLevel.high);
      final entry = parsed.entries.single;

      expect(entry.personNameConfidence.isRead, isTrue);
      expect(entry.personNameConfidence.level, FieldConfidenceLevel.high);
      expect(entry.amountConfidence.isRead, isTrue);
      expect(entry.amountConfidence.level, FieldConfidenceLevel.high);
    });

    test('a confusable amount is downgraded to a low read', () {
      final parsed = run(['Ahmed 1O00'], level: FieldConfidenceLevel.high);
      final entry = parsed.entries.single;

      expect(entry.amountConfidence.isRead, isTrue);
      expect(entry.amountConfidence.level, FieldConfidenceLevel.low);
      expect(entry.hasLowConfidenceField, isTrue);
      // The name beside it was read cleanly and keeps its own level.
      expect(entry.personNameConfidence.level, FieldConfidenceLevel.high);
    });

    test('a name smeared with digits is downgraded to a low read', () {
      final parsed = run([
        'Ali 100',
        'Ahmed 500.123',
      ], level: FieldConfidenceLevel.high);
      final entry = parsed.entries.last;

      expect(entry.personName, 'Ahmed 500.123');
      expect(entry.personNameConfidence.level, FieldConfidenceLevel.low);
    });

    test('a missing amount is inferred with no level, never a read', () {
      final parsed = run(['Ahmed 500', 'Mona -']);
      final entry = parsed.entries.last;

      expect(entry.amountMinorUnits, isNull);
      expect(entry.amountConfidence, const FieldConfidence.inferred());
      expect(entry.amountConfidence.isRead, isFalse);
      expect(entry.amountConfidence.level, FieldConfidenceLevel.none);
    });

    test('a date read on the row itself is a read', () {
      final parsed = run([
        'Ahmed 500 12/05/2026',
      ], level: FieldConfidenceLevel.high);
      final entry = parsed.entries.single;

      expect(entry.date, DateTime(2026, 5, 12));
      expect(entry.dateConfidence.isRead, isTrue);
      expect(entry.dateConfidence.level, FieldConfidenceLevel.high);
    });

    test('a page-level date applied to a row stays inferred — it was derived '
        'there, not read there', () {
      final parsed = run(['12/05/2026', 'Ahmed 500']);
      final entry = parsed.entries.single;

      expect(entry.date, DateTime(2026, 5, 12));
      expect(entry.dateConfidence, const FieldConfidence.inferred());
      expect(entry.dateConfidence.level, FieldConfidenceLevel.none);
    });

    test('a row with no date anywhere is left null and inferred', () {
      final parsed = run(['Ahmed 500']);
      final entry = parsed.entries.single;

      expect(entry.date, isNull);
      expect(entry.dateConfidence, const FieldConfidence.inferred());
    });

    test('no inferred field anywhere on a page ever carries a level', () {
      final parsed = run([
        'فرح محمد',
        '12/05/2026',
        'الاسم   المبلغ',
        '1. Ahmed 500',
        'Mona -',
        '500 خالد',
        'Total 800',
      ]);

      expect(parsed.entries, isNotEmpty);
      for (final entry in parsed.entries) {
        for (final confidence in [
          entry.personNameConfidence,
          entry.amountConfidence,
          entry.directionConfidence,
          entry.dateConfidence,
        ]) {
          if (confidence.isInferred) {
            expect(confidence.level, FieldConfidenceLevel.none);
          } else {
            expect(confidence.level, isNot(FieldConfidenceLevel.none));
          }
        }
      }
    });
  });
}

class _Fixture {
  const _Fixture(
    this.description,
    this.lines,
    this.expected, {
    this.heading,
    this.batchDate,
  });

  final String description;
  final List<String> lines;
  final List<_Expected> expected;
  final String? heading;
  final DateTime? batchDate;
}

class _Expected {
  const _Expected(this.name, this.amountMinorUnits);

  final String name;
  final int? amountMinorUnits;
}
