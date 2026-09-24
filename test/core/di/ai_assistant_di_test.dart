import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:daftary/features/ai_assistant/domain/services/ai_service.dart';
import 'package:daftary/features/ai_assistant/domain/tools/ai_tool_registry.dart';
import 'package:daftary/features/ai_assistant/domain/tools/tool_catalog.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/ask_financial_question.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/get_proactive_observation.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T024/T040/T055/T075 — the generated DI graph resolves every AI assistant
/// dependency. Only object construction happens: the real database is
/// swapped for an in-memory one, and nothing here touches the keychain or
/// the network (both are only used on a call, never at construction).
void main() {
  late AppDatabase db;

  setUp(() async {
    await configureDependencies();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt
      ..unregister<AppDatabase>()
      ..registerSingleton<AppDatabase>(db);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  test('resolves the AI assistant graph', () async {
    final registry = getIt<AIToolRegistry>();
    expect(registry.toolNames, aiToolCatalog.map((d) => d.name).toSet());
    expect(getIt<AIService>(), isNotNull);
    expect(getIt<AIAssistantRepository>(), isNotNull);
    expect(getIt<AskFinancialQuestion>(), isNotNull);
    expect(getIt<GetProactiveObservation>(), isNotNull);
    final cubit = getIt<AISettingsCubit>();
    await cubit.close();
  });
}
