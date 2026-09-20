import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/person_balance.dart';
import '../../domain/entities/person.dart';

enum PersonListStatus { loading, success, failure }

/// One row of the active-people list: a [Person] paired with the balance
/// used both to render its status badge and to satisfy the FR-019 status
/// filter.
class PersonListItem extends Equatable {
  const PersonListItem({required this.person, required this.balance});

  final Person person;
  final PersonBalance balance;

  @override
  List<Object?> get props => [person, balance];
}

/// Immutable state for [PersonListCubit] (constitution Principle IV).
class PersonListState extends Equatable {
  const PersonListState({
    this.status = PersonListStatus.loading,
    this.items = const [],
    this.nameQuery = '',
    this.statusFilter,
    this.errorMessage,
  });

  final PersonListStatus status;
  final List<PersonListItem> items;
  final String nameQuery;
  final RelationshipStatus? statusFilter;
  final String? errorMessage;

  bool get isLoading => status == PersonListStatus.loading;

  PersonListState copyWith({
    PersonListStatus? status,
    List<PersonListItem>? items,
    String? nameQuery,
    RelationshipStatus? statusFilter,
    bool clearStatusFilter = false,
    String? errorMessage,
  }) {
    return PersonListState(
      status: status ?? this.status,
      items: items ?? this.items,
      nameQuery: nameQuery ?? this.nameQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    nameQuery,
    statusFilter,
    errorMessage,
  ];
}
