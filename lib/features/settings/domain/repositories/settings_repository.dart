import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_language.dart';
import '../entities/app_theme_mode.dart';
import '../entities/glass_appearance.dart';

/// Domain/Data boundary for the user's language, theme and Liquid Glass
/// preferences (constitution Principle VI). This feature has no network
/// layer, so this interface itself is the contract Presentation and Data
/// both depend on.
abstract class SettingsRepository {
  /// The persisted language choice, or `null` if the user has never
  /// explicitly chosen one yet (FR-009's "no row" case — first launch, or
  /// first launch after upgrading from a version that predates this table).
  Future<Either<Failure, AppLanguage?>> getLanguagePreference();

  /// Persists [language] as the user's explicit choice. The caller
  /// (`ChangeLanguage`) owns the FR-008 retry-once-then-flag-non-blocking-
  /// failure policy — this method itself simply reports success/failure
  /// of a single write attempt.
  Future<Either<Failure, Unit>> setLanguagePreference(AppLanguage language);

  /// The persisted theme mode choice, or `null` if the user has never
  /// explicitly chosen one yet (data-model.md Validation rules — no row, a
  /// `NULL` column, or an unrecognized stored value all resolve to `null`).
  Future<Either<Failure, AppThemeMode?>> getThemeModePreference();

  /// Persists [mode] as the user's explicit choice. The caller
  /// (`ChangeThemeMode`) owns the retry-once-then-flag-non-blocking-failure
  /// policy — this method itself simply reports success/failure of a
  /// single write attempt.
  Future<Either<Failure, Unit>> setThemeModePreference(AppThemeMode mode);

  /// The persisted glass preference with per-field defaults applied, or
  /// `null` when no settings row exists at all (020
  /// contracts/settings_repository.md).
  Future<Either<Failure, GlassAppearance?>> getGlassAppearancePreference();

  /// Persists all three glass fields as one snapshot. The caller
  /// (`ChangeGlassAppearance`) owns the retry-once policy. This method
  /// reports the outcome of a single write attempt.
  Future<Either<Failure, Unit>> setGlassAppearancePreference(
    GlassAppearance appearance,
  );
}
