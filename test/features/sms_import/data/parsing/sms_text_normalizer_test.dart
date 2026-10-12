import 'package:daftary/features/sms_import/data/parsing/sms_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

// 023 T042: the parser's normalization pipeline (parser-contract §3).
// Steps 1-3 build `forDisplay`; steps 4-5 (Arabic folding, Latin
// lower-casing) apply to `forMatching` only.
void main() {
  const normalizer = SmsTextNormalizerImpl();

  group('step 1: bidi and zero-width characters', () {
    test('strips every bidi control and zero-width character', () {
      const marks = [
        '\u{200E}', '\u{200F}', '\u{061C}', //
        '\u{202A}', '\u{202B}', '\u{202C}', '\u{202D}', '\u{202E}',
        '\u{2066}', '\u{2067}', '\u{2068}', '\u{2069}',
        '\u{200B}', '\u{200C}', '\u{200D}', '\u{FEFF}',
      ];
      final input = 'EGP${marks.join()} 150.00';
      final result = normalizer.normalize(input);
      expect(result.forDisplay, 'EGP 150.00');
      expect(result.forMatching, 'egp 150.00');
    });

    test('a mark between two words does not glue or split them', () {
      final result = normalizer.normalize(
        'تم\u{200F} خصم\u{2067} مبلغ\u{2069}',
      );
      expect(result.forDisplay, 'تم خصم مبلغ');
    });
  });

  group('step 2: whitespace', () {
    test('collapses runs, line breaks, tabs and no-break spaces', () {
      final result = normalizer.normalize(
        '  Purchase\t\tat\n\nExample\u{00A0}Cafe\r\n on\u{202F}04/03  ',
      );
      expect(result.forDisplay, 'Purchase at Example Cafe on 04/03');
    });

    test('whitespace-only input normalizes to empty', () {
      final result = normalizer.normalize(' \n\t\u{200F}\u{00A0} ');
      expect(result.forDisplay, isEmpty);
      expect(result.forMatching, isEmpty);
    });
  });

  group('step 3: digits and separators', () {
    test('ASCII digits are unchanged', () {
      expect(normalizer.normalize('1,234.50').forDisplay, '1,234.50');
    });

    test('Arabic-Indic digits U+0660-0669 become Western', () {
      expect(normalizer.normalize('٠١٢٣٤٥٦٧٨٩').forDisplay, '0123456789');
    });

    test('Eastern Arabic-Indic digits U+06F0-06F9 become Western', () {
      expect(normalizer.normalize('۰۱۲۳۴۵۶۷۸۹').forDisplay, '0123456789');
    });

    test('Arabic decimal and thousands separators map to . and ,', () {
      expect(normalizer.normalize('١٬٢٣٤٫٥٠').forDisplay, '1,234.50');
    });

    test('digits are normalized in forMatching too', () {
      expect(
        normalizer.normalize('مبلغ ١٥٠ جنيه').forMatching,
        'مبلغ 150 جنيه',
      );
    });
  });

  group('step 4: Arabic folding (forMatching only)', () {
    test('strips tatweel and harakat', () {
      final result = normalizer.normalize('شـــراءٌ مَبْلَغ');
      expect(result.forMatching, 'شراء مبلغ');
      expect(result.forDisplay, 'شـــراءٌ مَبْلَغ');
    });

    test('folds alef forms to bare alef', () {
      expect(normalizer.normalize('أإآٱ').forMatching, 'اااا');
    });

    test('folds alef maqsura to ya and ta marbuta to ha', () {
      expect(normalizer.normalize('لدى بطاقة').forMatching, 'لدي بطاقه');
    });

    test('folds hamza seats on waw and ya', () {
      expect(normalizer.normalize('مؤسسة رئيسية').forMatching, 'موسسه رييسيه');
    });

    test('the display text keeps the original letters', () {
      const text = 'إيداع راتب لدى البنك الأهلى';
      final result = normalizer.normalize(text);
      expect(result.forDisplay, text);
      expect(result.forMatching, 'ايداع راتب لدي البنك الاهلي');
    });
  });

  group('step 5: lower-casing (forMatching only)', () {
    test('lower-cases Latin letters', () {
      final result = normalizer.normalize('Purchase AT Example CAFE');
      expect(result.forMatching, 'purchase at example cafe');
      expect(result.forDisplay, 'Purchase AT Example CAFE');
    });

    test('lower-cases accented Latin letters', () {
      expect(normalizer.normalize('CAFÉ').forMatching, 'café');
    });
  });

  group('index map', () {
    test('maps every folded index back to the display text', () {
      const text = 'شـراء  لدى Example Cafe';
      final folded = normalizer.normalizeWithMap(text);
      expect(folded.forMatching, 'شراء لدي example cafe');
      final start = folded.forMatching.indexOf('example');
      final end = folded.forMatching.length;
      expect(folded.displaySpan(start, end), 'Example Cafe');
      final arabicEnd = folded.forMatching.indexOf(' ');
      expect(folded.displaySpan(0, arabicEnd), 'شـراء');
    });

    test('forMatching and forDisplay agree with normalize()', () {
      const text = '  \u{200F}تم خصم ١٬٥٠٠٫٠٠ ج.م\nمن بطاقتك  ';
      final plain = normalizer.normalize(text);
      final mapped = normalizer.normalizeWithMap(text);
      expect(mapped.forMatching, plain.forMatching);
      expect(mapped.forDisplay, plain.forDisplay);
    });
  });

  test('is deterministic and idempotent on its own output', () {
    const text = 'Your card ****0000 was debited with EGP ١٬٥٠٠٫٠٠';
    final once = normalizer.normalize(text);
    final twice = normalizer.normalize(once.forDisplay);
    expect(twice.forDisplay, once.forDisplay);
    expect(normalizer.normalize(text), once);
  });

  test('toString never prints the text', () {
    final result = normalizer.normalize('EGP 987654.32 Example Cafe');
    expect(result.toString(), isNot(contains('987654')));
    expect(result.toString(), isNot(contains('Cafe')));
  });
}
