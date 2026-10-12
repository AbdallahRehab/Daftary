import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../services/sms_key_store.dart';

/// Deletes the bank-message encryption and MAC keys
/// (`sms_import.enc_key.v1`, `sms_import.mac_key.v1`) from secure storage
/// (data-model §10, domain-interfaces §5.4). Called by `DeleteAllUserData`
/// beside `PurgeAIAssistantCredentials`: the table wipe cannot reach secure
/// storage, and no key may outlive Delete all data.
///
/// Both deletes are always attempted. Any failure becomes one fixed,
/// content-free token; the underlying error is never passed on or logged.
@injectable
class PurgeSmsImportKeys {
  PurgeSmsImportKeys(this._keys);

  final SmsKeyStore _keys;

  static const Failure purgeFailed = CacheFailure(
    'sms_import_keys_purge_failed',
  );

  Future<Either<Failure, Unit>> call() async {
    try {
      await _keys.purge();
      return const Right(unit);
    } catch (_) {
      // Never inspected or kept.
      return const Left(purgeFailed);
    }
  }
}
