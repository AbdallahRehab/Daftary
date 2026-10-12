/// Why a bank-message crypto operation could not run.
enum SmsCryptoError {
  /// The encryption or MAC key could not be read, created or verified in
  /// secure storage. Treat it as purged (FR-074a).
  keyUnavailable,

  /// The masked original could not be sealed (bad input to the cipher).
  sealFailed,
}

/// The only exception the SMS crypto adapters throw.
///
/// Content-free by construction: it carries an [SmsCryptoError] code and
/// nothing else, never message text, a key, a pending id or the text of an
/// underlying platform error (briefing rule 6). Callers map it to "raw text
/// unavailable" or a fixed failure.
class SmsCryptoException implements Exception {
  const SmsCryptoException(this.error);

  final SmsCryptoError error;

  @override
  String toString() => 'SmsCryptoException(${error.name})';
}
