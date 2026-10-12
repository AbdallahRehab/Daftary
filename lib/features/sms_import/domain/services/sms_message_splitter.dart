import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';

/// Splits pasted or shared text into messages (FR-017, FR-017a,
/// parser-contract §3). Pure.
abstract class SmsMessageSplitter {
  /// `Left(InputTooLargeFailure)` over 10,000 characters or 50 messages;
  /// nothing is stored in that case.
  Either<Failure, List<SplitMessage>> split(String text);
}

/// One message cut from a paste; transient.
class SplitMessage extends Equatable {
  const SplitMessage({required this.text, required this.index});

  /// Never logged, never in [toString].
  final String text;

  /// Position in the paste, from 0.
  final int index;

  @override
  List<Object?> get props => [text, index];

  @override
  String toString() => 'SplitMessage(index: $index, length: ${text.length})';
}
