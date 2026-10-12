import 'package:injectable/injectable.dart';

import '../../domain/services/bank_reference_policy.dart';
import 'sms_parser_registry.dart';

/// [BankReferencePolicy] over the shipped profiles: a bank's
/// `refIsUnique` rule-set property (FR-059b). The generic profile and an
/// unknown bank are never unique.
@LazySingleton(as: BankReferencePolicy)
class RegistryBankReferencePolicy implements BankReferencePolicy {
  RegistryBankReferencePolicy({@ignoreParam SmsParserRegistry? registry})
    : _registry = registry ?? SmsParserRegistry.standard;

  final SmsParserRegistry _registry;

  @override
  bool refIsUnique(String bankId) {
    for (final profile in _registry.profiles) {
      if (profile.id == bankId) return profile.refIsUnique;
    }
    return false;
  }
}
