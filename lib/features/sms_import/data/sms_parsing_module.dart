import 'package:injectable/injectable.dart';

import '../../../core/date/app_clock.dart';
import '../domain/services/fingerprint_normalizer.dart';
import '../domain/services/sms_masker.dart';
import '../domain/services/sms_message_parser.dart';
import '../domain/services/sms_message_splitter.dart';
import '../domain/services/sms_text_normalizer.dart';
import 'parsing/fingerprint_normalizer.dart';
import 'parsing/rule_based_sms_parser.dart';
import 'parsing/sms_masker_impl.dart';
import 'parsing/sms_message_splitter.dart';
import 'parsing/sms_text_normalizer.dart';

/// Registers the pure parsing services by their domain ports.
///
/// A module rather than annotations on the classes: the frozen
/// `FingerprintNormalizerV1` may import nothing but `NumeralParser` and its
/// port (an import guard pins that, FR-023), and the parser files stay
/// free of DI concerns. Each class is stateless or immutable, so one
/// instance serves the app.
@module
abstract class SmsParsingModule {
  @lazySingleton
  SmsMessageParser smsMessageParser(AppClock clock) =>
      RuleBasedSmsParser(clock: clock);

  @lazySingleton
  SmsTextNormalizer get smsTextNormalizer => const SmsTextNormalizerImpl();

  @lazySingleton
  SmsMasker get smsMasker => const SmsMaskerImpl();

  @lazySingleton
  SmsMessageSplitter get smsMessageSplitter => SmsMessageSplitterImpl();

  @lazySingleton
  FingerprintNormalizer get fingerprintNormalizer =>
      const FingerprintNormalizerV1();
}
