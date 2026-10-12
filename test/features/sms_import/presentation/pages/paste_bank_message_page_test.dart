import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/l10n/app_localizations_en.dart';
import 'package:daftary/features/sms_import/data/platform/system_clipboard_reader.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/read_clipboard_text.dart';
import 'package:daftary/features/sms_import/presentation/cubit/paste_cubit.dart';
import 'package:daftary/features/sms_import/presentation/pages/paste_bank_message_page.dart';
import 'package:daftary/features/sms_import/presentation/routes.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_inbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget_harness.dart';

class _MockImportPasted extends Mock implements ImportPastedText {}

class _MockImportShared extends Mock implements ImportSharedText {}

const _secret =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 card ****0000';

/// T092 — `PasteBankMessagePage`: the mocked `flutter/platform` channel
/// receives **zero** `Clipboard.getData` calls before the Paste tap (open,
/// resume, focus, route push); the privacy flags; bounds; result states;
/// RTL/theme; large text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = AppLocalizationsEn();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> platformCalls;
  late String? clipboardText;
  late _MockImportPasted importPasted;
  late _MockImportShared importShared;
  late SharedTextInbox inbox;

  int clipboardReads() =>
      platformCalls.where((m) => m == 'Clipboard.getData').length;

  setUpAll(() {
    registerFallbackValue(SmsSource.paste);
    registerFallbackValue(const SharedText(text: ''));
  });

  setUp(() {
    platformCalls = [];
    clipboardText = _secret;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call.method);
      if (call.method == 'Clipboard.getData') {
        final text = clipboardText;
        return text == null ? null : {'text': text};
      }
      if (call.method == 'Clipboard.hasStrings') {
        return {'value': clipboardText != null};
      }
      return null;
    });
    importPasted = _MockImportPasted();
    importShared = _MockImportShared();
    inbox = SharedTextInbox();
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Right(
        PasteImportResult(
          summary: ScanSummary(scanned: 1, recognized: 1, createdPending: 1),
          newIds: const ['id-1'],
        ),
      ),
    );
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    await inbox.dispose();
  });

  PasteCubit newCubit() => PasteCubit(
    // The real adapter, so the mocked platform channel sees every read.
    ReadClipboardText(const SystemClipboardReader()),
    importPasted,
    importShared,
    inbox,
  );

  Future<GoRouter> pumpPage(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
    bool tall = true,
  }) async {
    if (tall) {
      // Room for the field, the buttons and the result panel at once.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    return pumpSmsPage(
      tester,
      PasteBankMessagePage(cubit: newCubit()),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );
  }

  /// Scrolls the page's list until [finder] is built and visible, then
  /// taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Finder field() => find.byKey(const ValueKey('paste_bank_message_field'));
  Finder pasteButton() =>
      find.byKey(const ValueKey('paste_bank_message_paste'));
  Finder processButton() =>
      find.byKey(const ValueKey('paste_bank_message_process'));

  group('FR-015: no clipboard read before the Paste tap', () {
    testWidgets('open, focus and resume read nothing; the tap reads once', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(clipboardReads(), 0);

      await tester.tap(field());
      await tester.pumpAndSettle();
      expect(clipboardReads(), 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(clipboardReads(), 0);

      await tapVisible(tester, pasteButton());
      await tester.pumpAndSettle();
      expect(clipboardReads(), 1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        _secret,
      );
    });

    testWidgets('a route push to the page reads nothing', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push(BankMessagesRoutes.paste),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: BankMessagesRoutes.paste,
            builder: (_, _) => PasteBankMessagePage(cubit: newCubit()),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportPasteTitle), findsWidgets);
      expect(clipboardReads(), 0);
    });

    testWidgets('a shared text is shown and staged without a clipboard '
        'read; the field stays empty', (tester) async {
      when(
        () => importShared(any()),
      ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
      inbox.put(const SharedText(text: _secret));
      await pumpPage(tester);
      expect(clipboardReads(), 0);
      verify(() => importShared(const SharedText(text: _secret))).called(1);
      expect(find.text(en.smsImportShareReceived), findsOneWidget);
      expect(find.text(en.smsImportPasteNotRecognizedTitle), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.textContaining('Example Cafe'), findsNothing);
    });
  });

  testWidgets('the field never feeds the keyboard', (tester) async {
    await pumpPage(tester);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enableIMEPersonalizedLearning, isFalse);
    expect(textField.autocorrect, isFalse);
    expect(textField.enableSuggestions, isFalse);
    expect(textField.obscureText, isFalse);
    expect(textField.maxLength, isNull, reason: 'never truncates silently');
  });

  testWidgets('Process is disabled while the field is empty', (tester) async {
    await pumpPage(tester);
    final button = tester.widget<FilledButton>(
      find.descendant(of: processButton(), matching: find.byType(FilledButton)),
    );
    expect(button.onPressed, isNull);
    expect(find.text(en.smsImportPasteLimits), findsOneWidget);
    expect(find.text(en.smsImportPasteCharacterCount(0)), findsOneWidget);
  });

  testWidgets('an empty clipboard shows "nothing to paste"', (tester) async {
    clipboardText = null;
    await pumpPage(tester);
    await tapVisible(tester, pasteButton());
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPasteNothingTitle), findsOneWidget);
    expect(find.text(en.smsImportErrorClipboardEmpty), findsOneWidget);
  });

  testWidgets('one recognized item opens its review', (tester) async {
    final router = await pumpPage(tester);
    await tester.enterText(field(), _secret);
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    verify(
      () => importPasted(text: _secret, source: SmsSource.paste),
    ).called(1);
    expect(find.text('review-id-1'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.toString(),
      BankMessagesRoutes.review('id-1'),
    );
  });

  testWidgets('several recognized items open the list', (tester) async {
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Right(
        PasteImportResult(
          summary: ScanSummary(scanned: 3, recognized: 2, createdPending: 2),
          newIds: const ['a', 'b'],
        ),
      ),
    );
    await pumpPage(tester);
    await tester.enterText(field(), _secret);
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
  });

  testWidgets('already-known messages say so and stay on the page', (
    tester,
  ) async {
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Right(
        PasteImportResult(
          summary: ScanSummary(scanned: 1, recognized: 1, alreadyKnown: 1),
        ),
      ),
    );
    await pumpPage(tester);
    await tester.enterText(field(), _secret);
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPasteRecognized(1)), findsOneWidget);
    expect(find.textContaining(en.smsImportPasteAlreadyListed), findsOneWidget);
    await tapVisible(tester, find.text(en.smsImportPasteOpenList));
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
  });

  testWidgets('not recognized offers manual entry and Try again', (
    tester,
  ) async {
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
    await pumpPage(tester);
    await tester.enterText(field(), 'hello');
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPasteNotRecognizedTitle), findsOneWidget);
    expect(find.text(en.smsImportPasteEnterManually), findsOneWidget);
    await tapVisible(tester, find.text(en.smsImportPasteTryAgain));
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPasteNotRecognizedTitle), findsNothing);
  });

  for (final (limit, message) in [
    (InputLimit.characters, en.smsImportErrorTooLongCharacters),
    (InputLimit.messages, en.smsImportErrorTooManyMessages),
  ]) {
    testWidgets('bounds: ${limit.name} exceeded is explained', (tester) async {
      when(
        () => importPasted(
          text: any(named: 'text'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async => Left(InputTooLargeFailure(limit)));
      await pumpPage(tester);
      await tester.enterText(field(), 'x' * 10001);
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportPasteCharacterCount(10001)), findsOneWidget);
      await tapVisible(tester, processButton());
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportPasteTooLargeTitle), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('unreadable only offers manual entry', (tester) async {
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer(
      (_) async => Right(
        PasteImportResult(summary: ScanSummary(scanned: 1, unreadable: 1)),
      ),
    );
    await pumpPage(tester);
    await tester.enterText(field(), _secret);
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPasteUnreadableTitle), findsOneWidget);
    expect(find.text(en.smsImportPasteEnterManually), findsOneWidget);
  });

  testWidgets('a storage failure shows the mapped message', (tester) async {
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('x')));
    await pumpPage(tester);
    await tester.enterText(field(), _secret);
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportPasteTryAgain), findsOneWidget);
  });

  group('RTL x LTR x light x dark', () {
    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('${locale.name}, ${theme.name}', (tester) async {
          await pumpPage(tester, locale: locale.locale, theme: theme.theme);
          expect(tester.takeException(), isNull);
          final l10n = lookupAppLocalizations(locale.locale);
          expect(find.text(l10n.smsImportPasteButton), findsOneWidget);
          expect(
            Directionality.of(tester.element(field())),
            locale.locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          expectTapTargets(tester, find.byType(PasteBankMessagePage));
        });
      }
    }
  });

  testWidgets('large text (200%) lays out without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(
      () => importPasted(
        text: any(named: 'text'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async => const Left(NotRecognizedFailure()));
    await pumpPage(
      tester,
      textScale: 2,
      locale: const Locale('ar'),
      tall: false,
    );
    expect(tester.takeException(), isNull);
    await tester.enterText(field(), 'x');
    await tester.pumpAndSettle();
    await tapVisible(tester, processButton());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text(
        lookupAppLocalizations(
          const Locale('ar'),
        ).smsImportPasteNotRecognizedTitle,
      ),
      findsOneWidget,
    );
  });
}
