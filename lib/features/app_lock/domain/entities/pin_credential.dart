import 'package:equatable/equatable.dart';

/// The user's PIN, represented irreversibly (015 data-model.md): a
/// PBKDF2-HMAC-SHA256 [hash] of the raw PIN with a per-install random
/// [salt], plus the [iterations] used to derive it.
///
/// There is deliberately no raw-PIN field on this type — the raw value can
/// never be persisted or logged through it (FR-004/FR-016).
class PinCredential extends Equatable {
  const PinCredential({
    required this.hash,
    required this.salt,
    required this.iterations,
  });

  /// Base64-encoded derived key.
  final String hash;

  /// Base64-encoded random salt.
  final String salt;

  /// Stored with the hash so raising the default iteration count later never
  /// invalidates an existing credential.
  final int iterations;

  @override
  List<Object?> get props => [hash, salt, iterations];

  /// Never prints the hash or salt.
  @override
  String toString() => 'PinCredential(iterations: $iterations)';
}
