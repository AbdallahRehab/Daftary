import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:flutter_test/flutter_test.dart';

// 023 T044: masking before sealing (FR-031a, research Decision 7,
// parser-contract §3). Every number below is invented; the mobile-shaped
// values are the spec's own examples.
void main() {
  const masker = SmsMaskerImpl();

  group('long digit groups keep only the last four', () {
    test('a contiguous 16-digit run', () {
      expect(
        masker.mask('Card 0000111122223333 used'),
        'Card ••••••••••••3333 used',
      );
    });

    test('groups joined by single spaces', () {
      expect(
        masker.mask('Card 0000 1111 2222 3333 used'),
        'Card •••• •••• •••• 3333 used',
      );
    });

    test('groups joined by single hyphens', () {
      expect(masker.mask('0000-1111-2222-3333'), '••••-••••-••••-3333');
    });

    test('Arabic-Indic digits keep their own glyphs', () {
      expect(
        masker.mask('بطاقة ٠٠٠٠ ١١١١ ٢٢٢٢ ٣٣٣٣'),
        'بطاقة •••• •••• •••• ٣٣٣٣',
      );
    });

    test('Eastern Arabic-Indic digits', () {
      expect(masker.mask('۰۰۰۰۱۱۱۱۲۲۲۲۳۳۳۳'), '••••••••••••۳۳۳۳');
    });

    test('mixed digit scripts in one group', () {
      expect(masker.mask('٠٠٠٠ 1111 ۲۲۲۲ 3333'), '•••• •••• •••• 3333');
    });

    test('exactly 12 digits is masked; 11 non-mobile digits are not', () {
      expect(masker.mask('Ref 123456789012'), 'Ref ••••••••9012');
      expect(masker.mask('Ref 12345678901'), 'Ref 12345678901');
    });

    test('a double space or other separator breaks the group', () {
      expect(masker.mask('000011  112222'), '000011  112222');
      expect(masker.mask('000011/112222'), '000011/112222');
    });

    test('a spaced card holding a mobile-shaped block leaves only four '
        'digits visible', () {
      expect(masker.mask('0000 0101 2345 6789'), '•••• •••• •••• 6789');
    });
  });

  group('threshold', () {
    test('a profile may lower it', () {
      expect(masker.mask('Acc 1234567890', threshold: 10), 'Acc ••••••7890');
      expect(masker.mask('Acc 1234567890'), 'Acc 1234567890');
    });

    test('it is never raised above 12', () {
      expect(
        masker.mask('Ref 000011112222', threshold: 16),
        'Ref ••••••••2222',
      );
    });
  });

  group('Egyptian mobile numbers', () {
    test('contiguous local form', () {
      expect(masker.mask('to 01012345678.'), 'to •••••••5678.');
    });

    test('spaced and hyphenated local forms', () {
      expect(masker.mask('to 010 1234 5678 now'), 'to ••• •••• 5678 now');
      expect(masker.mask('to 010-1234-5678'), 'to •••-••••-5678');
    });

    test('international forms', () {
      expect(masker.mask('+201012345678'), '+••••••••5678');
      expect(masker.mask('+20 10 1234 5678'), '+•• •• •••• 5678');
      expect(masker.mask('201512345678'), '••••••••5678');
    });

    test('every mobile prefix 010, 011, 012, 015', () {
      for (final prefix in ['010', '011', '012', '015']) {
        expect(masker.mask('${prefix}12345678'), '•••••••5678');
      }
      // 013 is not a mobile prefix and 11 digits are under the threshold.
      expect(masker.mask('01312345678'), '01312345678');
    });

    test('Arabic-Indic and Eastern Arabic-Indic forms', () {
      expect(masker.mask('إلى ٠١٠١٢٣٤٥٦٧٨'), 'إلى •••••••٥٦٧٨');
      expect(masker.mask('إلى ٠١٠ ١٢٣٤ ٥٦٧٨'), 'إلى ••• •••• ٥٦٧٨');
      expect(masker.mask('۰۱۰۱۲۳۴۵۶۷۸'), '•••••••۵۶۷۸');
    });

    test('an amount-adjacent run masks only the mobile', () {
      expect(masker.mask('EGP 1500 01012345678'), 'EGP 1500 •••••••5678');
      expect(masker.mask('جنيه ١٥٠٠ ٠١٠١٢٣٤٥٦٧٨'), 'جنيه ١٥٠٠ •••••••٥٦٧٨');
    });
  });

  group('left untouched', () {
    test('grouped amounts', () {
      for (final amount in [
        'EGP 1,234,567.50',
        '1 234 567',
        '١٬٢٣٤٬٥٦٧٫٥٠',
        '987,654,321,000.00',
      ]) {
        expect(masker.mask(amount), amount);
      }
    });

    test('already-masked tokens', () {
      for (final token in ['XXXX1234', '****1234', '...1234', 'xx1234']) {
        expect(masker.mask('Card $token'), 'Card $token');
      }
    });

    test('dates, times and short numbers', () {
      const text = 'on 04/03/2026 10:15 ref 998877';
      expect(masker.mask(text), text);
    });

    test('text without digits, and the empty string', () {
      expect(masker.mask('تم خصم مبلغ من حسابك'), 'تم خصم مبلغ من حسابك');
      expect(masker.mask(''), '');
    });
  });

  test('keeps every non-digit character and the length', () {
    const text = '\u{200F}Card 0000 1111 2222 3333 at Example\nto 01012345678';
    final masked = masker.mask(text);
    expect(masked.length, text.length);
    expect(masked, startsWith('\u{200F}Card '));
    expect(masked, contains('Example\nto '));
  });

  test('never leaves more than four digits of a long run', () {
    final digits = RegExp(
      r'[0-9\u{0660}-\u{0669}\u{06F0}-\u{06F9}]',
      unicode: true,
    );
    const text = 'a 0000 1111 2222 3333 b 01012345678 c 123456789012345678';
    final masked = masker.mask(text);
    expect(digits.allMatches(masked).length, 12);
  });
}
