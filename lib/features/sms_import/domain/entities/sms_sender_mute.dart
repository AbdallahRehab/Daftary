import 'package:equatable/equatable.dart';

/// The canonical form of an SMS sender id: trimmed, every whitespace
/// removed, upper-case (FR-020). Used for the allow-list, mutes and the
/// pending row's `senderId`.
String canonicalSmsSenderId(String senderId) =>
    senderId.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// A sender the user chose to stop suggestions from (FR-065).
///
/// [senderId] is the primary key and is always canonical upper-case: the
/// constructor stores [canonicalSmsSenderId] of what it is given, so two
/// spellings of one sender can never become two mutes.
class SmsSenderMute extends Equatable {
  SmsSenderMute({required String senderId, required this.createdAt})
    : senderId = canonicalSmsSenderId(senderId);

  final String senderId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [senderId, createdAt];
}
