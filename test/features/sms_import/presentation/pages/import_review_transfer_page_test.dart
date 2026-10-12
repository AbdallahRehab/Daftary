import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/presentation/pages/import_review_page.dart';
import 'package:daftary/features/sms_import/presentation/widgets/bidi_text.dart';
import 'package:daftary/features/transactions/presentation/widgets/duplicate_warning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/review_harness.dart';
import '../../helpers/widget_harness.dart';

/// T140 (T138, T145) — the review page's transfer and people suggestions,
/// the Ignore hints, the ATM link to the cash preference, and the restore
/// (key loss) rendering. Every name and value is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late ReviewHarness harness;

  setUp(
    () => harness = ReviewHarness(
      people: [
        testPerson('person-1', 'Mona'),
        testPerson('person-2', 'Mona Adel'),
        testPerson('person-3', 'Karim'),
      ],
    ),
  );
  tearDown(() => harness.dispose());

  Future<void> pumpReview(
    WidgetTester tester,
    PendingSmsImport item, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(420 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    harness.repository.seed([item]);
    await pumpSmsPage(
      tester,
      ImportReviewPage(importId: item.id, cubit: harness.build()),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );
  }

  Finder byKey(String key) => find.byKey(ValueKey(key));

  PendingSmsImport transferIn(String counterparty, {String? personId}) =>
      buildPendingImport(
        kind: SmsKind.transferIn,
        direction: SmsDirection.credit,
        suggestedType: SuggestedRecordType.income,
        counterparty: counterparty,
        suggestedPersonId: personId,
        merchant: null,
        merchantKey: null,
      );

  group('people (FR-054, US7)', () {
    testWidgets('one exact match: the one-tap Received chip pre-selects the '
        'person; nobody is created', (tester) async {
      await pumpReview(tester, transferIn('Karim', personId: 'person-3'));
      expect(
        find.text(
          en.smsImportReviewRecordAsReceived(BidiIsolate.auto('Karim')),
        ),
        findsOne,
      );
      expect(byKey('import_review_choose_person'), findsNothing);
      await tester.tap(byKey('import_review_suggested_person'));
      await tester.pumpAndSettle();
      expect(byKey('import_review_suggested_person'), findsNothing);
      expect(find.text('Karim'), findsWidgets);
      expect(harness.people.people, hasLength(3));
    });

    testWidgets('several matches: "Choose who sent it" opens the existing '
        'similar-name choice; picking one creates nobody', (tester) async {
      await pumpReview(tester, transferIn('mona'));
      expect(byKey('import_review_suggested_person'), findsNothing);
      expect(
        find.textContaining(en.smsImportSuggestChoosePerson('received')),
        findsOneWidget,
      );
      await tester.tap(byKey('import_review_choose_person'));
      await tester.pumpAndSettle();
      expect(find.byType(DuplicateWarningSheet), findsOneWidget);
      expect(find.text('Mona Adel'), findsWidgets);
      await tester.tap(find.text(en.duplicateUseExisting).last);
      await tester.pumpAndSettle();
      expect(find.byType(DuplicateWarningSheet), findsNothing);
      expect(byKey('import_review_choose_person'), findsNothing);
      expect(harness.people.people, hasLength(3));
    });

    testWidgets('no match: Received shows the name in the search and the '
        '"nothing is created" line; Create is an explicit tap', (tester) async {
      await pumpReview(tester, transferIn('Example Sender'));
      expect(byKey('import_review_choose_person'), findsNothing);
      expect(byKey('import_review_suggested_person'), findsNothing);
      await tester.tap(find.text(en.directionReceived));
      await tester.pumpAndSettle();
      expect(byKey('import_review_person_not_in_list'), findsOneWidget);
      expect(harness.people.people, hasLength(3));
      final create = find.text(
        '${en.createPersonInlineAction} "Example Sender"',
      );
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(harness.people.people, hasLength(4));
      expect(byKey('import_review_person_not_in_list'), findsNothing);
    });
  });

  group('Ignore hints (FR-051a, FR-051c)', () {
    testWidgets('own-account: the Ignore hint and the warning line', (
      tester,
    ) async {
      await pumpReview(
        tester,
        buildPendingImport(
          kind: SmsKind.ownAccountTransfer,
          suggestedType: SuggestedRecordType.ignore,
          warnings: {SmsWarning.ownAccountSuggestedIgnore},
        ),
      );
      expect(find.text(en.smsImportSuggestHint('ignore')), findsOneWidget);
      expect(
        find.text(en.smsImportWarningText('ownAccountSuggestedIgnore')),
        findsOneWidget,
      );
      expect(byKey('import_review_cash_link'), findsNothing);
    });

    testWidgets('a deposit with no default: the choose hint', (tester) async {
      await pumpReview(
        tester,
        buildPendingImport(
          kind: SmsKind.otherDeposit,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.unset,
        ),
      );
      expect(find.text(en.smsImportSuggestHint('unset')), findsOneWidget);
      // Choosing a type removes the hint.
      await tester.tap(find.text(en.financeTypeIncome));
      await tester.pumpAndSettle();
      expect(byKey('import_review_suggest_hint'), findsNothing);
    });
  });

  group('ATM (FR-051b)', () {
    PendingSmsImport atm() => buildPendingImport(
      kind: SmsKind.atmWithdrawal,
      suggestedType: SuggestedRecordType.ignore,
      merchant: null,
      warnings: {SmsWarning.atmIgnoredByDefault},
    );

    testWidgets('preference off: one link line, Ignore suggested; the link '
        'opens the preference and the new default applies on return', (
      tester,
    ) async {
      await pumpReview(tester, atm());
      expect(find.text(en.smsImportSuggestCashLink('off')), findsOneWidget);
      // The link replaces the warning sentence: one line, not two.
      expect(
        find.text(en.smsImportWarningText('atmIgnoredByDefault')),
        findsNothing,
      );
      expect(find.text(en.smsImportSuggestHint('ignore')), findsOneWidget);
      await tester.tap(byKey('import_review_cash_link'));
      await tester.pumpAndSettle();
      expect(find.text('sms-settings-route'), findsOneWidget);

      await harness.settings.setCountCashWithdrawals(true);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportSuggestCashLink('on')), findsOneWidget);
      expect(byKey('import_review_suggest_hint'), findsNothing);
    });

    testWidgets('preference on: Expense is chosen', (tester) async {
      await harness.settings.setCountCashWithdrawals(true);
      await pumpReview(tester, atm());
      expect(find.text(en.smsImportSuggestCashLink('on')), findsOneWidget);
      expect(byKey('import_review_suggest_hint'), findsNothing);
    });
  });

  group('restore / key loss (T145, FR-062, FR-074a)', () {
    testWidgets('the fields stay; "Show original" ends disabled with its '
        'localized reason; Add still works', (tester) async {
      // Before the key loss is noticed the row still claims a stored
      // original; the fake has no blob, as after a restore.
      await pumpReview(
        tester,
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
      );
      expect(find.text('125.50'), findsOneWidget);
      // The header isolates the name (FR-091).
      expect(find.text(BidiIsolate.auto('Example Cafe')), findsWidgets);
      final show = find.text(en.smsImportReviewShowOriginal);
      await tester.ensureVisible(show);
      await tester.tap(show);
      await tester.pumpAndSettle();

      final tile = byKey('import_review_original_unavailable');
      expect(tile, findsOneWidget);
      expect(tester.widget<ListTile>(tile).enabled, isFalse);
      expect(find.text(en.smsImportErrorOriginalUnavailable), findsOneWidget);
      expect(byKey('import_review_original_text'), findsNothing);
      // Tapping the disabled row does nothing.
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(byKey('import_review_original_text'), findsNothing);

      final add = byKey('import_review_add');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(harness.repository.confirmCalls, hasLength(1));
    });

    testWidgets('in Arabic the reason is localized', (tester) async {
      final ar = lookupAppLocalizations(const Locale('ar'));
      await pumpReview(
        tester,
        buildPendingImport(hasRawText: false),
        locale: const Locale('ar'),
      );
      expect(find.text(ar.smsImportErrorOriginalUnavailable), findsOneWidget);
      expect(find.text(ar.smsImportReviewShowOriginal), findsOneWidget);
    });
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('${locale.name} / ${theme.name}: the people choice and '
          'the ATM link render', (tester) async {
        await pumpReview(
          tester,
          transferIn('mona'),
          locale: locale.locale,
          theme: theme.theme,
        );
        expect(byKey('import_review_choose_person'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectTapTargets(tester, find.byType(ImportReviewPage));
      });
    }
  }

  testWidgets('200% Arabic: the suggestion lines do not overflow', (
    tester,
  ) async {
    await pumpReview(
      tester,
      transferIn('mona'),
      locale: const Locale('ar'),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
