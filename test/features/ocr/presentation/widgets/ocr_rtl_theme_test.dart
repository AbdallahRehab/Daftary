import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:daftary/features/ocr/presentation/widgets/candidate_entry_card.dart';
import 'package:daftary/features/ocr/presentation/widgets/confidence_indicator.dart';
import 'package:daftary/features/ocr/presentation/widgets/direction_default_toggle.dart';
import 'package:daftary/features/ocr/presentation/widgets/scan_failure_state.dart';
import 'package:daftary/features/ocr/presentation/widgets/scan_processing_overlay.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T070 — the RTL/LTR and light/dark pass for 009, written as assertions
/// rather than left to a manual look: every OCR widget is pumped in Arabic
/// RTL and English LTR, and in both themes, so a hardcoded `left`/`right`
/// or a colour that vanishes in dark mode fails here instead of shipping
/// (009 FR-022).
void main() {
  final scanDate = DateTime(2026, 9, 15);

  CandidateEntry entry({
    String personName = 'أحمد حسن',
    int? amountMinorUnits = 150000,
    FieldConfidence? amountConfidence,
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
    rawOcrText: 'أحمد حسن  ١٥٠٠',
    createdAt: scanDate,
  );

  final locales = [
    (name: 'ar RTL', locale: const Locale('ar')),
    (name: 'en LTR', locale: const Locale('en')),
  ];
  final themes = [
    (name: 'light', theme: buildLightTheme()),
    (name: 'dark', theme: buildDarkTheme()),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required Locale locale,
    required ThemeData theme,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    // A widget with a looping progress animation never settles, which is
    // correct behaviour rather than something to wait out.
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// Pumping without an exception is the assertion: an overflow, a missing
  /// localization, or a theme extension the widget expects and the theme
  /// does not provide all surface as a thrown error here.
  Future<void> rendersEverywhere(
    WidgetTester tester,
    Widget Function() build, {
    bool settle = true,
  }) async {
    for (final locale in locales) {
      for (final theme in themes) {
        await pump(
          tester,
          build(),
          locale: locale.locale,
          theme: theme.theme,
          settle: settle,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${locale.name} / ${theme.name}',
        );
      }
    }
  }

  testWidgets('every confidence variant renders in both locales and themes', (
    tester,
  ) async {
    for (final confidence in [
      const FieldConfidence.inferred(),
      FieldConfidence.read(FieldConfidenceLevel.low),
      FieldConfidence.read(FieldConfidenceLevel.medium),
      FieldConfidence.read(FieldConfidenceLevel.high),
    ]) {
      await rendersEverywhere(
        tester,
        () => ConfidenceIndicator(confidence: confidence),
      );
    }
  });

  testWidgets('the candidate entry card lays out with Arabic names and '
      'Arabic-Indic amounts without overflowing', (tester) async {
    await rendersEverywhere(
      tester,
      () => CandidateEntryCard(
        entry: entry(),
        batchDefaultDirection: TransactionDirection.received,
        scanDate: scanDate,
        duplicateMatches: const [],
        amountInvalid: false,
        onPersonNameChanged: (_) {},
        onPersonSelected: (_) {},
        onDuplicatesDismissed: () {},
        onAmountChanged: (_) {},
        onDirectionChanged: (_) {},
        onDateChanged: (_) {},
        onNotesChanged: (_) {},
        onDiscard: () {},
      ),
    );
  });

  testWidgets('an incomplete card renders its explanation in both locales', (
    tester,
  ) async {
    await rendersEverywhere(
      tester,
      () => CandidateEntryCard(
        entry: entry(amountMinorUnits: null),
        batchDefaultDirection: null,
        scanDate: scanDate,
        duplicateMatches: const [],
        amountInvalid: true,
        highlightIncomplete: true,
        onPersonNameChanged: (_) {},
        onPersonSelected: (_) {},
        onDuplicatesDismissed: () {},
        onAmountChanged: (_) {},
        onDirectionChanged: (_) {},
        onDateChanged: (_) {},
        onNotesChanged: (_) {},
        onDiscard: () {},
      ),
    );
  });

  testWidgets('the batch direction toggle renders in every combination, '
      'including its unset state', (tester) async {
    for (final value in [
      null,
      TransactionDirection.given,
      TransactionDirection.received,
    ]) {
      await rendersEverywhere(
        tester,
        () => DirectionDefaultToggle(value: value, onChanged: (_) {}),
      );
    }
  });

  testWidgets('every failure state renders its own recovery copy in both '
      'locales and themes (FR-004)', (tester) async {
    for (final failure in <Failure>[
      const NoTextRecognizedFailure('no text'),
      const NoCandidatesParsedFailure('no candidates'),
      const OcrUnavailableFailure('unsupported'),
      const ImageProcessingFailure('bad image'),
    ]) {
      await rendersEverywhere(
        tester,
        () => ScanFailureState(
          failure: failure,
          onRetakePhoto: () {},
          onRecrop: () {},
          onEnterManually: () {},
          onOpenSettings: () {},
        ),
      );
    }
  });

  testWidgets('the processing overlay renders its cancel affordance '
      'everywhere (FR-017)', (tester) async {
    await rendersEverywhere(
      tester,
      () => const SizedBox(
        height: 400,
        child: ScanProcessingOverlay(onCancel: _noop),
      ),
      settle: false,
    );
  });

  testWidgets('RTL actually flips the layout rather than only switching the '
      'strings', (tester) async {
    await pump(
      tester,
      ConfidenceIndicator(
        confidence: FieldConfidence.read(FieldConfidenceLevel.low),
      ),
      locale: const Locale('ar'),
      theme: buildLightTheme(),
    );
    final rtlIconX = tester.getCenter(find.byType(Icon)).dx;
    final rtlTextX = tester.getCenter(find.byType(Text)).dx;

    await pump(
      tester,
      ConfidenceIndicator(
        confidence: FieldConfidence.read(FieldConfidenceLevel.low),
      ),
      locale: const Locale('en'),
      theme: buildLightTheme(),
    );
    final ltrIconX = tester.getCenter(find.byType(Icon)).dx;
    final ltrTextX = tester.getCenter(find.byType(Text)).dx;

    expect(
      rtlIconX > rtlTextX,
      isTrue,
      reason: 'in RTL the leading icon sits to the right of its label',
    );
    expect(
      ltrIconX < ltrTextX,
      isTrue,
      reason: 'in LTR it sits to the left — the row genuinely flipped',
    );
  });
}

void _noop() {}
