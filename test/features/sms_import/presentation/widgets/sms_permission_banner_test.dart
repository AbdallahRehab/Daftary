import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/presentation/widgets/sms_permission_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_harness.dart';

/// T123 — `SmsPermissionBanner` (ui-contract §3.7): one test per state, the
/// restricted guidance, the paste fallback in every state, RTL/LTR and
/// light/dark. The banner never prompts: its actions are callbacks.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<Map<String, int>> pumpBanner(
    WidgetTester tester,
    SmsPermissionStatus status, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    final taps = <String, int>{};
    void count(String name) => taps[name] = (taps[name] ?? 0) + 1;
    await pumpSmsPage(
      tester,
      Scaffold(
        body: ListView(
          children: [
            SmsPermissionBanner(
              status: status,
              onPaste: () => count('paste'),
              onAllow: () => count('allow'),
              onOpenAppInfo: () => count('appInfo'),
              onShowMeHow: () => count('showMeHow'),
            ),
          ],
        ),
      ),
      locale: locale,
      theme: theme,
    );
    return taps;
  }

  for (final status in [
    SmsPermissionStatus.granted,
    SmsPermissionStatus.unavailable,
  ]) {
    testWidgets('${status.name} renders nothing', (tester) async {
      await pumpBanner(tester, status);
      expect(find.byType(TextButton), findsNothing);
      expect(find.text(en.smsImportPermissionPasteInstead), findsNothing);
    });
  }

  testWidgets('denied: explanation, Allow and the paste fallback', (
    tester,
  ) async {
    final taps = await pumpBanner(tester, SmsPermissionStatus.denied);
    expect(find.text(en.smsImportPermissionDeniedBanner), findsOneWidget);
    await tester.tap(find.text(en.smsImportPermissionAllow));
    await tester.tap(find.text(en.smsImportPermissionPasteInstead));
    expect(taps, {'allow': 1, 'paste': 1});
  });

  testWidgets('permanently denied: Open App info and paste', (tester) async {
    final taps = await pumpBanner(
      tester,
      SmsPermissionStatus.permanentlyDenied,
    );
    expect(find.text(en.smsImportPermissionPermanentBanner), findsOneWidget);
    expect(find.text(en.smsImportPermissionAllow), findsNothing);
    await tester.tap(find.text(en.smsImportPermissionOpenAppInfo));
    await tester.tap(find.text(en.smsImportPermissionPasteInstead));
    expect(taps, {'appInfo': 1, 'paste': 1});
  });

  testWidgets('restricted: the "may be blocking" copy, Show me how, paste', (
    tester,
  ) async {
    final taps = await pumpBanner(
      tester,
      SmsPermissionStatus.restrictedBlocked,
    );
    expect(find.text(en.smsImportRestrictedBanner), findsOneWidget);
    await tester.tap(find.text(en.smsImportPermissionShowMeHow));
    await tester.tap(find.text(en.smsImportPermissionPasteInstead));
    expect(taps, {'showMeHow': 1, 'paste': 1});
  });

  testWidgets('revoked: pending items stay; Turn on again, App info, paste', (
    tester,
  ) async {
    final taps = await pumpBanner(tester, SmsPermissionStatus.revoked);
    expect(find.text(en.smsImportPermissionRevokedBanner), findsOneWidget);
    await tester.tap(find.text(en.smsImportPermissionTurnOnAgain));
    await tester.tap(find.text(en.smsImportPermissionOpenAppInfo));
    await tester.tap(find.text(en.smsImportPermissionPasteInstead));
    expect(taps, {'allow': 1, 'appInfo': 1, 'paste': 1});
  });

  testWidgets('Show me how opens the numbered steps with App info', (
    tester,
  ) async {
    var appInfo = 0;
    await pumpSmsPage(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showRestrictedGuidanceSheet(
              context,
              onOpenAppInfo: () => appInfo++,
              onPaste: () {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final step in [
      en.smsImportRestrictedStep1,
      en.smsImportRestrictedStep2,
      en.smsImportRestrictedStep3,
      en.smsImportRestrictedStep4,
    ]) {
      expect(find.text(step), findsOneWidget);
    }
    expect(find.text(en.smsImportPermissionPasteInstead), findsOneWidget);
    await tester.tap(find.text(en.smsImportPermissionOpenAppInfo));
    await tester.pumpAndSettle();
    expect(appInfo, 1);
    expect(find.text(en.smsImportRestrictedStep1), findsNothing);
  });

  testWidgets('the restricted steps use Western digits in Arabic', (
    tester,
  ) async {
    final ar = lookupAppLocalizations(const Locale('ar'));
    for (final step in [
      ar.smsImportRestrictedStep1,
      ar.smsImportRestrictedStep2,
      ar.smsImportRestrictedStep3,
      ar.smsImportRestrictedStep4,
    ]) {
      expect(step, matches(RegExp(r'^[1-4]\.')));
      expect(step, isNot(matches(RegExp('[٠-٩]'))));
    }
    expect(ar.smsImportRestrictedBanner, isNot(contains('محظور بالتأكيد')));
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('${locale.name} ${theme.name}: every state renders', (
        tester,
      ) async {
        for (final status in SmsPermissionStatus.values) {
          await pumpBanner(
            tester,
            status,
            locale: locale.locale,
            theme: theme.theme,
          );
          expect(tester.takeException(), isNull);
        }
        expectTapTargets(tester, find.byType(SmsPermissionBanner));
      });
    }
  }
}
