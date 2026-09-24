import 'package:equatable/equatable.dart';

/// One browsable topic of the bundled content library (data-model.md).
/// [id] is a stable, language-independent navigation key; [title] and
/// [shortDescription] are already localized for the active app language.
class EducationCategory extends Equatable {
  const EducationCategory({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.articleIds,
  });

  final String id;
  final String title;
  final String shortDescription;

  /// The category's articles, in their authored display order.
  final List<String> articleIds;

  @override
  List<Object?> get props => [id, title, shortDescription, articleIds];
}
