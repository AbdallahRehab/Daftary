import 'dart:async';
import 'dart:io';

import 'package:daftary/features/ai_assistant/data/datasources/ai_provider_catalog_impl.dart';
import 'package:daftary/features/ai_assistant/data/services/ai_provider_registry.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/disable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/enable_ai_assistant.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/update_provider_credentials.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ai_assistant_harness.dart';

/// A recognisable sentinel: if it shows up anywhere, the key leaked.
const _sentinelKey = 'sk-SENTINEL-do-not-leak-9f8e7d6c5b4a';

/// T084 (constitution Principle XII, spec FR-004) — the API key never
/// appears in logs, printed output, emitted state, `toString`, failure
/// messages, or anything the data export produces.
///
/// `AIServiceImpl`'s own failure paths (including a provider echoing the
/// key back) are covered in `ai_service_impl_test.dart`; the full-deletion
/// key purge in `delete_all_user_data_test.dart`.
void main() {
  group('runtime', () {
    late AIAssistantHarness h;
    late AISettingsCubit cubit;
    final printed = <String>[];
    final states = <AISettingsState>[];
    DebugPrintCallback? originalDebugPrint;

    setUp(() {
      h = AIAssistantHarness.open();
      cubit = AISettingsCubit(
        GetAIAssistantSettings(h.repository),
        EnableAIAssistant(h.repository),
        DisableAIAssistant(h.repository),
        UpdateProviderCredentials(h.repository),
        const AIProviderCatalogImpl(),
      );
      printed.clear();
      states.clear();
      cubit.stream.listen(states.add);
      originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    });
    tearDown(() async {
      debugPrint = originalDebugPrint!;
      await cubit.close();
      await h.close();
    });

    /// Runs [body] with `print` captured as well as `debugPrint`.
    /// Also lets the cubit's (asynchronous) stream deliver every state.
    Future<void> capturing(Future<void> Function() body) async {
      await runZoned(
        body,
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    void expectNoLeak() {
      for (final state in states) {
        expect(state.toString(), isNot(contains(_sentinelKey)));
        expect(state.failure?.message ?? '', isNot(contains(_sentinelKey)));
      }
      expect(cubit.toString(), isNot(contains(_sentinelKey)));
      expect(printed.join('\n'), isNot(contains(_sentinelKey)));
      expect(h.store.log.join('\n'), isNot(contains(_sentinelKey)));
    }

    test(
      'a full enable → change key → disable flow never exposes the key',
      () async {
        await capturing(() async {
          await cubit.load();
          cubit
            ..presetSelected(AIProviderRegistry.openAiId)
            ..apiKeyChanged(_sentinelKey)
            ..requestEnable();
          await cubit.acceptConsent();
          expect(cubit.state.isEnabled, isTrue);
          // It really was stored — so its absence elsewhere means something.
          expect(h.store.keys.values, contains(_sentinelKey));

          cubit
            ..startEditingCredentials()
            ..apiKeyChanged('$_sentinelKey-2');
          await cubit.submitCredentialsUpdate();
          await cubit.disable();
        });

        expect(cubit.state.isEnabled, isFalse);
        expect(h.store.keys, isEmpty);
        expectNoLeak();
      },
    );

    test('a keychain failure while enabling never exposes the key', () async {
      h.store.failWrites = true;
      await capturing(() async {
        await cubit.load();
        cubit
          ..presetSelected(AIProviderRegistry.openAiId)
          ..apiKeyChanged(_sentinelKey)
          ..requestEnable();
        await cubit.acceptConsent();
      });

      expect(cubit.state.isEnabled, isFalse);
      expect(states.any((s) => s.failure != null), isTrue);
      expectNoLeak();
    });

    test('repository failures never carry the key', () async {
      h.store.failWrites = true;
      final enabled = await h.repository.enable(
        providerId: AIProviderRegistry.openAiId,
        apiKey: _sentinelKey,
        consentAcceptedAt: DateTime(2026, 9, 24),
      );
      final failure = enabled.getLeft().toNullable()!;
      expect(failure.message, isNot(contains(_sentinelKey)));
      expect(failure.toString(), isNot(contains(_sentinelKey)));
    });
  });

  group('source', () {
    /// Every Dart file under [dir], relative to the package root.
    List<File> dartFiles(String dir) => Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('the assistant feature never logs or prints anything', () {
      final logging = RegExp(
        r'\bprint\(|\bdebugPrint\(|\blog\(|developer\.log|\bLogger\b',
      );
      final offenders = [
        for (final file in dartFiles('lib/features/ai_assistant'))
          if (logging.hasMatch(file.readAsStringSync())) file.path,
      ];
      expect(offenders, isEmpty);
    });

    test('the data export reads neither secure storage nor any assistant '
        'setting', () {
      final forbidden = RegExp(
        r'ai_assistant|flutter_secure_storage|SecureCredentialStore|aiSettings',
      );
      final offenders = [
        for (final file in dartFiles('lib/features/data_privacy'))
          // Deletion legitimately purges the key; only export is checked.
          if (!file.path.contains('delete') &&
              forbidden.hasMatch(file.readAsStringSync()))
            file.path,
      ];
      expect(offenders, isEmpty);
    });
  });
}
