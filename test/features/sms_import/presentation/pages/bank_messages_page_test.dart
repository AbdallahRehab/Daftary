import 'dart:async';

import 'package:daftary/core/confidence/field_confidence.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_cubit.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

/// T086 — `BankMessagesPage`: loading, empty, error and ready states, the
/// expired notice, row semantics, no batch Add, 48 dp, large text and the
/// RTL x LTR x light x dark matrix. Every value is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late FixedClock clock;
  late FakeSmsImportRepository repository;

  setUp(() {
    clock = FixedClock(DateTime(2026, 3, 10, 12));
    repository = FakeSmsImportRepository(clock: clock);
  });
  tearDown(() => repository.close());

  BankMessagesCubit cubitFor(FakeSmsImportRepository repo) =>
      buildBankMessagesCubit(repo, clock);

  Future<void> pumpList(
    WidgetTester tester, {
    FakeSmsImportRepository? repo,
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
    bool settle = true,
  }) => pumpSmsPage(
    tester,
    BankMessagesPage(cubit: cubitFor(repo ?? repository)),
    locale: locale,
    theme: theme,
    textScale: textScale,
    settle: settle,
  );

  List<PendingSmsImport> sample() => [
    buildPendingImport(),
    buildPendingImport(
      id: 'pending-2',
      fingerprint: 'fp-2',
      amount: null,
      candidates: [100, 200],
      suggestedType: SuggestedRecordType.unset,
      merchant: 'متجر المثال',
      confidence: ParseConfidence(
        fields: {SmsField.date: const FieldConfidence.inferred()},
        overall: OverallConfidence.low,
      ),
      warnings: {SmsWarning.possibleDuplicate},
    ),
  ];

  testWidgets('loading shows skeleton cards', (tester) async {
    await pumpList(tester, repo: _NeverEmits(clock), settle: false);
    expect(
      find.byKey(const ValueKey('bank_messages_skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('empty explains scan, paste and share', (tester) async {
    await pumpList(tester);
    expect(find.text(en.smsImportPendingEmptyTitle), findsOneWidget);
    expect(find.text(en.smsImportPendingEmptyMessage), findsOneWidget);
  });

  testWidgets('empty offers Paste (US4), which opens the Paste screen', (
    tester,
  ) async {
    await pumpList(tester);
    await tester.tap(find.text(en.smsImportPasteTitle));
    await tester.pumpAndSettle();
    expect(find.text('paste-route'), findsOneWidget);
  });

  testWidgets('error shows retry', (tester) async {
    await pumpList(tester, repo: _FailingWatch(clock));
    expect(find.text(en.smsImportPendingLoadErrorTitle), findsOneWidget);
    expect(find.text(en.smsImportPendingRetry), findsOneWidget);
  });

  testWidgets('ready lists cards low confidence first; tapping opens review', (
    tester,
  ) async {
    repository.seed(sample());
    await pumpList(tester);
    final cards = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('pending_import_card_'),
    );
    expect(cards, findsNWidgets(2));
    final firstY = tester
        .getTopLeft(find.byKey(const ValueKey('pending_import_card_pending-2')))
        .dy;
    final secondY = tester
        .getTopLeft(find.byKey(const ValueKey('pending_import_card_pending-1')))
        .dy;
    expect(firstY, lessThan(secondY));
    expect(find.text(en.smsImportPendingAmountNeedsCheck), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('pending_import_card_pending-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('review-pending-1'), findsOneWidget);
  });

  testWidgets('rows announce as one node with their meaning', (tester) async {
    final handle = tester.ensureSemantics();
    repository.seed([buildPendingImport()]);
    await pumpList(tester);
    expect(
      find.bySemanticsLabel(
        RegExp(
          '${RegExp.escape(en.financeTypeExpense)}.*'
          '${RegExp.escape(en.ocrConfidenceHigh)}',
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('expired notice appears after expiry and can be dismissed', (
    tester,
  ) async {
    repository.seed([buildPendingImport(createdAt: DateTime(2026, 1, 1))]);
    await pumpList(tester);
    expect(find.text(en.smsImportPendingExpiredNotice(1)), findsOneWidget);
    expect(find.text(en.smsImportPendingEmptyTitle), findsOneWidget);
    await tester.tap(find.byTooltip(en.smsImportPendingExpiredDismiss));
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPendingExpiredNotice(1)), findsNothing);
  });

  testWidgets('there is no batch Add anywhere', (tester) async {
    repository.seed(sample());
    await pumpList(tester);
    expect(find.text(en.smsImportReviewAdd), findsNothing);
    expect(
      find.textContaining(RegExp('add all', caseSensitive: false)),
      findsNothing,
    );
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    repository.seed(sample());
    await pumpList(tester);
    for (final id in ['pending-1', 'pending-2']) {
      final size = tester.getSize(
        find.byKey(ValueKey('pending_import_card_$id')),
      );
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expectTapTargets(tester, find.byType(BankMessagesPage));
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('renders in ${locale.name} / ${theme.name}', (tester) async {
        repository.seed(sample());
        await pumpList(tester, locale: locale.locale, theme: theme.theme);
        expect(tester.takeException(), isNull);
        final l10n = lookupAppLocalizations(locale.locale);
        expect(find.text(l10n.smsImportPendingTitle), findsOneWidget);
      });
    }
  }

  testWidgets('200% text renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repository.seed(sample());
    await pumpList(tester, textScale: 2, locale: const Locale('ar'));
    expect(tester.takeException(), isNull);
  });
}

class _NeverEmits extends FakeSmsImportRepository {
  _NeverEmits(FixedClock clock) : super(clock: clock);

  @override
  Future<Either<Failure, int>> expireDue(DateTime now) =>
      Completer<Either<Failure, int>>().future;
}

class _FailingWatch extends FakeSmsImportRepository {
  _FailingWatch(FixedClock clock) : super(clock: clock);

  @override
  Stream<Either<Failure, List<PendingSmsImport>>> watchPending() =>
      Stream.value(const Left(CacheFailure('sms_import_store_failed')));
}
