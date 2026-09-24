import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_category_articles.dart';
import 'category_state.dart';

/// Drives one category's article list.
@injectable
class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._getCategoryArticles) : super(const CategoryState());

  final GetCategoryArticles _getCategoryArticles;

  Future<void> load(String categoryId, String languageCode) async {
    emit(
      state.copyWith(status: CategoryStatus.loading, clearErrorMessage: true),
    );
    final result = await _getCategoryArticles(
      categoryId,
      languageCode: languageCode,
    );
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: CategoryStatus.failure,
          errorMessage: failure.message,
        ),
        (loaded) => state.copyWith(
          status: CategoryStatus.success,
          category: loaded.$1,
          articles: loaded.$2,
        ),
      ),
    );
  }
}
