import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/presentation/widgets/candidate_entry_card.dart';
import 'package:daftary/features/ocr/presentation/widgets/confidence_indicator.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T040 — the review screen's per-entry card (009 User Story 2).
///
/// The card is where the user does the reviewing that constitution
/// Principle X requires, so these tests are about whether it actually
/// affords that: can the entry be corrected, can it be discarded, is the
/// original line checkable against the page, and is an entry that cannot
/// yet be saved visibly explained rather than silently inert.
void main() {
  CandidateEntry buildEntry({
    String personName = 'Ahmed',
    int? amountMinorUnits = 50000,
    FieldConfidence? amountConfidence,
    String rawOcrText = 'Ahmed  500',
    TransactionDirection? direction,
  }) => CandidateEntry(
    id: 'e1',
    scanId: 'scan-1',
    status: CandidateEntryStatus.pendingReview,
    personName: personName,
    personNameConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
    amountConfidence:
        amountConfidence ?? FieldConfidence.read(FieldConfidenceLevel.low),
    directionConfidence: const FieldConfidence.inferred(),
    dateConfidence: const FieldConfidence.inferred(),
    amountMinorUnits: amountMinorUnits,
    direction: direction,
    rawOcrText: rawOcrText,
    createdAt: DateTime(2026, 3, 1),
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    CandidateEntry? entry,
    List<Person> duplicateMatches = const [],
    bool amountInvalid = false,
    bool highlightIncomplete = false,
    TransactionDirection? batchDefaultDirection = TransactionDirection.received,
    VoidCallback? onDiscard,
    ValueChanged<String>? onAmountChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // The card and its confidence badges read `context.financeColors`,
        // which only the app's own theme registers.
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateEntryCard(
              entry: entry ?? buildEntry(),
              batchDefaultDirection: batchDefaultDirection,
              scanDate: DateTime(2026, 3, 1),
              duplicateMatches: duplicateMatches,
              amountInvalid: amountInvalid,
              highlightIncomplete: highlightIncomplete,
              onPersonNameChanged: (_) {},
              onPersonSelected: (_) {},
              onDuplicatesDismissed: () {},
              onAmountChanged: onAmountChanged ?? (_) {},
              onDirectionChanged: (_) {},
              onDateChanged: (_) {},
              onNotesChanged: (_) {},
              onDiscard: onDiscard ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the parsed name and amount as editable fields', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Ahmed'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
    // The amount arrives formatted, not as raw minor units — the reviewer
    // is checking it against a paper, not against a database column.
    expect(find.textContaining('500'), findsWidgets);
  });

  testWidgets('an amount edit is reported to the caller', (tester) async {
    final reported = <String>[];
    await pumpCard(tester, onAmountChanged: reported.add);

    final amountField = find.byType(TextField).at(1);
    await tester.enterText(amountField, '750');
    await tester.pump();

    expect(reported, isNotEmpty);
    expect(reported.last, '750');
  });

  testWidgets('the discard action is present and reaches the caller '
      '(FR-010)', (tester) async {
    var discarded = 0;
    await pumpCard(tester, onDiscard: () => discarded++);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final discardButton = find.byTooltip(l10n.ocrReviewDiscardAction);
    expect(discardButton, findsOneWidget);

    await tester.tap(discardButton);
    await tester.pumpAndSettle();

    expect(discarded, 1);
  });

  testWidgets('per-field confidence is shown, so a low-confidence read is '
      'visible before it is trusted (FR-013)', (tester) async {
    await pumpCard(tester);

    expect(find.byType(ConfidenceIndicator), findsWidgets);
  });

  testWidgets('the original recognized line is available to check against '
      'the page', (tester) async {
    await pumpCard(tester, entry: buildEntry(rawOcrText: 'Ahmed  5OO'));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // Collapsed by default so a clean batch reads calmly...
    expect(find.text('Ahmed  5OO'), findsNothing);

    await tester.tap(find.text(l10n.ocrReviewRawTextAction));
    await tester.pumpAndSettle();

    // ...but always one tap away.
    expect(find.text('Ahmed  5OO'), findsOneWidget);
  });

  testWidgets('an entry missing its amount says why it cannot be saved '
      'rather than failing silently (FR-008)', (tester) async {
    await pumpCard(
      tester,
      entry: buildEntry(amountMinorUnits: null),
      highlightIncomplete: true,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.ocrReviewAmountRequired), findsWidgets);
  });

  testWidgets('an entry with no resolvable direction explains that too, '
      'rather than the app picking one', (tester) async {
    await pumpCard(
      tester,
      entry: buildEntry(),
      batchDefaultDirection: null,
      highlightIncomplete: true,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.ocrReviewDirectionRequired), findsWidgets);
  });

  testWidgets('a possible duplicate person is surfaced for the user to '
      'resolve (FR-009)', (tester) async {
    await pumpCard(
      tester,
      duplicateMatches: [
        Person(
          id: 'p1',
          name: 'Ahmed Ali',
          isArchived: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.ocrReviewDuplicateWarningAction), findsOneWidget);
  });
}
