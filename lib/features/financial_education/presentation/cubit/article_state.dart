import 'package:equatable/equatable.dart';

import '../../domain/entities/education_article.dart';

enum ArticleStatus { loading, success, failure }

/// Immutable state for `ArticleCubit` (constitution Principle IV).
class ArticleState extends Equatable {
  const ArticleState({
    this.status = ArticleStatus.loading,
    this.article,
    this.errorMessage,
  });

  final ArticleStatus status;
  final EducationArticle? article;
  final String? errorMessage;

  ArticleState copyWith({
    ArticleStatus? status,
    EducationArticle? article,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ArticleState(
      status: status ?? this.status,
      article: article ?? this.article,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, article, errorMessage];
}
