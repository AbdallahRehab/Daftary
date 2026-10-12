import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/merchant_category_mapping.dart';
import '../repositories/sms_import_settings_repository.dart';

/// The learned merchant -> category mappings for the "Learned categories"
/// screen (FR-056). A mapping whose category was archived or deleted is
/// still listed (it is skipped at suggestion time and left in place); the
/// screen shows it as "category removed".
@injectable
class WatchLearnedMappings {
  WatchLearnedMappings(this._settings);

  final SmsImportSettingsRepository _settings;

  Stream<Either<Failure, List<MerchantCategoryMapping>>> call() =>
      _settings.watchMappings();
}
