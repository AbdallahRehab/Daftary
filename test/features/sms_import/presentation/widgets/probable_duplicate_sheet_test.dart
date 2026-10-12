import 'package:daftary/core/design_system/imported_from_sms_label.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/presentation/widgets/duplicate_comparison_card.dart';
import 'package:daftary/features/sms_import/presentation/widgets/probable_duplicate_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_harness.dart';

/// T103 — `ProbableDuplicateSheet` and `DuplicateComparisonCard`: the two
/// sides, the text-only differences, the three outcomes, the announcement,
/// semantics, 48 dp targets, stacking at large text or narrow width, and
/// the RTL x LTR x light x dark matrix. Every value is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  DuplicateSide existing(AppLocalizations l10n) => DuplicateSide(
    title: l10n.smsImportDuplicateExisting,
    typeLabel: l10n.financeTypeExpense,
    amount: const Money.egp(12550),
    date: DateTime(2026, 3, 3),
    note: 'Example Cafe\nsecond line never shown',
    importedFromSms: true,
  );

  DuplicateSide incoming(AppLocalizations l10n) => DuplicateSide(
    title: l10n.smsImportDuplicateIncoming,
    typeLabel: l10n.financeTypeExpense,
    amount: const Money.egp(12550),
    date: DateTime(2026, 3, 4),
    sourceLabel: l10n.smsImportReviewSourceLabel('paste'),
  );

  /// Opens the sheet from a button and records what it returned.
  Future<List<ProbableDuplicateChoice?>> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
    Size size = const Size(420, 900),
    bool canAddAnyway = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final results = <ProbableDuplicateChoice?>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: theme ?? buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Center(
                child: TextButton(
                  onPressed: () async {
                    final a = existing(l10n);
                    final b = incoming(l10n);
                    results.add(
                      await showProbableDuplicateSheet(
                        context,
                        existing: a,
                        incoming: b,
                        phrases: duplicateComparisonPhrases(
                          l10n,
                          existing: a,
                          incoming: b,
                        ),
                        canAddAnyway: canAddAnyway,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  Finder sheet() => find.byKey(const ValueKey('probable_duplicate_sheet'));

  testWidgets('shows both sides with the text differences, the note\'s '
      'first line only and the imported label', (tester) async {
    await open(tester);
    expect(find.text(en.smsImportDuplicateTitle), findsOneWidget);
    expect(find.text(en.smsImportDuplicateMessage), findsOneWidget);
    expect(find.text(en.smsImportDuplicateExisting), findsOneWidget);
    expect(find.text(en.smsImportDuplicateIncoming), findsOneWidget);
    expect(find.textContaining('125.50'), findsNWidgets(2));
    expect(
      find.text(en.smsImportDuplicateNote('Example Cafe')),
      findsOneWidget,
    );
    expect(find.textContaining('second line'), findsNothing);
    expect(find.byType(ImportedFromSmsLabel), findsOneWidget);
    expect(find.text(en.smsImportReviewSourceLabel('paste')), findsOneWidget);
    // Differences in text, never colour alone.
    expect(find.text(en.smsImportDuplicateSameAmount), findsOneWidget);
    expect(find.text(en.smsImportDuplicateDaysApart(1)), findsOneWidget);
    expect(
      find.byKey(const ValueKey('probable_duplicate_side_by_side')),
      findsOneWidget,
    );
  });

  testWidgets('"It\'s the same, don\'t add" returns same', (tester) async {
    final results = await open(tester);
    await tester.tap(find.byKey(const ValueKey('probable_duplicate_same')));
    await tester.pumpAndSettle();
    expect(results, [ProbableDuplicateChoice.same]);
    expect(sheet(), findsNothing);
  });

  testWidgets('"It\'s different, add anyway" returns addAnyway', (
    tester,
  ) async {
    final results = await open(tester);
    await tester.tap(
      find.byKey(const ValueKey('probable_duplicate_add_anyway')),
    );
    await tester.pumpAndSettle();
    expect(results, [ProbableDuplicateChoice.addAnyway]);
  });

  testWidgets('an incomplete draft: "add anyway" is disabled, the rest '
      'still works', (tester) async {
    final results = await open(tester, canAddAnyway: false);
    final addAnyway = find.byKey(
      const ValueKey('probable_duplicate_add_anyway'),
    );
    await tester.tap(addAnyway, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(sheet(), findsOneWidget);
    expect(results, isEmpty);
    await tester.tap(find.byKey(const ValueKey('probable_duplicate_same')));
    await tester.pumpAndSettle();
    expect(results, [ProbableDuplicateChoice.same]);
  });

  testWidgets('Cancel, the scrim and back return null (item stays pending)', (
    tester,
  ) async {
    final results = await open(tester);
    await tester.tap(find.byKey(const ValueKey('probable_duplicate_cancel')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(results, [null, null, null]);
  });

  testWidgets('announces "Possible duplicate found" assertively on open', (
    tester,
  ) async {
    tester.takeAnnouncements();
    await open(tester);
    final announcements = tester.takeAnnouncements();
    expect(
      announcements.where((a) => a.message == en.smsImportDuplicateFound),
      hasLength(1),
    );
    expect(
      announcements
          .firstWhere((a) => a.message == en.smsImportDuplicateFound)
          .assertiveness,
      Assertiveness.assertive,
    );
  });

  testWidgets('each card is one semantics node; the title is a header', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    final existingNode = tester.getSemantics(
      find.byKey(const ValueKey('probable_duplicate_existing')),
    );
    expect(existingNode.label, contains(en.smsImportDuplicateExisting));
    expect(existingNode.label, contains(en.financeTypeExpense));
    expect(existingNode.label, contains(en.smsImportProvenanceSemantics));
    final incomingNode = tester.getSemantics(
      find.byKey(const ValueKey('probable_duplicate_incoming')),
    );
    expect(incomingNode.label, contains(en.smsImportDuplicateIncoming));
    expect(find.bySemanticsLabel(en.smsImportDuplicateTitle), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text(en.smsImportDuplicateTitle))
          .flagsCollection
          .isHeader,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('every action meets 48 dp', (tester) async {
    await open(tester);
    expectTapTargets(tester, sheet());
    for (final key in [
      'probable_duplicate_same',
      'probable_duplicate_add_anyway',
      'probable_duplicate_cancel',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('stacks at 130% text and below 360 dp, without overflow', (
    tester,
  ) async {
    await open(tester, textScale: 1.3);
    expect(
      find.byKey(const ValueKey('probable_duplicate_stacked')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('probable_duplicate_cancel')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await open(tester, size: const Size(320, 700));
    expect(
      find.byKey(const ValueKey('probable_duplicate_stacked')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% text in Arabic: no overflow, every action reachable', (
    tester,
  ) async {
    await open(
      tester,
      locale: const Locale('ar'),
      textScale: 2,
      size: const Size(360, 780),
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('probable_duplicate_cancel')),
      100,
      scrollable: find.descendant(
        of: sheet(),
        matching: find.byType(Scrollable),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(ar.smsImportDuplicateCancel), findsOneWidget);
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('${locale.name} ${theme.name}: "Already in Daftary" sits '
          'at the start edge', (tester) async {
        await open(tester, locale: locale.locale, theme: theme.theme);
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(locale.locale);
        expect(find.text(l10n.smsImportDuplicateExisting), findsOneWidget);
        final a = tester.getRect(
          find.byKey(const ValueKey('probable_duplicate_existing')),
        );
        final b = tester.getRect(
          find.byKey(const ValueKey('probable_duplicate_incoming')),
        );
        if (locale.locale.languageCode == 'ar') {
          expect(a.right, greaterThan(b.right));
        } else {
          expect(a.left, lessThan(b.left));
        }
      });
    }
  }

  group('duplicateComparisonPhrases', () {
    test('same amount and calendar days apart, with Arabic plurals', () {
      final a = existing(en);
      final b = incoming(en);
      expect(duplicateComparisonPhrases(en, existing: a, incoming: b), [
        en.smsImportDuplicateSameAmount,
        en.smsImportDuplicateDaysApart(1),
      ]);
      expect(en.smsImportDuplicateDaysApart(0), 'Same day');
      expect(ar.smsImportDuplicateDaysApart(2), contains('يومين'));
      expect(
        ar.smsImportDuplicateDaysApart(0),
        isNot(en.smsImportDuplicateDaysApart(0)),
      );
    });

    test('a match on the stated original amount says so (FR-059)', () {
      final a = DuplicateSide(
        title: 'x',
        amount: const Money.fromMinorUnits(2000, Currency.usd),
        date: DateTime(2026, 3, 4),
      );
      final b = DuplicateSide(
        title: 'y',
        amount: const Money.egp(100000),
        date: DateTime(2026, 3, 4),
      );
      expect(
        duplicateComparisonPhrases(
          en,
          existing: a,
          incoming: b,
          statedOriginalAmount: const Money.fromMinorUnits(2000, Currency.usd),
        ),
        [
          en.smsImportDuplicateSameOriginalAmount,
          en.smsImportDuplicateDaysApart(0),
        ],
      );
    });

    test('nothing to compare gives no phrase', () {
      expect(
        duplicateComparisonPhrases(
          en,
          existing: const DuplicateSide(title: 'x'),
          incoming: const DuplicateSide(title: 'y'),
        ),
        isEmpty,
      );
    });

    test('DuplicateSide.toString is redacted', () {
      final text = existing(en).toString();
      expect(text, isNot(contains('125')));
      expect(text, isNot(contains('Cafe')));
    });
  });
}
