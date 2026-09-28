import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_arguments.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIPeriodResolver', () {
    final resolver = AIPeriodResolver.withClock(
      () => DateTime(2026, 3, 10, 18),
    );

    test("presets resolve exactly as 007's DateRange presets", () {
      expect(
        resolver.resolve({
          AIToolArgs.preset: AIPeriodPresets.thisMonth,
        }).toNullable(),
        DateRange.thisMonth(DateTime(2026, 3, 10)),
      );
      expect(
        resolver.resolve({
          AIToolArgs.preset: AIPeriodPresets.lastMonth,
        }).toNullable(),
        DateRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 28)),
      );
      expect(
        resolver.monthBeforeLast(),
        DateRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
      );
      expect(resolver.currentMonth(), '2026-03');
    });

    test('custom: inclusive start/end dates', () {
      expect(
        resolver.resolve({
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '2025-12-01',
          AIToolArgs.endDate: '2026-01-15',
        }).toNullable(),
        DateRange(start: DateTime(2025, 12, 1), end: DateTime(2026, 1, 15)),
      );
    });

    for (final (label, period) in <(String, Map<String, Object?>)>[
      ('no preset', {}),
      ('unknown preset', {AIToolArgs.preset: 'thisYear'}),
      (
        'custom without endDate',
        {
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '2026-01-01',
        },
      ),
      (
        'impossible date',
        {
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '2026-02-30',
          AIToolArgs.endDate: '2026-03-01',
        },
      ),
      (
        'wrong format',
        {
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '01/02/2026',
          AIToolArgs.endDate: '2026-03-01',
        },
      ),
      (
        'end before start',
        {
          AIToolArgs.preset: AIPeriodPresets.custom,
          AIToolArgs.startDate: '2026-03-02',
          AIToolArgs.endDate: '2026-03-01',
        },
      ),
    ]) {
      test('rejects $label with a ValidationFailure', () {
        expect(
          resolver.resolve(period).getLeft().toNullable(),
          isA<ValidationFailure>(),
        );
      });
    }
  });

  group('matchByName', () {
    String id(String s) => s;

    test('exact normalized match wins', () {
      final m = matchByName('  AHMED ', ['Ahmed', 'Ahmed Ali'], id);
      expect(m, isA<AINameMatched<String>>());
      expect((m as AINameMatched<String>).item, 'Ahmed');
    });

    test('a single partial match resolves (its real name is returned)', () {
      final m = matchByName('mona', ['Mona Hassan', 'Ahmed'], id);
      expect((m as AINameMatched<String>).item, 'Mona Hassan');
    });

    test('several partial matches are ambiguous', () {
      final m = matchByName('ahmed', ['Ahmed Ali', 'Ahmed Samir'], id);
      expect((m as AINameAmbiguous<String>).candidateNames, [
        'Ahmed Ali',
        'Ahmed Samir',
      ]);
    });

    test('no match / blank query → not found', () {
      expect(
        matchByName('Khaled', ['Ahmed'], id),
        isA<AINameNotFound<String>>(),
      );
      expect(matchByName('  ', ['Ahmed'], id), isA<AINameNotFound<String>>());
    });
  });
}
