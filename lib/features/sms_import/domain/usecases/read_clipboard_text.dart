import 'package:injectable/injectable.dart';

import '../services/clipboard_reader.dart';

/// Reads the clipboard for the Paste screen (domain-interfaces §5.2,
/// FR-015). Called only from the Paste button's `onPressed`: nothing in
/// the feature reads the clipboard on open, resume, focus or in the
/// background. `null` means empty or non-text (the "nothing to paste"
/// state, not a failure).
@injectable
class ReadClipboardText {
  ReadClipboardText(this._clipboard);

  final ClipboardReader _clipboard;

  Future<String?> call() => _clipboard.readText();
}
