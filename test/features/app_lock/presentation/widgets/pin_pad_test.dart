import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/app_lock/presentation/widgets/lockout_countdown_banner.dart';
import 'package:daftary/features/app_lock/presentation/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T034/T054 — the PIN pad and the lockout countdown banner.
void main() {
  Future<List<String>> pumpPad(
    WidgetTester tester, {
    bool enabled = true,
    Locale locale = const Locale('en'),
  }) async {
    final submitted = <String>[];
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: PinPad(enabled: enabled, onSubmitted: submitted.add),
          ),
        ),
      ),
    );
    return submitted;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.byKey(Key('pin_pad.digit.$digit')));
      await tester.pump();
    }
  }

  IconButton submitButton(WidgetTester tester) => tester.widget<IconButton>(
    find.descendant(
      of: find.byKey(const Key('pin_pad.submit')),
      matching: find.byType(IconButton),
    ),
  );

  testWidgets('submit enables at 4 digits, caps at 6, then clears', (
    tester,
  ) async {
    final submitted = await pumpPad(tester);
    await type(tester, '123');
    expect(submitButton(tester).onPressed, isNull);
    await type(tester, '45678');
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('pin_pad.submit')));
    await tester.pump();
    expect(submitted, ['123456']);
    expect(submitButton(tester).onPressed, isNull); // cleared
  });

  testWidgets('delete removes the last digit', (tester) async {
    final submitted = await pumpPad(tester);
    await type(tester, '12345');
    await tester.tap(find.byKey(const Key('pin_pad.delete')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pin_pad.submit')));
    expect(submitted, ['1234']);
  });

  testWidgets('a disabled pad ignores every key', (tester) async {
    final submitted = await pumpPad(tester, enabled: false);
    await type(tester, '123456');
    expect(submitButton(tester).onPressed, isNull);
    expect(submitted, isEmpty);
  });

  testWidgets('keeps the phone keypad order under RTL', (tester) async {
    await pumpPad(tester, locale: const Locale('ar'));
    final one = tester.getCenter(find.byKey(const Key('pin_pad.digit.1')));
    final three = tester.getCenter(find.byKey(const Key('pin_pad.digit.3')));
    expect(one.dx, lessThan(three.dx));
  });

  test('countdown formats m:ss in an LTR isolate', () {
    expect(
      LockoutCountdownBanner.formatRemaining(const Duration(seconds: 30)),
      '\u20660:30\u2069',
    );
    expect(
      LockoutCountdownBanner.formatRemaining(
        const Duration(minutes: 4, seconds: 5),
      ),
      '\u20664:05\u2069',
    );
  });
}
