import 'package:equatable/equatable.dart';

import '../../domain/entities/education_article.dart';
import '../../domain/entities/education_category.dart';

enum CategoryStatus { loading, success, failure }

/// Immutable state for `CategoryCubit` (constitution Principle IV).
class CategoryState extends Equatable {
  const CategoryState({
    this.status = CategoryStatus.loading,
    this.category,
    this.articles = const [],
    this.errorMessage,
  });

  final CategoryStatus status;
  final EducationCategory? category;

  /// The category's articles in authored order; the list screen shows only
  /// each one's title and short description (FR-003).
  final List<EducationArticle> articles;
  final String? errorMessage;

  CategoryState copyWith({
    CategoryStatus? status,
    EducationCategory? category,
    List<EducationArticle>? articles,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CategoryState(
      status: status ?? this.status,
      category: category ?? this.category,
      articles: articles ?? this.articles,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, category, articles, errorMessage];
}
