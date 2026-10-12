import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../entities/parse_result.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_value_types.dart';
import '../services/sms_message_parser.dart';

/// The parse of one incoming message, by position. Transient; holds no
/// text of its own.
class ParseOutcome extends Equatable {
  const ParseOutcome({required this.index, required this.result});

  /// Position in the input list, from 0.
  final int index;
  final ParseResult result;

  @override
  List<Object?> get props => [index, result];

  @override
  String toString() => 'ParseOutcome(index: $index, result: $result)';
}

/// Parse and classify only; nothing is persisted (domain-interfaces §5.2).
/// Used by `SmsIngestionService` and by tests.
///
/// One hostile message never stops the others (FR-098): the parser never
/// throws, and anything that still escapes it becomes
/// `Unreadable(parserError)` without inspecting the error.
@injectable
class ParseMessages {
  ParseMessages(this._parser);

  final SmsMessageParser _parser;

  List<ParseOutcome> call({
    required List<RawIncoming> messages,
    required SmsSource source,
    ParserOptions options = const ParserOptions(),
  }) => [
    for (var i = 0; i < messages.length; i++)
      ParseOutcome(
        index: i,
        result: parseOne(messages[i], source: source, options: options),
      ),
  ];

  /// One message. Paste and share carry no sender and no receipt time
  /// (FR-020).
  ParseResult parseOne(
    RawIncoming message, {
    required SmsSource source,
    ParserOptions options = const ParserOptions(),
  }) {
    try {
      return _parser.parse(
        SmsParseInput(
          rawText: message.text,
          source: source,
          sender: source.hasSender ? message.sender : null,
          receivedAt: source.hasReceivedAt ? message.receivedAt : null,
        ),
        options: options,
      );
    } catch (_) {
      // Never inspected: it may carry message text.
      return const Unreadable(UnreadableReason.parserError);
    }
  }
}
