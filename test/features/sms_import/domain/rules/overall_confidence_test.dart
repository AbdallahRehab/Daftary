import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/rules/overall_confidence.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T028: the confidence calibration table (parser-contract §6,
/// FR-039 to FR-042). Written before the implementation.
void main() {
  FieldConfidence high() => FieldConfidence.read(FieldConfidenceLevel.high);
  FieldConfidence medium() => FieldConfidence.read(FieldConfidenceLevel.medium);
  FieldConfidence low() => FieldConfidence.read(FieldConfidenceLevel.low);
  const inferred = FieldConfidence.inferred();

  Map<SmsField, FieldConfidence> fields({
    FieldConfidence? amount,
    FieldConfidence? currency,
    FieldConfidence? direction,
    FieldConfidence? date,
    Map<SmsField, FieldConfidence> extra = const {},
  }) => {
    SmsField.amount: ?amount,
    SmsField.currency: ?currency,
    SmsField.direction: ?direction,
    SmsField.date: ?date,
    ...extra,
  };

  final allHigh = fields(
    amount: high(),
    currency: high(),
    direction: high(),
    date: high(),
  );

  final table =
      <
        ({
          String name,
          Map<SmsField, FieldConfidence> fields,
          bool capMedium,
          OverallConfidence expected,
        })
      >[
        (
          name: 'all required fields read high -> high',
          fields: allHigh,
          capMedium: false,
          expected: OverallConfidence.high,
        ),
        (
          name: 'lowest read level wins: one medium -> medium',
          fields: fields(
            amount: high(),
            currency: medium(),
            direction: high(),
            date: high(),
          ),
          capMedium: false,
          expected: OverallConfidence.medium,
        ),
        (
          name: 'lowest read level wins: one low -> low',
          fields: fields(
            amount: low(),
            currency: high(),
            direction: high(),
            date: high(),
          ),
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'an inferred required field caps at medium (FR-039)',
          fields: fields(
            amount: high(),
            currency: inferred,
            direction: high(),
            date: high(),
          ),
          capMedium: false,
          expected: OverallConfidence.medium,
        ),
        (
          name: 'an inferred date with a low read stays low',
          fields: fields(
            amount: low(),
            currency: high(),
            direction: high(),
            date: inferred,
          ),
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'generic, paste and share cap at medium (FR-041, FR-020)',
          fields: allHigh,
          capMedium: true,
          expected: OverallConfidence.medium,
        ),
        (
          name: 'the cap never raises a low',
          fields: fields(
            amount: low(),
            currency: high(),
            direction: high(),
            date: high(),
          ),
          capMedium: true,
          expected: OverallConfidence.low,
        ),
        (
          name: 'absent amount -> low (D-C1)',
          fields: fields(currency: high(), direction: high(), date: high()),
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'absent currency -> low',
          fields: fields(amount: high(), direction: high(), date: high()),
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'absent direction (unset) -> low',
          fields: fields(amount: high(), currency: high(), date: high()),
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'absent date -> low',
          fields: fields(amount: high(), currency: high(), direction: high()),
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'paste without date or currency is always Low',
          fields: fields(amount: high(), direction: high()),
          capMedium: true,
          expected: OverallConfidence.low,
        ),
        (
          name: 'paste without date is always Low',
          fields: fields(amount: high(), currency: high(), direction: high()),
          capMedium: true,
          expected: OverallConfidence.low,
        ),
        (
          name: 'paste without currency is always Low',
          fields: fields(amount: high(), direction: high(), date: high()),
          capMedium: true,
          expected: OverallConfidence.low,
        ),
        (
          name: 'nothing at all -> low',
          fields: const {},
          capMedium: false,
          expected: OverallConfidence.low,
        ),
        (
          name: 'optional fields never lower the overall',
          fields: {
            ...allHigh,
            SmsField.merchant: low(),
            SmsField.cardLast4: low(),
            SmsField.time: inferred,
          },
          capMedium: false,
          expected: OverallConfidence.high,
        ),
        (
          name: 'every required field inferred -> medium',
          fields: fields(
            amount: inferred,
            currency: inferred,
            direction: inferred,
            date: inferred,
          ),
          capMedium: false,
          expected: OverallConfidence.medium,
        ),
      ];

  group('overallConfidence', () {
    for (final row in table) {
      test(row.name, () {
        expect(
          overallConfidence(row.fields, capMedium: row.capMedium),
          row.expected,
        );
      });
    }

    test('never returns high when capped, for every combination', () {
      final options = [high(), medium(), low(), inferred, null];
      for (final a in options) {
        for (final c in options) {
          for (final d in options) {
            for (final t in options) {
              final result = overallConfidence(
                fields(amount: a, currency: c, direction: d, date: t),
                capMedium: true,
              );
              expect(result, isNot(OverallConfidence.high));
            }
          }
        }
      }
    });
  });

  group('confidenceCapsAtMedium', () {
    test('generic profile caps whatever the source', () {
      for (final source in SmsSource.values) {
        expect(confidenceCapsAtMedium(isGeneric: true, source: source), isTrue);
      }
    });

    test('paste and share cap; scan and catch-up of a bank do not', () {
      expect(
        confidenceCapsAtMedium(isGeneric: false, source: SmsSource.paste),
        isTrue,
      );
      expect(
        confidenceCapsAtMedium(isGeneric: false, source: SmsSource.share),
        isTrue,
      );
      expect(
        confidenceCapsAtMedium(isGeneric: false, source: SmsSource.inboxScan),
        isFalse,
      );
      expect(
        confidenceCapsAtMedium(isGeneric: false, source: SmsSource.catchUpScan),
        isFalse,
      );
    });
  });
}
