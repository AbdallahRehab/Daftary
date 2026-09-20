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
  });

  final ArchivedPeopleStatus status;
  final List<Person> people;
  final String nameQuery;
  final String? errorMessage;

  bool get isLoading => status == ArchivedPeopleStatus.loading;

  ArchivedPeopleState copyWith({
    ArchivedPeopleStatus? status,
    List<Person>? people,
    String? nameQuery,
    String? errorMessage,
  }) {
    return ArchivedPeopleState(
      status: status ?? this.status,
      people: people ?? this.people,
      nameQuery: nameQuery ?? this.nameQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, people, nameQuery, errorMessage];
}
