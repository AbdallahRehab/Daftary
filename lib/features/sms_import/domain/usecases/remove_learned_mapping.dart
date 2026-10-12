import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../entities/merchant_category_mapping.dart';
import '../repositories/sms_import_settings_repository.dart';

/// Forgets one learned merchant -> category mapping (FR-056). Later
/// messages from that merchant fall back to the keyword rules, then
/// "other". No category and no saved record is touched.
@injectable
class RemoveLearnedMapping {
  RemoveLearnedMapping(this._settings);

  final SmsImportSettingsRepository _settings;

  Future<Either<Failure, Unit>> call(MerchantCategoryMapping mapping) =>
      _settings.removeMapping(mapping.merchantKey, mapping.entryType.dbValue);
}
