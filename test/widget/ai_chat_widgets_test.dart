import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/l10n/app_localizations_ar.dart';
import 'package:daftary/core/l10n/app_localizations_en.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/presentation/widgets/ai_failure_banner.dart';
import 'package:daftary/features/ai_assistant/presentation/widgets/chat_bubble.dart';
import 'package:daftary/features/ai_assistant/presentation/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T042/T067 (+ T079/T080/T081 checks): chat bubble direction-aware
/// alignment, typing indicator, and the five distinct failure banners in
/// both locales and both themes.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    bool disableAnimations = false,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 800),
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  Rect bubbleRect(WidgetTester tester, String text) {
    final box = find.ancestor(
      of: find.text(text),
      matching: find.byType(DecoratedBox),
    );
    return tester.getRect(box.first);
  }

  group('ChatBubble alignment follows reading direction (FR-021)', () {
    Widget bubbles() => const Column(
      children: [
        ChatBubble(text: 'question', isFromUser: true),
        ChatBubble(text: 'answer', isFromUser: false),
      ],
    );

    testWidgets('LTR: user on the right (end), assistant on the left', (
      tester,
    ) async {
      await pump(tester, bubbles());
      const width = 400.0;
      final user = bubbleRect(tester, 'question');
      final assistant = bubbleRect(tester, 'answer');
      expect(user.right, greaterThan(width - AppSpacing.md - 1));
      expect(user.left, greaterThan(width / 2));
      expect(assistant.left, lessThan(AppSpacing.md + 1));
      expect(assistant.right, lessThan(width / 2));
    });

    testWidgets('RTL: user on the left (end), assistant on the right', (
      tester,
    ) async {
      await pump(tester, bubbles(), locale: const Locale('ar'));
      const width = 400.0;
      final user = bubbleRect(tester, 'question');
      final assistant = bubbleRect(tester, 'answer');
      expect(user.left, lessThan(AppSpacing.md + 1));
      expect(user.right, lessThan(width / 2));
      expect(assistant.right, greaterThan(width - AppSpacing.md - 1));
      expect(assistant.left, greaterThan(width / 2));
    });

    testWidgets('long text wraps within the bubble without overflow', (
      tester,
    ) async {
      final long = List.filled(80, 'word').join(' ');
      await pump(tester, ChatBubble(text: long, isFromUser: false));
      expect(tester.takeException(), isNull);
      expect(bubbleRect(tester, long).width, lessThanOrEqualTo(400 * 0.82));
    });

    testWidgets('failed message is marked with icon + text, not color only', (
      tester,
    ) async {
      final message = AIMessage(
        id: 'm1',
        conversationId: 'c1',
        sender: MessageSender.user,
        content: 'How much on food?',
        status: MessageStatus.failed,
        failureReason: AIFailureReason.network,
        createdAt: DateTime(2026, 9, 1, 14, 5),
      );
      await pump(tester, ChatBubble.fromMessage(message));
      expect(find.text('How much on food?'), findsOneWidget);
      expect(
        find.text(AppLocalizationsEn().aiChatMessageFailedLabel),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('interrupted and observation labels render (ar)', (
      tester,
    ) async {
      final ar = AppLocalizationsAr();
      await pump(
        tester,
        const Column(
          children: [
            ChatBubble(text: 'q', isFromUser: true, isInterrupted: true),
            ChatBubble(text: 'obs', isFromUser: false, isObservation: true),
          ],
        ),
        locale: const Locale('ar'),
      );
      expect(find.text(ar.aiChatInterruptedLabel), findsOneWidget);
      expect(
        find.bySemanticsLabel(ar.aiObservationSemanticLabel),
        findsOneWidget,
      );
    });
  });

  group('TypingIndicator', () {
    testWidgets('exposes a localized semantics label and animates', (
      tester,
    ) async {
      await pump(tester, const TypingIndicator());
      expect(
        find.bySemanticsLabel(AppLocalizationsEn().aiChatTypingLabel),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('is static when reduced motion is requested', (tester) async {
      await pump(tester, const TypingIndicator(), disableAnimations: true);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('sits at the start edge in RTL', (tester) async {
      await pump(tester, const TypingIndicator(), locale: const Locale('ar'));
      final rect = tester.getRect(
        find
            .descendant(
              of: find.byType(TypingIndicator),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(rect.right, greaterThan(400 - AppSpacing.md - 1));
    });
  });

  group('AIFailureBanner (FR-017)', () {
    String messageFor(AppLocalizations l10n, AIFailureReason reason) =>
        switch (reason) {
          AIFailureReason.invalidApiKey => l10n.aiFailureInvalidApiKeyMessage,
          AIFailureReason.rateLimited => l10n.aiFailureRateLimitedMessage,
          AIFailureReason.network => l10n.aiFailureNetworkMessage,
          AIFailureReason.providerError => l10n.aiFailureProviderErrorMessage,
          AIFailureReason.unrecognizedResponse =>
            l10n.aiFailureUnrecognizedMessage,
        };

    for (final (locale, l10n) in [
      (const Locale('en'), AppLocalizationsEn() as AppLocalizations),
      (const Locale('ar'), AppLocalizationsAr()),
    ]) {
      testWidgets('each reason renders a distinct message and icon '
          '(${locale.languageCode})', (tester) async {
        final messages = <String>{};
        final icons = <IconData?>{};
        for (final reason in AIFailureReason.values) {
          await pump(
            tester,
            AIFailureBanner(reason: reason, onRetry: () {}, onUpdateKey: () {}),
            locale: locale,
          );
          final text = messageFor(l10n, reason);
          expect(find.text(text), findsOneWidget, reason: reason.name);
          messages.add(text);
          icons.add(
            tester
                .widget<Icon>(
                  find
                      .descendant(
                        of: find.byType(Row),
                        matching: find.byType(Icon),
                      )
                      .first,
                )
                .icon,
          );
        }
        expect(messages, hasLength(AIFailureReason.values.length));
        expect(icons, hasLength(AIFailureReason.values.length));
      });
    }

    testWidgets('invalid key offers update-key only, and it fires', (
      tester,
    ) async {
      var updated = 0;
      var retried = 0;
      await pump(
        tester,
        AIFailureBanner(
          reason: AIFailureReason.invalidApiKey,
          onRetry: () => retried++,
          onUpdateKey: () => updated++,
        ),
      );
      final en = AppLocalizationsEn();
      expect(find.text(en.aiFailureRetryAction), findsNothing);
      await tester.tap(find.text(en.aiFailureUpdateKeyAction));
      expect(updated, 1);
      expect(retried, 0);
    });

    testWidgets('other reasons offer retry, and it fires', (tester) async {
      var retried = 0;
      final en = AppLocalizationsEn();
      for (final reason in AIFailureReason.values.where(
        (r) => r != AIFailureReason.invalidApiKey,
      )) {
        await pump(
          tester,
          AIFailureBanner(reason: reason, onRetry: () => retried++),
        );
        expect(find.text(en.aiFailureUpdateKeyAction), findsNothing);
        await tester.tap(find.text(en.aiFailureRetryAction));
      }
      expect(retried, AIFailureReason.values.length - 1);
    });

    testWidgets('local storage variant renders its own copy and retry', (
      tester,
    ) async {
      var retried = 0;
      await pump(
        tester,
        AIFailureBanner.localStorage(onRetry: () => retried++),
        locale: const Locale('ar'),
      );
      final ar = AppLocalizationsAr();
      expect(find.text(ar.aiFailureLocalMessage), findsOneWidget);
      await tester.tap(find.text(ar.aiFailureRetryAction));
      expect(retried, 1);
    });
  });

  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('all widgets render in $name theme without exceptions', (
      tester,
    ) async {
      await pump(
        tester,
        Column(
          children: [
            const ChatBubble(text: 'q', isFromUser: true, isFailed: true),
            const ChatBubble(text: 'a', isFromUser: false, isObservation: true),
            const TypingIndicator(),
            for (final reason in AIFailureReason.values)
              AIFailureBanner(reason: reason, onRetry: () {}),
            const AIFailureBanner.localStorage(),
          ],
        ),
        theme: theme,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
