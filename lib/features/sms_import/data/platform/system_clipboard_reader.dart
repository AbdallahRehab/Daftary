import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/services/clipboard_reader.dart';

/// Reads plain text from the system clipboard. Called only from the Paste
/// button tap (FR-015): nothing in this feature reads the clipboard on
/// open, resume or focus.
@LazySingleton(as: ClipboardReader)
class SystemClipboardReader implements ClipboardReader {
  const SystemClipboardReader();

  @override
  Future<String?> readText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      return text == null || text.isEmpty ? null : text;
    } on PlatformException {
      // A clipboard the platform cannot read counts as empty. The
      // exception is never inspected or kept.
      return null;
    }
  }
}
