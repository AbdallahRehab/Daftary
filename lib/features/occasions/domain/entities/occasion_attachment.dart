import 'package:equatable/equatable.dart';

/// A photo linked to an [Occasion] as a whole — never to one participant's
/// contribution (research.md Decision 7). Only the local file path is stored;
/// the bytes live in the app's private sandboxed storage and are never
/// uploaded anywhere.
class OccasionAttachment extends Equatable {
  const OccasionAttachment({
    required this.id,
    required this.occasionId,
    required this.filePath,
    required this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String occasionId;

  /// A path to a file the app itself wrote into its own documents directory
  /// — never a transient OS picker cache path, which could disappear.
  final String filePath;
  final DateTime createdAt;

  /// Soft-delete tombstone; `null` means active (FR-017).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [id, occasionId, filePath, createdAt, deletedAt];
}
