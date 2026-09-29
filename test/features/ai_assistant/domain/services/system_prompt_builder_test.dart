import 'package:daftary/features/ai_assistant/domain/services/system_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = SystemPromptBuilder();
  final prompt = builder.build(currentDate: DateTime(2026, 9, 4, 23, 59));

  test('includes the current date (zero-padded) and month', () {
    expect(prompt, contains('2026-09-04'));
    expect(prompt, contains('current month is 2026-09'));
  });

  test('is deterministic for the same date and changes with the date', () {
    expect(builder.build(currentDate: DateTime(2026, 9, 4)), prompt);
    final other = builder.build(currentDate: DateTime(2027, 1, 15));
    expect(other, contains('2027-01-15'));
    expect(other, isNot(contains('2026-09-04')));
  });

  group('grounding (T036)', () {
    test('narrate only tool-returned values', () {
      expect(prompt, contains('Narrate only tool-returned values'));
    });

    test('never invent or compute a figure', () {
      expect(prompt, contains('Never invent'));
      expect(prompt, contains('compute a figure yourself'));
    });

    test('honest decline on foundData=false, not a zero', () {
      expect(prompt, contains('"foundData": false'));
      expect(prompt, contains('Do not present it as zero'));
    });

    test('explains minor units as a notation change only', () {
      expect(prompt, contains('MinorUnits'));
      expect(prompt, contains('minorUnitsPerMajorUnit'));
      expect(prompt, contains('never a calculation'));
    });

    test('names each result\'s own currency and never adds across '
        'currencies (018)', () {
      expect(prompt, contains('"currency"'));
      expect(prompt, contains('never add amounts in different currencies'));
      expect(prompt, contains('exchangeRateMissing'));
    });
  });

  test('011: savings goals carry their own currency; an incomplete total '
      'is disclosed; a what-if never changes the goal', () {
    expect(prompt, contains('each savings goal, carries its own "currency"'));
    expect(prompt, contains('"isTotalIncomplete"'));
    expect(prompt, contains('never changes the goal'));
  });

  group('boundaries (T049)', () {
    test('declines create/edit/delete of records', () {
      expect(prompt, contains('read-only'));
      for (final verb in ['create', 'edit', 'delete']) {
        expect(prompt, contains(verb));
      }
    });

    test('declines personalized investment advice', () {
      expect(prompt, contains('investment'));
      expect(prompt, contains('does not offer investment advice'));
    });

    test('asks a clarifying question when ambiguous', () {
      expect(prompt, contains('ambiguous'));
      expect(prompt, contains('clarifying question'));
    });
  });

  test('answers in the language of the question (Arabic/English)', () {
    expect(prompt, contains('Arabic'));
    expect(prompt, contains('English'));
    expect(prompt, contains('language of the user'));
  });
}
