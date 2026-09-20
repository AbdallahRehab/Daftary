import 'package:injectable/injectable.dart';

import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

/// Persists [mode] as the user's explicit choice, owning the retry policy
/// (research.md Decision 9): a single immediate, synchronous retry (no
/// `Timer`/`Future.delayed`) mirrors `ChangeLanguage`'s FR-008 policy.
@injectable
class ChangeThemeMode {
  const ChangeThemeMode(this._repository);

  final SettingsRepository _repository;

  /// Returns whether persistence ultimately succeeded (after the retry, if
  /// the first attempt failed), so the caller can decide whether to
  /// surface a notice.
  Future<bool> call(AppThemeMode mode) async {
    final firstAttempt = await _repository.setThemeModePreference(mode);
    if (firstAttempt.isRight()) {
      return true;
    }
    final retry = await _repository.setThemeModePreference(mode);
    return retry.isRight();
  }
}
