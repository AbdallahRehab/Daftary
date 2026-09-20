import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

/// Resolves the currently persisted theme mode choice, or `null` if the
/// user has never explicitly chosen one yet — the caller combines this
/// with the FR-011 first-launch default of `AppThemeMode.system`.
@injectable
class GetThemeModePreference {
  const GetThemeModePreference(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, AppThemeMode?>> call() =>
      _repository.getThemeModePreference();
}
