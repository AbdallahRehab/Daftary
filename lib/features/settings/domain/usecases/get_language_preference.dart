import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/app_language.dart';
import '../repositories/settings_repository.dart';

/// Resolves the currently persisted language choice, or `null` if the user
/// has never explicitly chosen one yet — the caller combines this with the
/// device-locale fallback for FR-009's first-launch default, which is why
/// this isn't a bare repository passthrough.
@injectable
class GetLanguagePreference {
  const GetLanguagePreference(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, AppLanguage?>> call() =>
      _repository.getLanguagePreference();
}
