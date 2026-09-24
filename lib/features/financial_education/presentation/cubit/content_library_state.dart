import 'package:equatable/equatable.dart';

import '../../domain/entities/education_category.dart';

enum ContentLibraryStatus { loading, success, failure }

/// Immutable state for `ContentLibraryCubit` (constitution Principle IV).
class ContentLibraryState extends Equatable {
  const ContentLibraryState({
    this.status = ContentLibraryStatus.loading,
    this.categories = const [],
    this.errorMessage,
  });

  final ContentLibraryStatus status;
  final List<EducationCategory> categories;
  final String? errorMessage;

  ContentLibraryState copyWith({
    ContentLibraryStatus? status,
    List<EducationCategory>? categories,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ContentLibraryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, categories, errorMessage];
}
