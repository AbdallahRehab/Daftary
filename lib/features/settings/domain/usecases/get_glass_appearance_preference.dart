import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/glass_appearance.dart';
import '../repositories/settings_repository.dart';

/// Resolves the currently persisted glass appearance (per-field defaults
/// already applied), or `null` if no settings row exists yet — the caller
/// combines this with `GlassAppearance.defaults`.
///
/// A thin pass-through, kept for symmetry with the existing
/// `Get…Preference` use cases so the cubit depends only on use cases
/// (020 plan.md Complexity Tracking).
@injectable
class GetGlassAppearancePreference {
  const GetGlassAppearancePreference(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, GlassAppearance?>> call() =>
      _repository.getGlassAppearancePreference();
}
