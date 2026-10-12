import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/presentation/widgets/bidi_text.dart';
import 'package:daftary/features/sms_import/presentation/widgets/import_type_selector.dart';
import 'package:daftary/features/sms_import/presentation/widgets/pending_import_card.dart';
import 'package:daftary/features/sms_import/presentation/widgets/sms_import_labels.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/widget_harness.dart';

/// T080 — `BidiText`, `PendingImportCard` and `ImportTypeSelector`:
/// semantics, 48 dp targets and RTL/LTR. Every value is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: theme ?? buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BidiText', () {
    test('isolates LTR tokens and auto-direction names', () {
      expect(BidiIsolate.ltr('•••• 1234'), '\u2066•••• 1234\u2069');
      expect(BidiIsolate.auto('متجر'), '\u2068متجر\u2069');
    });

    testWidgets('renders isolated text', (tester) async {
      await pump(tester, const BidiText.ltr('EGP 5.00'));
      expect(find.text('\u2066EGP 5.00\u2069'), findsOneWidget);
    });
  });

  group('SmsImportLabels.bank', () {
    final ar = lookupAppLocalizations(const Locale('ar'));

    test('registered banks show their localized name, not the id', () {
      expect(SmsImportLabels.bank(en, 'nbe'), 'National Bank of Egypt');
      expect(SmsImportLabels.bank(en, 'banque_misr'), 'Banque Misr');
      expect(SmsImportLabels.bank(en, 'qnb'), 'QNB Alahli');
      expect(SmsImportLabels.bank(ar, 'banque_misr'), 'بنك مصر');
      expect(SmsImportLabels.bank(ar, 'instapay'), 'إنستاباي');
      for (final id in [
        'nbe',
        'banque_misr',
        'cib',
        'qnb',
        'banque_du_caire',
        'aaib',
        'instapay',
      ]) {
        for (final l10n in [en, ar]) {
          final name = SmsImportLabels.bank(l10n, id);
          expect(name, isNot(BidiIsolate.ltr(id.toUpperCase())));
          expect(name, isNot(l10n.smsImportBankName('other')));
        }
      }
    });

    test('an unknown id keeps its isolated code; generic is unrecognized', () {
      expect(SmsImportLabels.bank(en, 'newbank'), BidiIsolate.ltr('NEWBANK'));
      expect(
        SmsImportLabels.bank(en, 'generic'),
        en.smsImportPendingUnknownBank,
      );
      expect(SmsImportLabels.bank(en, ''), en.smsImportPendingUnknownBank);
    });
  });

  group('PendingImportCard', () {
    testWidgets('one semantics node, stable key, tap, never the raw text', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pump(
        tester,
        PendingImportCard(
          item: buildPendingImport(cardLast4: '0042'),
          onTap: () => taps++,
        ),
      );
      final card = find.byKey(const ValueKey('pending_import_card_pending-1'));
      expect(card, findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(en.smsImportSemanticsCardEnding('0042'))),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      await tester.tap(card);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('confidence and warnings carry icon plus text', (tester) async {
      await pump(
        tester,
        PendingImportCard(
          item: buildPendingImport(
            amount: null,
            warnings: {SmsWarning.possibleDuplicate},
            suggestedType: SuggestedRecordType.ignore,
          ),
          onTap: () {},
        ),
      );
      expect(find.text(en.ocrConfidenceHigh), findsOneWidget);
      expect(find.text(en.smsImportPendingPossibleDuplicate), findsOneWidget);
      expect(find.text(en.smsImportPendingIgnoreSuggested), findsOneWidget);
      expect(find.text(en.smsImportPendingAmountNeedsCheck), findsOneWidget);
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('renders in ${locale.name} / ${theme.name}', (
          tester,
        ) async {
          await pump(
            tester,
            PendingImportCard(item: buildPendingImport(), onTap: () {}),
            locale: locale.locale,
            theme: theme.theme,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('ImportTypeSelector', () {
    testWidgets('offers exactly expense, income, given, received', (
      tester,
    ) async {
      await pump(tester, ImportTypeSelector(value: null, onChanged: (_) {}));
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text(en.financeTypeExpense), findsOneWidget);
      expect(find.text(en.financeTypeIncome), findsOneWidget);
      expect(find.text(en.directionGiven), findsOneWidget);
      expect(find.text(en.directionReceived), findsOneWidget);
      expect(find.text(en.repaymentLabel), findsNothing);
      expect(find.text(en.smsImportReviewChooseType), findsOneWidget);
    });

    testWidgets('selection, 48 dp targets, and change callback', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      SuggestedRecordType? picked;
      await pump(
        tester,
        ImportTypeSelector(
          value: SuggestedRecordType.given,
          onChanged: (t) => picked = t,
        ),
        locale: const Locale('ar'),
      );
      expectTapTargets(tester, find.byType(ImportTypeSelector));
      final given = tester.getSemantics(
        find.byKey(const ValueKey('import_type_given')),
      );
      expect(given.flagsCollection.isSelected, Tristate.isTrue);
      await tester.tap(find.byKey(const ValueKey('import_type_income')));
      expect(picked, SuggestedRecordType.income);
      handle.dispose();
    });
  });
}
