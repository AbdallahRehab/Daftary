/// Reads the clipboard. Called only from the Paste button tap (FR-015).
abstract class ClipboardReader {
  /// `null` for an empty or non-text clipboard.
  Future<String?> readText();
}
