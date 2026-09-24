import 'package:equatable/equatable.dart';

/// One bundled, read-only article (data-model.md). Its body is structured
/// as headed sections rather than one opaque blob so the UI renders
/// headings/paragraphs consistently without a markdown parser.
class EducationArticle extends Equatable {
  const EducationArticle({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.shortDescription,
    required this.bodySections,
  });

  final String id;
  final String categoryId;
  final String title;
  final String shortDescription;
  final List<ArticleSection> bodySections;

  @override
  List<Object?> get props => [
    id,
    categoryId,
    title,
    shortDescription,
    bodySections,
  ];
}

/// A part of an [EducationArticle]'s body — not independently addressable.
class ArticleSection extends Equatable {
  const ArticleSection({required this.paragraphs, this.heading});

  /// Optional — a plain paragraph section may omit it.
  final String? heading;
  final List<String> paragraphs;

  @override
  List<Object?> get props => [heading, paragraphs];
}
