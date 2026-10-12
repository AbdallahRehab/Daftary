import 'package:flutter/widgets.dart';

/// Unicode isolates for identifiers inside localized text (FR-091,
/// ui-contract §8.4), so digits and punctuation of a masked card, a sender
/// id or an amount with its code never reorder inside an Arabic sentence.
abstract final class BidiIsolate {
  /// LEFT-TO-RIGHT ISOLATE ... POP DIRECTIONAL ISOLATE: for tokens known to
  /// be left-to-right (masked card, sender id, amount with currency code).
  static String ltr(String text) => '\u2066$text\u2069';

  /// FIRST STRONG ISOLATE ... POP DIRECTIONAL ISOLATE: for names whose
  /// direction is not known (merchants, counterparties).
  static String auto(String text) => '\u2068$text\u2069';
}

/// A [Text] whose content is isolated from the surrounding direction.
class BidiText extends StatelessWidget {
  /// An LTR token (masked card, amount with code, sender id).
  const BidiText.ltr(this.text, {super.key, this.style, this.maxLines})
    : _auto = false;

  /// A name in either script; its first strong character decides.
  const BidiText.auto(this.text, {super.key, this.style, this.maxLines})
    : _auto = true;

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final bool _auto;

  @override
  Widget build(BuildContext context) {
    return Text(
      _auto ? BidiIsolate.auto(text) : BidiIsolate.ltr(text),
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}
