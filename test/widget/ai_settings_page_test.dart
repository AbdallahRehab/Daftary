import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/l10n/app_localizations_ar.dart';
import 'package:daftary/features/ai_assistant/data/datasources/ai_provider_catalog_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/disable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/enable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/update_provider_credentials.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/pages/ai_settings_page.dart';
import 'package:daftary/features/ai_assistant/presentation/widgets/consent_disclosure_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSettings extends Mock implements GetAIAssistantSettings {}

class MockEnable extends Mock implements EnableAIAssistant {}

class MockDisable extends Mock implements DisableAIAssistant {}

class MockUpdateCredentials extends Mock implements UpdateProviderCredentials {}

/// T027/T063 — the setup page: masked key field, consent sheet gating
/// enable, the key never redisplayed, and disable returning to the full
/// setup form.
void main() {
  const key = 'sk-test-0123456789abcdef';
  final t0 = DateTime(2026, 9, 1);
  late MockGetSettings getSettings;
  late MockEnable enable;
  late MockDisable disable;
  late AIAssistantSettings current;

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    getSettings = MockGetSettings();
    enable = MockEnable();
    disable = MockDisable();
    current = AIAssistantSettings.disabled(updatedAt: t0);
    when(() => getSettings()).thenAnswer((_) async => Right(current));
    when(
      () => enable(
        providerId: any(named: 'providerId'),
        apiKey: any(named: 'apiKey'),
        consentAcceptedAt: any(named: 'consentAcceptedAt'),
      ),
    ).thenAnswer((_) async {
      current = AIAssistantSettings.enabled(
        providerId: AIProviderRegistry.openAiId,
        consentAcceptedAt: t0,
        updatedAt: t0,
      );
      return Right(current);
    });
    when(() => disable()).thenAnswer((_) async {
      current = AIAssistantSettings.disabled(updatedAt: t0);
      return const Right(unit);
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    final cubit = AISettingsCubit(
      getSettings,
      enable,
      disable,
      MockUpdateCredentials(),
      const AIProviderCatalogImpl(),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..load(),
          child: const AISettingsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder keyField() => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == 'Your API key',
  );

  Future<void> tapVisible(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndContinue(WidgetTester tester) async {
    await tester.tap(find.text('OpenAI'));
    await tester.enterText(keyField(), key);
    await tapVisible(tester, 'Continue');
  }

  testWidgets('opens in the setup state with a masked key field', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('The assistant is off'), findsOneWidget);
    for (final preset in AIProviderRegistry.presets) {
      expect(find.text(preset.displayName), findsOneWidget);
    }
    expect(find.text('Custom provider'), findsOneWidget);
    final field = tester.widget<TextField>(keyField());
    expect(field.obscureText, isTrue);
    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
  });

  testWidgets('Continue shows the disclosure; declining leaves it off', (
    tester,
  ) async {
    await pump(tester);
    await fillAndContinue(tester);

    expect(find.byType(ConsentDisclosureSheet), findsOneWidget);
    await tapVisible(tester, 'Not now');

    expect(find.text('The assistant is off'), findsOneWidget);
    verifyZeroInteractions(enable);
  });

  testWidgets('accepting enables it, and the key is never shown again', (
    tester,
  ) async {
    await pump(tester);
    await fillAndContinue(tester);
    await tapVisible(tester, 'I agree, turn it on');

    expect(find.text('The assistant is on'), findsOneWidget);
    expect(find.text('API key: saved securely (hidden)'), findsOneWidget);
    expect(keyField(), findsNothing);
    expect(find.textContaining(key), findsNothing);
  });

  testWidgets('turning it off asks first, then returns to the full, empty '
      'setup form (T063)', (tester) async {
    await pump(tester);
    await fillAndContinue(tester);
    await tapVisible(tester, 'I agree, turn it on');

    await tapVisible(tester, 'Turn off assistant');
    expect(find.text('Turn off the assistant?'), findsOneWidget);
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();

    verify(() => disable()).called(1);
    expect(find.text('The assistant is off'), findsOneWidget);
    final field = tester.widget<TextField>(keyField());
    expect(field.controller!.text, isEmpty);
    final openAiChip = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('OpenAI'), matching: find.byType(ChoiceChip)),
    );
    expect(openAiChip.selected, isFalse);
  });

  // T079 — section titles are exposed as headings.
  testWidgets('section titles are semantic headers', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    for (final title in ['The assistant is off', 'Provider', 'API key']) {
      final node = tester.getSemantics(find.text(title));
      expect(
        node.getSemanticsData().flagsCollection.isHeader,
        isTrue,
        reason: title,
      );
    }
    handle.dispose();
  });

  // T081 — the settings form in Arabic (RTL), in both themes, including
  // the custom-provider fields and the enabled summary.
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('ar RTL ($name): setup, custom form and enabled summary '
        'render without overflow', (tester) async {
      final ar = AppLocalizationsAr();
      await pump(tester, locale: const Locale('ar'), theme: theme);

      expect(
        Directionality.of(tester.element(find.byType(AISettingsView))),
        TextDirection.rtl,
      );
      expect(find.text(ar.aiSettingsIntroTitle), findsOneWidget);

      await tapVisible(tester, ar.aiSettingsProviderCustom);
      expect(find.text(ar.aiSettingsCustomBaseUrlLabel), findsOneWidget);
      // URLs, model ids and keys stay LTR inside the RTL form.
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.textDirection, TextDirection.ltr);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('OpenAI'));
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText == ar.aiSettingsApiKeyLabel,
        ),
        key,
      );
      await tapVisible(tester, ar.aiSettingsContinueAction);
      await tapVisible(tester, ar.aiConsentAcceptAction);

      expect(find.text(ar.aiSettingsEnabledTitle), findsOneWidget);
      expect(find.text(ar.aiSettingsDisableAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
