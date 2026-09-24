import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ai_assistant/data/datasources/ai_provider_catalog_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/disable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/enable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/update_provider_credentials.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/ai_assistant_harness.dart';

class MockGetSettings extends Mock implements GetAIAssistantSettings {}

class MockEnable extends Mock implements EnableAIAssistant {}

class MockDisable extends Mock implements DisableAIAssistant {}

class MockUpdateCredentials extends Mock implements UpdateProviderCredentials {}

/// T018 (+ T063) — `AISettingsCubit`: a key without consent never enables;
/// consent after a key does; validation errors; duplicate-submit guard;
/// and after a disable, re-enabling needs the whole flow again.
void main() {
  late MockGetSettings getSettings;
  late MockEnable enable;
  late MockDisable disable;
  late MockUpdateCredentials updateCredentials;

  const openAi = AIProviderRegistry.openAiId;
  const anthropic = AIProviderRegistry.anthropicId;
  final t0 = DateTime(2026, 9, 1);
  final disabled = AIAssistantSettings.disabled(updatedAt: t0);
  final enabled = AIAssistantSettings.enabled(
    providerId: openAi,
    consentAcceptedAt: t0,
    updatedAt: t0,
  );

  AISettingsCubit build() => AISettingsCubit(
    getSettings,
    enable,
    disable,
    updateCredentials,
    const AIProviderCatalogImpl(),
  );

  void stubEnableSucceeds() => when(
    () => enable(
      providerId: any(named: 'providerId'),
      apiKey: any(named: 'apiKey'),
      consentAcceptedAt: any(named: 'consentAcceptedAt'),
    ),
  ).thenAnswer((_) async => Right(enabled));

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    getSettings = MockGetSettings();
    enable = MockEnable();
    disable = MockDisable();
    updateCredentials = MockUpdateCredentials();
    when(() => getSettings()).thenAnswer((_) async => Right(disabled));
  });

  test('starts with every preset from the catalog on offer', () {
    final cubit = build();
    expect(
      [for (final p in cubit.state.presets) p.id],
      [for (final p in AIProviderRegistry.presets) p.id],
    );
    cubit.close();
  });

  blocTest<AISettingsCubit, AISettingsState>(
    'load: a fresh install opens in the disabled/setup state',
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, AISettingsStatus.ready);
      expect(cubit.state.isEnabled, isFalse);
      expect(cubit.state.showsCredentialForm, isTrue);
    },
  );

  blocTest<AISettingsCubit, AISettingsState>(
    'load failure is reported, not swallowed',
    setUp: () => when(
      () => getSettings(),
    ).thenAnswer((_) async => const Left(CacheFailure('db'))),
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, AISettingsStatus.loadFailure);
      expect(cubit.state.failure, const CacheFailure('db'));
    },
  );

  group('consent gating (FR-003)', () {
    blocTest<AISettingsCubit, AISettingsState>(
      'a provider and key without consent leave the assistant unusable — '
      'only the disclosure is requested',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..presetSelected(openAi)
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
      },
      verify: (cubit) {
        expect(cubit.state.status, AISettingsStatus.awaitingConsent);
        expect(cubit.state.isEnabled, isFalse);
        verifyNever(
          () => enable(
            providerId: any(named: 'providerId'),
            apiKey: any(named: 'apiKey'),
            consentAcceptedAt: any(named: 'consentAcceptedAt'),
          ),
        );
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'declining the disclosure keeps the assistant off and stores nothing',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..presetSelected(openAi)
          ..apiKeyChanged(testApiKey)
          ..requestEnable()
          ..declineConsent();
      },
      verify: (cubit) {
        expect(cubit.state.status, AISettingsStatus.ready);
        expect(cubit.state.isEnabled, isFalse);
        verifyZeroInteractions(enable);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'accepting consent after the key enables it, passing the typed key '
      'and a consent timestamp',
      setUp: stubEnableSucceeds,
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..presetSelected(openAi)
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
        await cubit.acceptConsent();
      },
      verify: (cubit) {
        expect(cubit.state.isEnabled, isTrue);
        expect(cubit.state.outcome, AISettingsOutcome.enabled);
        expect(cubit.state.hasApiKeyInput, isFalse);
        verify(
          () => enable(
            providerId: openAi,
            apiKey: testApiKey,
            consentAcceptedAt: any(named: 'consentAcceptedAt'),
          ),
        ).called(1);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'acceptConsent outside the consent step does nothing',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..presetSelected(openAi)
          ..apiKeyChanged(testApiKey);
        await cubit.acceptConsent();
      },
      verify: (cubit) {
        expect(cubit.state.isEnabled, isFalse);
        verifyZeroInteractions(enable);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'a custom provider is encoded from its base URL and model',
      setUp: stubEnableSucceeds,
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..customProviderSelected()
          ..customBaseUrlChanged('https://llm.example.com/v1')
          ..customModelChanged('model-1')
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
        await cubit.acceptConsent();
      },
      verify: (_) => verify(
        () => enable(
          providerId: AIProviderRegistry.encodeCustom(
            baseUrl: 'https://llm.example.com/v1',
            model: 'model-1',
          )!,
          apiKey: testApiKey,
          consentAcceptedAt: any(named: 'consentAcceptedAt'),
        ),
      ).called(1),
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'an enable failure keeps the assistant off, reports the failure, and '
      'lets the user try again',
      setUp: () => when(
        () => enable(
          providerId: any(named: 'providerId'),
          apiKey: any(named: 'apiKey'),
          consentAcceptedAt: any(named: 'consentAcceptedAt'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('keychain'))),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..presetSelected(openAi)
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
        await cubit.acceptConsent();
      },
      verify: (cubit) {
        expect(cubit.state.status, AISettingsStatus.ready);
        expect(cubit.state.isEnabled, isFalse);
        expect(cubit.state.failure, const CacheFailure('keychain'));
        expect(cubit.state.hasApiKeyInput, isTrue);
      },
    );
  });

  group('validation', () {
    blocTest<AISettingsCubit, AISettingsState>(
      'no provider and no key: both errors, no consent step',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.requestEnable();
      },
      verify: (cubit) {
        expect(cubit.state.status, AISettingsStatus.ready);
        expect(cubit.state.providerError, AIProviderInputError.required);
        expect(cubit.state.apiKeyError, AIApiKeyInputError.required);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'a malformed key is refused client-side',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..presetSelected(openAi)
          ..apiKeyChanged('sk 1')
          ..requestEnable();
      },
      verify: (cubit) {
        expect(cubit.state.apiKeyError, AIApiKeyInputError.malformed);
        expect(cubit.state.isAwaitingConsent, isFalse);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'a custom provider needs an https URL, then a model',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..customProviderSelected()
          ..customBaseUrlChanged('ftp://nope')
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
      },
      verify: (cubit) => expect(
        cubit.state.providerError,
        AIProviderInputError.invalidBaseUrl,
      ),
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'a custom provider with a valid URL but no model asks for the model',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..customProviderSelected()
          ..customBaseUrlChanged('https://llm.example.com/v1')
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
      },
      verify: (cubit) =>
          expect(cubit.state.providerError, AIProviderInputError.modelRequired),
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'editing a field clears its error',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..requestEnable()
          ..presetSelected(openAi)
          ..apiKeyChanged('x');
      },
      verify: (cubit) {
        expect(cubit.state.providerError, isNull);
        expect(cubit.state.apiKeyError, isNull);
      },
    );
  });

  group('duplicate submit guard', () {
    test('a rapid second accept while the first is in flight enables exactly '
        'once, and Save is disabled from the first tap', () async {
      final gate = Completer<Either<Failure, AIAssistantSettings>>();
      when(
        () => enable(
          providerId: any(named: 'providerId'),
          apiKey: any(named: 'apiKey'),
          consentAcceptedAt: any(named: 'consentAcceptedAt'),
        ),
      ).thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load();
      cubit
        ..presetSelected(openAi)
        ..apiKeyChanged(testApiKey)
        ..requestEnable();

      final first = cubit.acceptConsent();
      expect(cubit.state.isSubmitting, isTrue);
      final second = cubit.acceptConsent();
      cubit.requestEnable();
      gate.complete(Right(enabled));
      await Future.wait([first, second]);

      verify(
        () => enable(
          providerId: any(named: 'providerId'),
          apiKey: any(named: 'apiKey'),
          consentAcceptedAt: any(named: 'consentAcceptedAt'),
        ),
      ).called(1);
      expect(cubit.state.isEnabled, isTrue);
      await cubit.close();
    });

    test('a rapid second disable runs the use case once', () async {
      final gate = Completer<Either<Failure, Unit>>();
      when(() => getSettings()).thenAnswer((_) async => Right(enabled));
      when(() => disable()).thenAnswer((_) => gate.future);
      final cubit = build();
      await cubit.load();

      final first = cubit.disable();
      final second = cubit.disable();
      when(() => getSettings()).thenAnswer((_) async => Right(disabled));
      gate.complete(const Right(unit));
      await Future.wait([first, second]);

      verify(() => disable()).called(1);
      await cubit.close();
    });
  });

  group('update credentials', () {
    blocTest<AISettingsCubit, AISettingsState>(
      'editing preselects the current provider but never prefills the key',
      setUp: () =>
          when(() => getSettings()).thenAnswer((_) async => Right(enabled)),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.startEditingCredentials();
      },
      verify: (cubit) {
        expect(cubit.state.isEditingCredentials, isTrue);
        expect(cubit.state.selectedPresetId, openAi);
        expect(cubit.state.hasApiKeyInput, isFalse);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'saves the new provider/key without any consent step',
      setUp: () {
        when(() => getSettings()).thenAnswer((_) async => Right(enabled));
        when(
          () => updateCredentials(
            providerId: any(named: 'providerId'),
            apiKey: any(named: 'apiKey'),
          ),
        ).thenAnswer(
          (_) async => Right(
            AIAssistantSettings.enabled(
              providerId: anthropic,
              consentAcceptedAt: t0,
              updatedAt: t0,
            ),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..startEditingCredentials()
          ..presetSelected(anthropic)
          ..apiKeyChanged(otherTestApiKey);
        await cubit.submitCredentialsUpdate();
      },
      verify: (cubit) {
        verify(
          () =>
              updateCredentials(providerId: anthropic, apiKey: otherTestApiKey),
        ).called(1);
        expect(cubit.state.outcome, AISettingsOutcome.credentialsUpdated);
        expect(cubit.state.isEditingCredentials, isFalse);
        expect(cubit.state.settings!.providerId, anthropic);
        verifyZeroInteractions(enable);
      },
    );

    blocTest<AISettingsCubit, AISettingsState>(
      'an empty new key is refused before the use case',
      setUp: () =>
          when(() => getSettings()).thenAnswer((_) async => Right(enabled)),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.startEditingCredentials();
        await cubit.submitCredentialsUpdate();
      },
      verify: (cubit) {
        expect(cubit.state.apiKeyError, AIApiKeyInputError.required);
        verifyZeroInteractions(updateCredentials);
      },
    );
  });

  group('disable → re-enable needs the full flow (T063)', () {
    blocTest<AISettingsCubit, AISettingsState>(
      'after a disable the form is empty, and re-enabling requires provider '
      '+ key + consent again — it never silently resumes',
      setUp: () {
        var current = enabled;
        when(() => getSettings()).thenAnswer((_) async => Right(current));
        when(() => disable()).thenAnswer((_) async {
          current = disabled;
          return const Right(unit);
        });
        stubEnableSucceeds();
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.disable();

        expect(cubit.state.isEnabled, isFalse);
        expect(cubit.state.outcome, AISettingsOutcome.disabled);
        expect(cubit.state.selectedPresetId, isNull);
        expect(cubit.state.hasApiKeyInput, isFalse);

        // Nothing typed: "enable" cannot proceed at all.
        cubit.requestEnable();
        expect(cubit.state.isAwaitingConsent, isFalse);
        await cubit.acceptConsent();

        // Provider only: the key from before the disable is gone too.
        cubit
          ..presetSelected(openAi)
          ..requestEnable();
        expect(cubit.state.apiKeyError, AIApiKeyInputError.required);
        expect(cubit.state.isAwaitingConsent, isFalse);

        // Provider + key: still only the consent step.
        cubit
          ..apiKeyChanged(testApiKey)
          ..requestEnable();
        expect(cubit.state.isAwaitingConsent, isTrue);
        expect(cubit.state.isEnabled, isFalse);
      },
      verify: (_) => verifyZeroInteractions(enable),
    );

    test('structurally: after disable, the real repository holds no key and '
        'no consent, so nothing can be resumed', () async {
      final h = AIAssistantHarness.open();
      addTearDown(h.close);
      final cubit = AISettingsCubit(
        GetAIAssistantSettings(h.repository),
        EnableAIAssistant(h.repository),
        DisableAIAssistant(h.repository),
        UpdateProviderCredentials(h.repository),
        const AIProviderCatalogImpl(),
      );
      addTearDown(cubit.close);
      await cubit.load();
      cubit
        ..presetSelected(openAi)
        ..apiKeyChanged(testApiKey)
        ..requestEnable();
      await cubit.acceptConsent();
      expect(cubit.state.isEnabled, isTrue);

      await cubit.disable();

      final settings = (await h.repository.getSettings()).toNullable()!;
      expect(settings.isEnabled, isFalse);
      expect(settings.consentAcceptedAt, isNull);
      expect(settings.hasStoredCredential, isFalse);
      expect(h.store.keys, isEmpty);
      // And the update path — the only other way to store a key — refuses
      // a disabled assistant.
      final update = await h.repository.updateCredentials(
        providerId: openAi,
        apiKey: testApiKey,
      );
      expect(update.isLeft(), isTrue);
      expect(h.store.keys, isEmpty);
    });
  });

  test('neither the state nor the cubit ever prints the typed key', () async {
    final cubit = build();
    await cubit.load();
    cubit
      ..presetSelected(openAi)
      ..apiKeyChanged(testApiKey)
      ..requestEnable();

    expect(cubit.state.toString(), isNot(contains(testApiKey)));
    expect(cubit.toString(), isNot(contains(testApiKey)));
    await cubit.close();
  });
}
