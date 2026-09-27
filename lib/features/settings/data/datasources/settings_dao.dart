import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/app_language.dart';

/// Direct `drift` access to the single-row `AppSettings` table
/// (data-model.md: the row id is always the fixed constant `'singleton'`).
@injectable
class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  static const _singletonId = 'singleton';

  Future<AppSetting?> getPreference() => (_db.select(
    _db.appSettings,
  )..where((t) => t.id.equals(_singletonId))).getSingleOrNull();

  /// Merges [languageCode]/[themeMode] and the three glass columns into the
  /// existing row rather than overwriting it wholesale, so a theme-only
  /// write never clobbers the persisted language and vice versa
  /// (research.md Decision 3), and a glass write never clobbers
  /// language/theme and vice versa (020 research.md Decision 8).
  Future<void> upsertPreference({
    String? languageCode,
    String? themeMode,
    bool? glassEnabled,
    String? glassTransparency,
    String? glassIntensity,
    required int updatedAt,
  }) async {
    final existing = await getPreference();
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: _singletonId,
            languageCode:
                languageCode ??
                existing?.languageCode ??
                AppLanguage.english.code,
            themeMode: Value(themeMode ?? existing?.themeMode),
            glassEnabled: Value(glassEnabled ?? existing?.glassEnabled),
            glassTransparency: Value(
              glassTransparency ?? existing?.glassTransparency,
            ),
            glassIntensity: Value(glassIntensity ?? existing?.glassIntensity),
            updatedAt: updatedAt,
          ),
        );
  }
}
