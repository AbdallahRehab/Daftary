import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/services/sms_message_splitter.dart';
import 'sms_envelope_rules.dart';
import 'sms_parser_registry.dart';
import 'sms_text_normalizer.dart';

/// Splits pasted or shared text into messages (FR-017, FR-017a,
/// parser-contract §3). Pure; never logs.
///
/// 1. Input over 10,000 UTF-16 code units is rejected before anything else
///    (`InputTooLargeFailure(characters)`), measured on the raw input so a
///    Kotlin-side truncation at 10,001 is always detected.
/// 2. E0: `\r\n`, `\r`, U+2028 and U+2029 become `\n`.
/// 3. Runs of blank lines and E5 separator lines end a chunk.
/// 4. Envelope headers (E1-E4, `SmsEnvelopeRules`) are stripped in header
///    position; a header of the same shape inside a chunk starts a new
///    message only when the chunk itself began with that shape.
/// 5. Inside a message, every line matching a profile `messageStart`
///    starts a new message when two or more such lines exist.
/// 6. More than 50 messages: `InputTooLargeFailure(messages)`.
///
/// Empty messages are dropped silently. A single message longer than
/// 4,000 characters is passed through; the parser reports it as
/// `Unreadable(tooLong)`.
class SmsMessageSplitterImpl implements SmsMessageSplitter {
  SmsMessageSplitterImpl({SmsParserRegistry? registry})
    : _registry = registry ?? SmsParserRegistry.standard;

  final SmsParserRegistry _registry;

  @override
  Either<Failure, List<SplitMessage>> split(String text) {
    if (text.length > InputLimit.characters.max) {
      return const Left(InputTooLargeFailure(InputLimit.characters));
    }
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u{2028}', '\n')
        .replaceAll('\u{2029}', '\n')
        .split('\n');

    final messages = <String>[];
    var chunk = <String>[];
    void flush() {
      if (chunk.isNotEmpty) messages.addAll(_splitChunk(chunk));
      chunk = <String>[];
    }

    for (final line in lines) {
      if (SmsEnvelopeRules.isBlank(line) ||
          SmsEnvelopeRules.isSeparator(line)) {
        flush();
      } else {
        chunk.add(line);
      }
    }
    flush();

    final kept = [
      for (final message in messages)
        if (!SmsEnvelopeRules.isBlank(message)) message,
    ];
    if (kept.length > InputLimit.messages.max) {
      return const Left(InputTooLargeFailure(InputLimit.messages));
    }
    return Right([
      for (var i = 0; i < kept.length; i++)
        SplitMessage(text: kept[i], index: i),
    ]);
  }

  List<String> _splitChunk(List<String> lines) {
    final first = _headerAt(lines, 0);
    final segments = <List<String>>[];
    if (first == null) {
      segments.add(lines);
    } else {
      var current = <String>[...first.apply(lines, 0)];
      var i = first.consumed(lines, 0);
      var bodyLines = current.isEmpty ? 0 : 1;
      while (i < lines.length) {
        final header = bodyLines > 0 ? _headerAt(lines, i) : null;
        if (header != null && header.shape == first.shape) {
          segments.add(current);
          current = [...header.apply(lines, i)];
          bodyLines = current.isEmpty ? 0 : 1;
          i = header.consumed(lines, i);
          continue;
        }
        current.add(lines[i]);
        bodyLines++;
        i++;
      }
      segments.add(current);
    }
    return [
      for (final segment in segments) ..._splitOnMessageStart(segment),
    ].map(_join).toList();
  }

  /// The header at line [i], if one is there and a body follows it.
  _Header? _headerAt(List<String> lines, int i) {
    final bracketBody = SmsEnvelopeRules.stripBracketPrefix(
      lines[i],
      registry: _registry,
    );
    if (bracketBody != null) {
      final hasBody = bracketBody.trim().isNotEmpty || i + 1 < lines.length;
      return hasBody ? _Header('E4', 0, bracketBody) : null;
    }
    EnvelopeHeader kindAt(int k) => k < lines.length
        ? SmsEnvelopeRules.classify(lines[k], registry: _registry)
        : EnvelopeHeader.none;
    final k0 = kindAt(i);
    if (k0 == EnvelopeHeader.none) return null;
    final k1 = kindAt(i + 1);
    _Header? header;
    if (k0 == EnvelopeHeader.senderStamp) {
      header = _Header('E3', 1, null);
    } else if (k0 == EnvelopeHeader.stamp && k1 == EnvelopeHeader.sender) {
      header = _Header('E2E1', 2, null);
    } else if (k0 == EnvelopeHeader.stamp) {
      header = _Header('E2', 1, null);
    } else if ((k0 == EnvelopeHeader.sender ||
            k0 == EnvelopeHeader.senderShape) &&
        k1 == EnvelopeHeader.stamp) {
      header = _Header('E1E2', 2, null);
    } else if (k0 == EnvelopeHeader.sender) {
      header = _Header('E1', 1, null);
    }
    if (header == null || i + header.lines >= lines.length) return null;
    return header;
  }

  List<List<String>> _splitOnMessageStart(List<String> segment) {
    final starts = _registry.profiles
        .map((p) => p.messageStart)
        .whereType<RegExp>()
        .toList();
    if (starts.isEmpty) return [segment];
    bool isStart(String line) {
      final folded = SmsTextNormalizerImpl.fold(line);
      return starts.any((s) => s.hasMatch(folded));
    }

    if (segment.where(isStart).length < 2) return [segment];
    final out = <List<String>>[];
    var current = <String>[];
    for (final line in segment) {
      if (isStart(line) && current.isNotEmpty) {
        out.add(current);
        current = <String>[];
      }
      current.add(line);
    }
    out.add(current);
    return out;
  }

  static String _join(List<String> lines) => lines.join('\n').trim();
}

/// A header found at some line: its shape, how many whole lines it takes,
/// and (E4) the kept body text of its own line.
class _Header {
  const _Header(this.shape, this.lines, this.bracketBody);

  final String shape;
  final int lines;
  final String? bracketBody;

  /// The body lines that remain from the header's own lines.
  List<String> apply(List<String> all, int i) =>
      bracketBody == null || bracketBody!.trim().isEmpty ? [] : [bracketBody!];

  /// The index of the first line after the header.
  int consumed(List<String> all, int i) =>
      i + (bracketBody == null ? lines : 1);
}
