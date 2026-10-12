import 'package:equatable/equatable.dart';

/// Whether this build and platform can read the SMS inbox (research
/// Decision 3). There is no compile-time const: [readSmsDeclared] comes
/// from the platform channel, and domain code reads availability only
/// through `GetSmsCapability`.
class SmsCapability extends Equatable {
  const SmsCapability({required this.readSmsDeclared, required this.isAndroid});

  /// No inbox access: iOS, macOS, or an Android build without READ_SMS.
  static const SmsCapability unavailable = SmsCapability(
    readSmsDeclared: false,
    isAndroid: false,
  );

  /// READ_SMS appears in the installed package's requested permissions.
  final bool readSmsDeclared;
  final bool isAndroid;

  /// `readSmsDeclared && isAndroid`.
  bool get available => readSmsDeclared && isAndroid;

  /// Sharing text into the app works on every Android build, with or
  /// without the SMS capability.
  bool get canReceiveShares => isAndroid;

  @override
  List<Object?> get props => [readSmsDeclared, isAndroid];
}
