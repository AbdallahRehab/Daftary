import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_article.dart';
import 'article_state.dart';

/// Drives the article reader (FR-003).
@injectable
class ArticleCubit extends Cubit<ArticleState> {
  ArticleCubit(this._getArticle) : super(const ArticleState());

  final GetArticle _getArticle;

  Future<void> load(String articleId, String languageCode) async {
    emit(
      state.copyWith(status: ArticleStatus.loading, clearErrorMessage: true),
    );
    final result = await _getArticle(articleId, languageCode: languageCode);
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: ArticleStatus.failure,
          errorMessage: failure.message,
        ),
        (article) =>
            state.copyWith(status: ArticleStatus.success, article: article),
      ),
    );
  }
}
