import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/glass_appearance.dart';
import '../../domain/entities/glass_level.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_dao.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dao);

  final SettingsDao _dao;

  @override
  Future<Either<Failure, AppLanguage?>> getLanguagePreference() async {
    try {
      final row = await _dao.getPreference();
      if (row == null) {
        return const Right(null);
      }
      return Right(_parse(row.languageCode));
    } catch (e) {
      return Left(CacheFailure('Failed to load language preference: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setLanguagePreference(
    AppLanguage language,
  ) async {
    try {
      await _dao.upsertPreference(
        languageCode: language.code,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save language preference: $e'));
    }
  }

  /// An unrecognized `languageCode` (only possible via external DB
  /// tampering, never a normal app write — data-model.md Validation rules)
  /// is treated as "no valid preference" rather than thrown.
  AppLanguage? _parse(String languageCode) {
    for (final language in AppLanguage.values) {
      if (language.code == languageCode) {
        return language;
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, AppThemeMode?>> getThemeModePreference() async {
    try {
      final row = await _dao.getPreference();
      final themeMode = row?.themeMode;
      if (themeMode == null) {
        return const Right(null);
      }
      return Right(_parseThemeMode(themeMode));
    } catch (e) {
      return Left(CacheFailure('Failed to load theme mode preference: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setThemeModePreference(
    AppThemeMode mode,
  ) async {
    try {
      await _dao.upsertPreference(
        themeMode: mode.value,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save theme mode preference: $e'));
    }
  }

  /// An unrecognized stored `themeMode` (only possible via external DB
  /// tampering, never a normal app write) is treated as "no valid
  /// preference" rather than thrown — mirrors `_parse` for `AppLanguage`.
  AppThemeMode? _parseThemeMode(String themeMode) {
    for (final mode in AppThemeMode.values) {
      if (mode.value == themeMode) {
        return mode;
      }
    }
    return null;
  }

  @override
  Future<Either<Failure, GlassAppearance?>>
  getGlassAppearancePreference() async {
    try {
      final row = await _dao.getPreference();
      if (row == null) {
        return const Right(null);
      }
      // Per-field fallback (data-model.md Validation rules): a NULL or
      // unrecognized column resolves to that field's default only.
      const defaults = GlassAppearance.defaults;
      return Right(
        GlassAppearance(
          enabled: row.glassEnabled ?? defaults.enabled,
          transparency:
              _parseGlassLevel(row.glassTransparency) ?? defaults.transparency,
          intensity: _parseGlassLevel(row.glassIntensity) ?? defaults.intensity,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure('Failed to load glass appearance preference: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> setGlassAppearancePreference(
    GlassAppearance appearance,
  ) async {
    try {
      // One upsert for all three fields, so each save is an atomic
      // snapshot (020 research.md Decision 8).
      await _dao.upsertPreference(
        glassEnabled: appearance.enabled,
        glassTransparency: appearance.transparency.value,
        glassIntensity: appearance.intensity.value,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Failed to save glass appearance preference: $e'),
      );
    }
  }

  /// A `NULL` or unrecognized stored glass level (the latter only possible
  /// via external DB tampering, never a normal app write) is treated as "no
  /// valid value" rather than thrown — mirrors `_parseThemeMode`.
  GlassLevel? _parseGlassLevel(String? value) {
    for (final level in GlassLevel.values) {
      if (level.value == value) {
        return level;
      }
    }
    return null;
  }
}
