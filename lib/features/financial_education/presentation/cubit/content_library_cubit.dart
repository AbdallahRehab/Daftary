import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/get_education_categories.dart';
import 'content_library_state.dart';

/// Drives the content library home: the category list for the active app
/// language (FR-001).
@injectable
class ContentLibraryCubit extends Cubit<ContentLibraryState> {
  ContentLibraryCubit(this._getCategories) : super(const ContentLibraryState());

  final GetEducationCategories _getCategories;

  /// [languageCode] is the active app language (`en`/`ar`); the page reads
  /// it from its `Localizations`, so the content always matches the UI.
  Future<void> load(String languageCode) async {
    emit(
      state.copyWith(
        status: ContentLibraryStatus.loading,
        clearErrorMessage: true,
      ),
    );
    final result = await _getCategories(languageCode: languageCode);
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: ContentLibraryStatus.failure,
          errorMessage: failure.message,
        ),
        (categories) => state.copyWith(
          status: ContentLibraryStatus.success,
          categories: categories,
        ),
      ),
    );
  }
}
