import 'package:injectable/injectable.dart';

import '../entities/app_language.dart';
import '../repositories/settings_repository.dart';

/// Persists [language] as the user's explicit choice, owning the FR-008
/// retry policy (research.md Decision 7): the Clarifications answer is
/// "retry the save silently in the background and surface a non-blocking
/// notice only if it keeps failing" — a single immediate, synchronous
/// retry (no `Timer`/`Future.delayed`) satisfies "keeps failing" for a
/// local SQLite write without adding real-time dependencies that would
/// make `SettingsCubit` harder to unit test deterministically.
@injectable
class ChangeLanguage {
  const ChangeLanguage(this._repository);

  final SettingsRepository _repository;

  /// Returns whether persistence ultimately succeeded (after the retry, if
  /// the first attempt failed), so the caller can decide whether to
  /// surface a notice.
  Future<bool> call(AppLanguage language) async {
    final firstAttempt = await _repository.setLanguagePreference(language);
    if (firstAttempt.isRight()) {
      return true;
    }
    final retry = await _repository.setLanguagePreference(language);
    return retry.isRight();
  }
}
