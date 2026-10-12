import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/presentation/pages/import_review_page.dart';
import 'package:daftary/features/sms_import/presentation/widgets/bidi_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/review_harness.dart';
import '../../helpers/widget_harness.dart';

/// T086 — `ImportReviewPage`: states, Add gating with the missing field in
/// text, the parser follow-ups, semantics, 48 dp targets, large text and
/// the RTL x LTR x light x dark matrix. Every value is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late ReviewHarness harness;

  setUp(() => harness = ReviewHarness());
  tearDown(() => harness.dispose());

  Future<void> pumpReview(
    WidgetTester tester,
    List<PendingSmsImport> items, {
    String id = 'pending-1',
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
    bool tall = true,
  }) async {
    if (tall) {
      // Tall enough that the whole form is built (the list is lazy).
      tester.view.physicalSize = const Size(420 * 3, 3000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }
    harness.repository.seed(items);
    await pumpSmsPage(
      tester,
      ImportReviewPage(importId: id, cubit: harness.build()),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );
  }

  Finder addButton() => find.byKey(const ValueKey('import_review_add'));

  bool addEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.descendant(
              of: addButton(),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed !=
      null;

  testWidgets('loading shows a skeleton', (tester) async {
    final h = ReviewHarness(repositoryOverride: _NeverLoads());
    await pumpSmsPage(
      tester,
      ImportReviewPage(importId: 'pending-1', cubit: h.build()),
      settle: false,
    );
    expect(
      find.byKey(const ValueKey('import_review_skeleton')),
      findsOneWidget,
    );
    await h.dispose();
  });

  testWidgets('a load failure shows an error with retry', (tester) async {
    final h = ReviewHarness(repositoryOverride: _FailingGet());
    await pumpSmsPage(
      tester,
      ImportReviewPage(importId: 'pending-1', cubit: h.build()),
    );
    expect(find.text(en.smsImportReviewLoadErrorTitle), findsOneWidget);
    expect(find.text(en.smsImportPendingRetry), findsOneWidget);
    await h.dispose();
  });

  testWidgets('a decided item shows "already handled"', (tester) async {
    await pumpReview(tester, [
      pendingWithDecision(
        buildPendingImport(),
        status: SmsImportStatus.ignored,
        decidedAt: DateTime(2026, 3, 4),
        hasRawText: false,
      ),
    ]);
    expect(find.text(en.smsImportReviewAlreadyHandledTitle), findsOneWidget);
    expect(addButton(), findsNothing);
  });

  testWidgets('Add is disabled with the missing field named in text, and '
      'its semantics state why', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpReview(tester, [buildPendingImport()]);
    expect(addEnabled(tester), isFalse);
    expect(
      find.text(en.smsImportReviewMissing(en.smsImportReviewFieldCategory)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(
          RegExp.escape(
            en.smsImportSemanticsAddUnavailable(
              en.smsImportReviewFieldCategory,
            ),
          ),
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('choosing a category enables Add; Add saves exactly once and '
      'leaves the review', (tester) async {
    await pumpReview(tester, [buildPendingImport()]);
    await tester.ensureVisible(find.text('seed_groceries'));
    await tester.tap(find.text('seed_groceries'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('import_review_missing')), findsNothing);
    expect(addEnabled(tester), isTrue);
    await tester.ensureVisible(addButton());
    await tester.tap(addButton());
    await tester.pumpAndSettle();
    expect(harness.repository.confirmCalls, hasLength(1));
    expect(harness.repository.rows['pending-1']!.status, SmsImportStatus.added);
    expect(find.text('hub-route'), findsOneWidget);
  });

  testWidgets('after Add it advances to the next pending item', (tester) async {
    await pumpReview(tester, [
      buildPendingImport(suggestedCategoryId: 'seed_groceries'),
      buildPendingImport(
        id: 'pending-2',
        fingerprint: 'fp-2',
        createdAt: DateTime(2026, 3, 5),
      ),
    ]);
    await tester.ensureVisible(addButton());
    await tester.tap(addButton());
    await tester.pumpAndSettle();
    expect(find.text('review-pending-2'), findsOneWidget);
  });

  testWidgets('one candidate and no currency: amount pre-filled, currency '
      'required', (tester) async {
    await pumpReview(tester, [
      buildPendingImport(
        amount: null,
        candidates: [4200],
        suggestedCategoryId: 'seed_groceries',
        source: SmsSource.paste,
        senderId: null,
      ),
    ]);
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('import_review_amount')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '42.00');
    expect(find.text(en.smsImportReviewCurrencyNeeded), findsOneWidget);
    expect(
      find.text(en.smsImportReviewMissing(en.smsImportReviewFieldCurrency)),
      findsOneWidget,
    );
    expect(addEnabled(tester), isFalse);
  });

  testWidgets('two candidates give one-tap chips', (tester) async {
    await pumpReview(tester, [
      buildPendingImport(
        amount: null,
        candidates: [4200, 9900],
        suggestedCategoryId: 'seed_groceries',
      ),
    ]);
    expect(find.text(en.smsImportReviewWhichAmount), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('import_review_candidate_9900')),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('import_review_amount')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '99.00');
  });

  testWidgets('the unverified-profile warning is shown', (tester) async {
    await pumpReview(tester, [
      buildPendingImport(warnings: {SmsWarning.unverifiedProfile}),
    ]);
    expect(
      find.text(en.smsImportWarningText(SmsWarning.unverifiedProfile.name)),
      findsOneWidget,
    );
  });

  testWidgets('an authorization reversal shows the matched record with '
      '"Open it" and no duplicate banner', (tester) async {
    harness.lookup.savedMatches = [
      DuplicateRecordRef(
        id: 'entry-7',
        recordType: SavedRecordType.financeEntry,
        type: SuggestedRecordType.expense,
        amount: const Money.egp(12550),
        date: DateTime(2026, 3, 4),
      ),
    ];
    await pumpReview(tester, [
      buildPendingImport(
        kind: SmsKind.authorizationReversal,
        direction: SmsDirection.credit,
        suggestedType: SuggestedRecordType.ignore,
        warnings: {SmsWarning.reversalHint},
      ),
    ]);
    expect(
      find.byKey(const ValueKey('import_review_matched_record')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('import_review_duplicate_banner')),
      findsNothing,
    );
    await tester.tap(find.text(en.smsImportReviewOpenRecord));
    await tester.pumpAndSettle();
    expect(find.text('entry-entry-7'), findsOneWidget);
  });

  testWidgets('show original: in its own direction; unavailable without '
      'an original', (tester) async {
    harness.repository.seed([]);
    await harness.repository.insertPending(
      NewPendingImport(
        item: buildPendingImport(),
        rawMasked: 'تم خصم مبلغ EGP 125.50',
      ),
    );
    await pumpReview(tester, const []);
    await tester.ensureVisible(find.text(en.smsImportReviewShowOriginal));
    await tester.tap(find.text(en.smsImportReviewShowOriginal));
    await tester.pumpAndSettle();
    final text = find.byKey(const ValueKey('import_review_original_text'));
    expect(text, findsOneWidget);
    final direction = tester
        .widget<Directionality>(
          find.ancestor(of: text, matching: find.byType(Directionality)).first,
        )
        .textDirection;
    expect(direction, TextDirection.rtl);
  });

  // T145 (FR-062, FR-074a) replaces the earlier "hidden" rendering: with
  // no readable original, "Show original" is shown disabled with the
  // localized reason, and it never opens.
  testWidgets('no original: "Show original" is disabled with its reason', (
    tester,
  ) async {
    await pumpReview(tester, [buildPendingImport(hasRawText: false)]);
    final tile = find.byKey(
      const ValueKey('import_review_original_unavailable'),
    );
    expect(tile, findsOneWidget);
    expect(tester.widget<ListTile>(tile).enabled, isFalse);
    expect(
      find.descendant(
        of: tile,
        matching: find.text(en.smsImportReviewShowOriginal),
      ),
      findsOneWidget,
    );
    expect(find.text(en.smsImportErrorOriginalUnavailable), findsOneWidget);
    expect(find.byKey(const ValueKey('import_review_original')), findsNothing);
  });

  testWidgets('a save failure is shown and the item stays pending', (
    tester,
  ) async {
    await pumpReview(tester, [
      buildPendingImport(suggestedCategoryId: 'seed_groceries'),
    ]);
    harness.repository.nextFailure = const CacheFailure('sms_confirm_failed');
    await tester.ensureVisible(addButton());
    await tester.tap(addButton());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('import_review_failure')), findsOneWidget);
    expect(harness.repository.rows['pending-1']!.isPending, isTrue);
  });

  testWidgets('the merchant in the header is a direction-isolated name', (
    tester,
  ) async {
    await pumpReview(tester, [buildPendingImport()]);
    expect(find.text(BidiIsolate.auto('Example Cafe')), findsOneWidget);
  });

  testWidgets('a fee whose parent has no date links without an empty date', (
    tester,
  ) async {
    await pumpReview(tester, [
      buildPendingImport(
        id: 'parent-1',
        fingerprint: 'fp-parent',
        withoutDate: true,
      ),
      buildPendingImport(
        kind: SmsKind.fee,
        parentImportId: 'parent-1',
        merchant: null,
      ),
    ]);
    expect(find.text(en.smsImportReviewFeeFromParentNoDate), findsOneWidget);
    expect(
      find.textContaining(en.smsImportReviewFeeFromParent('')),
      findsNothing,
    );
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    await pumpReview(tester, [
      buildPendingImport(
        amount: null,
        candidates: [4200, 9900],
        suggestedCategoryId: 'seed_groceries',
      ),
    ]);
    expectTapTargets(tester, find.byType(ImportReviewPage));
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('renders in ${locale.name} / ${theme.name}', (tester) async {
        await pumpReview(
          tester,
          [
            buildPendingImport(
              merchant: 'متجر المثال',
              warnings: {SmsWarning.genericParser},
            ),
          ],
          locale: locale.locale,
          theme: theme.theme,
        );
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(locale.locale);
        expect(find.text(l10n.smsImportReviewTitle), findsOneWidget);
        expect(
          Directionality.of(tester.element(addButton())),
          locale.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
      });
    }
  }

  testWidgets('200% text renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpReview(
      tester,
      [
        buildPendingImport(warnings: {SmsWarning.unverifiedProfile}),
      ],
      textScale: 2,
      tall: false,
    );
    expect(tester.takeException(), isNull);
    // Scroll the whole form through, so every section is laid out.
    await tester.scrollUntilVisible(
      addButton(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(addButton(), findsOneWidget);
  });

  testWidgets('200% text: people ledger, two amounts, reversal card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    harness.lookup.savedMatches = [
      DuplicateRecordRef(
        id: 'entry-7',
        recordType: SavedRecordType.financeEntry,
        type: SuggestedRecordType.expense,
        amount: const Money.egp(12550),
        date: DateTime(2026, 3, 4),
      ),
    ];
    await pumpReview(
      tester,
      [
        buildPendingImport(
          suggestedType: SuggestedRecordType.given,
          amount: null,
          candidates: [4200, 9900],
          kind: SmsKind.authorizationReversal,
          warnings: {SmsWarning.reversalHint, SmsWarning.genericParser},
          foreignAmountText: 'USD 25.00',
        ),
      ],
      locale: const Locale('ar'),
      textScale: 2,
      tall: false,
    );
    await tester.scrollUntilVisible(
      addButton(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('probable duplicate (T102, US5)', () {
    DuplicateRecordRef manual() => DuplicateRecordRef(
      id: 'entry-9',
      recordType: SavedRecordType.financeEntry,
      type: SuggestedRecordType.expense,
      amount: const Money.egp(12550),
      date: DateTime(2026, 3, 3),
      note: 'Example Cafe',
    );

    Finder sheet() => find.byKey(const ValueKey('probable_duplicate_sheet'));

    Future<void> tapAdd(WidgetTester tester) async {
      await tester.ensureVisible(addButton());
      await tester.tap(addButton());
      await tester.pumpAndSettle();
    }

    testWidgets('checked on open: a banner with Compare; Compare opens the '
        'side-by-side sheet; Cancel keeps the item pending', (tester) async {
      harness.lookup.savedMatches = [manual()];
      await pumpReview(tester, [
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
      ]);
      expect(
        find.byKey(const ValueKey('import_review_duplicate_banner')),
        findsOneWidget,
      );
      expect(sheet(), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('import_review_duplicate_compare')),
      );
      await tester.pumpAndSettle();
      expect(sheet(), findsOneWidget);
      expect(find.text(en.smsImportDuplicateExisting), findsOneWidget);
      expect(find.text(en.smsImportDuplicateIncoming), findsOneWidget);
      expect(
        find.text(en.smsImportDuplicateNote('Example Cafe')),
        findsOneWidget,
      );
      expect(find.text(en.smsImportDuplicateSameAmount), findsOneWidget);
      expect(find.text(en.smsImportDuplicateDaysApart(1)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('probable_duplicate_cancel')));
      await tester.pumpAndSettle();
      expect(sheet(), findsNothing);
      expect(harness.repository.rows['pending-1']!.isPending, isTrue);
      expect(harness.repository.confirmCalls, isEmpty);
    });

    testWidgets('an incomplete draft: Compare offers "add anyway" disabled', (
      tester,
    ) async {
      harness.lookup.savedMatches = [manual()];
      await pumpReview(tester, [buildPendingImport()]);
      expect(addEnabled(tester), isFalse);
      await tester.tap(
        find.byKey(const ValueKey('import_review_duplicate_compare')),
      );
      await tester.pumpAndSettle();
      expect(sheet(), findsOneWidget);
      final addAnyway = find.descendant(
        of: find.byKey(const ValueKey('probable_duplicate_add_anyway')),
        matching: find.byWidgetPredicate(
          (w) => w is ButtonStyleButton && w.onPressed == null,
        ),
      );
      expect(addAnyway, findsOneWidget);
      expect(harness.repository.confirmCalls, isEmpty);
    });

    testWidgets('Add raises the sheet (not a dialog); "add anyway" adds', (
      tester,
    ) async {
      harness.lookup.savedMatches = [manual()];
      await pumpReview(tester, [
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
      ]);
      await tapAdd(tester);
      expect(sheet(), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.repository.confirmCalls, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('probable_duplicate_add_anyway')),
      );
      await tester.pumpAndSettle();
      expect(harness.repository.confirmCalls, hasLength(1));
      expect(
        harness.repository.rows['pending-1']!.status,
        SmsImportStatus.added,
      );
      expect(find.text('hub-route'), findsOneWidget);
    });

    testWidgets('"It\'s the same, don\'t add" closes the item, adds nothing '
        'and advances to the next item', (tester) async {
      harness.lookup.savedMatches = [manual()];
      await pumpReview(tester, [
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          createdAt: DateTime(2026, 3, 5),
        ),
      ]);
      await tapAdd(tester);
      await tester.tap(find.byKey(const ValueKey('probable_duplicate_same')));
      await tester.pumpAndSettle();
      expect(harness.repository.confirmCalls, isEmpty);
      expect(
        harness.repository.rows['pending-1']!.status,
        SmsImportStatus.duplicateClosed,
      );
      expect(find.text('review-pending-2'), findsOneWidget);
    });

    testWidgets('closing the last item announces it and returns to the list', (
      tester,
    ) async {
      harness.lookup.savedMatches = [manual()];
      await pumpReview(tester, [
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
      ]);
      tester.takeAnnouncements();
      await tester.tap(
        find.byKey(const ValueKey('import_review_duplicate_compare')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('probable_duplicate_same')));
      await tester.pump();
      final messages = tester.takeAnnouncements().map((a) => a.message);
      expect(messages, contains(en.smsImportDuplicateFound));
      expect(messages, contains(en.smsImportDuplicateClosed));
      await tester.pumpAndSettle();
      expect(find.text('hub-route'), findsOneWidget);
    });

    testWidgets('a pending pair shows the other bank message', (tester) async {
      final other = buildPendingImport(
        id: 'pending-3',
        fingerprint: 'fp-3',
        source: SmsSource.paste,
        senderId: null,
        createdAt: DateTime(2026, 3, 6),
      );
      harness.lookup.pendingPair = other;
      await pumpReview(tester, [
        buildPendingImport(suggestedCategoryId: 'seed_groceries'),
        other,
      ]);
      await tester.tap(
        find.byKey(const ValueKey('import_review_duplicate_compare')),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportDuplicateOtherPending), findsOneWidget);
      expect(find.text(en.smsImportReviewSourceLabel('paste')), findsOneWidget);
      expect(find.text(en.smsImportDuplicateDaysApart(0)), findsOneWidget);
    });

    testWidgets('legitimately similar shows no banner and Add is not '
        'interrupted', (tester) async {
      harness.lookup.savedMatches = [
        DuplicateRecordRef(
          id: 'entry-9',
          recordType: SavedRecordType.financeEntry,
          type: SuggestedRecordType.expense,
          amount: const Money.egp(12550),
          date: DateTime(2026, 3, 4),
          importProvenance: ImportProvenance.sms,
        ),
      ];
      harness.lookup.refHashBySavedRecord = {'entry-9': 'ref-other'};
      await pumpReview(tester, [
        buildPendingImport(
          suggestedCategoryId: 'seed_groceries',
          refHash: 'ref-mine',
        ),
      ]);
      expect(
        find.byKey(const ValueKey('import_review_duplicate_banner')),
        findsNothing,
      );
      await tapAdd(tester);
      expect(sheet(), findsNothing);
      expect(harness.repository.confirmCalls, hasLength(1));
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('${locale.name} ${theme.name}: the sheet over review '
            'renders without overflow', (tester) async {
          harness.lookup.savedMatches = [manual()];
          await pumpReview(
            tester,
            [buildPendingImport(suggestedCategoryId: 'seed_groceries')],
            locale: locale.locale,
            theme: theme.theme,
          );
          await tester.tap(
            find.byKey(const ValueKey('import_review_duplicate_compare')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(sheet(), findsOneWidget);
          expectTapTargets(tester, sheet());
        });
      }
    }
  });

  testWidgets('the page offers no batch add', (tester) async {
    await pumpReview(tester, [buildPendingImport()]);
    expect(
      find.textContaining(RegExp('add all', caseSensitive: false)),
      findsNothing,
    );
  });
}

class _NeverLoads extends FakeSmsImportRepository {
  @override
  Future<Either<Failure, PendingSmsImport>> getById(String id) =>
      Completer<Either<Failure, PendingSmsImport>>().future;
}

class _FailingGet extends FakeSmsImportRepository {
  @override
  Future<Either<Failure, PendingSmsImport>> getById(String id) async =>
      const Left(CacheFailure('sms_import_store_failed'));
}
