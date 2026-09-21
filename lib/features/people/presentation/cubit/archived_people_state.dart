import 'package:equatable/equatable.dart';

import '../../domain/entities/person.dart';

enum ArchivedPeopleStatus { loading, success, failure }

/// Immutable state for [ArchivedPeopleCubit] (constitution Principle IV).
class ArchivedPeopleState extends Equatable {
  const ArchivedPeopleState({
    this.status = ArchivedPeopleStatus.loading,
    this.people = const [],
    this.nameQuery = '',
    this.errorMessage,
    this.processingPersonId,
  });

  final ArchivedPeopleStatus status;
  final List<Person> people;
  final String nameQuery;
  final String? errorMessage;

  /// Same guard as `PersonListState.processingPersonId`, applied to
  /// `restore()` (FR-006).
  final String? processingPersonId;

  bool get isLoading => status == ArchivedPeopleStatus.loading;

  ArchivedPeopleState copyWith({
    ArchivedPeopleStatus? status,
    List<Person>? people,
    String? nameQuery,
    String? errorMessage,
    String? processingPersonId,
    bool clearProcessingPersonId = false,
  }) {
    return ArchivedPeopleState(
      status: status ?? this.status,
      people: people ?? this.people,
      nameQuery: nameQuery ?? this.nameQuery,
      errorMessage: errorMessage,
      processingPersonId: clearProcessingPersonId
          ? null
          : (processingPersonId ?? this.processingPersonId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    people,
    nameQuery,
    errorMessage,
    processingPersonId,
  ];
}
