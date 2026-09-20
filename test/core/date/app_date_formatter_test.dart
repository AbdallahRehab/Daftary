import 'package:daftary/core/date/app_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final date = DateTime(2026, 3, 15);

  // In the real app, `flutter_localizations`' delegate loading initializes
  // `intl`'s date symbol data as a side effect of the first locale
  // resolution. A plain unit test never triggers that, so it's done
  // explicitly here — the same thing `DateFormat` needs regardless of
  // which locale is under test.
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar_u_nu_latn');
  });

  group('AppDateFormatter', () {
    test('formats under the en locale', () {
      final formatted = AppDateFormatter(locale: 'en').format(date);
      expect(formatted, isNotEmpty);
      expect(RegExp(r'[٠-٩]').hasMatch(formatted), isFalse);
    });

    test('formats under the ar locale with Western digits (FR-011)', () {
      final formatted = AppDateFormatter(locale: 'ar').format(date);
      expect(formatted, isNotEmpty);
      expect(RegExp(r'[٠-٩]').hasMatch(formatted), isFalse);
      expect(RegExp(r'[0-9]').hasMatch(formatted), isTrue);
    });

    test('en and ar both encode the same calendar date', () {
      final en = AppDateFormatter(locale: 'en').format(date);
      final ar = AppDateFormatter(locale: 'ar').format(date);
      expect(en, contains('2026'));
      expect(en, contains('15'));
      expect(ar, contains('2026'));
      expect(ar, contains('15'));
    });
  });
}
