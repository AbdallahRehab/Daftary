import 'package:injectable/injectable.dart';

import '../entities/glass_appearance.dart';
import '../repositories/settings_repository.dart';

/// Persists a [GlassAppearance] snapshot as the user's explicit choice, owning the
/// retry policy: a single immediate, synchronous retry (no
/// `Timer`/`Future.delayed`) — identical to `ChangeThemeMode`.
@injectable
class ChangeGlassAppearance {
  const ChangeGlassAppearance(this._repository);

  final SettingsRepository _repository;

  /// Returns whether persistence ultimately succeeded (after the retry, if
  /// the first attempt failed), so the caller can decide whether to
  /// surface a notice.
  Future<bool> call(GlassAppearance appearance) async {
    final firstAttempt = await _repository.setGlassAppearancePreference(
      appearance,
    );
    if (firstAttempt.isRight()) {
      return true;
    }
    final retry = await _repository.setGlassAppearancePreference(appearance);
    return retry.isRight();
  }
}
