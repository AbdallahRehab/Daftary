import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
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
    this.failure,
    this.processingPersonId,
    this.lastArchived,
  });

  final PersonListStatus status;
  final List<PersonListItem> items;
  final String nameQuery;
  final RelationshipStatus? statusFilter;
  final Failure? failure;

  /// Non-null while an `archive()` call is in flight for that person id;
  /// `archive()` is a no-op re-entrancy guard when called again with the
  /// same id while it is already set (FR-006). Cleared once the use case
  /// call (success or failure) completes and, on success, the subsequent
  /// `load()` has emitted.
  final String? processingPersonId;

  /// The person a just-completed `archive()` removed from the list. Set for
  /// a single emission (every `copyWith` clears it unless passed again) so
  /// the page shows exactly one Undo snackbar per archive.
  final Person? lastArchived;

  bool get isLoading => status == PersonListStatus.loading;

  PersonListState copyWith({
    PersonListStatus? status,
    List<PersonListItem>? items,
    String? nameQuery,
    RelationshipStatus? statusFilter,
    bool clearStatusFilter = false,
    Failure? failure,
    String? processingPersonId,
    bool clearProcessingPersonId = false,
    Person? lastArchived,
  }) {
    return PersonListState(
      status: status ?? this.status,
      items: items ?? this.items,
      nameQuery: nameQuery ?? this.nameQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      failure: failure,
      processingPersonId: clearProcessingPersonId
          ? null
          : (processingPersonId ?? this.processingPersonId),
      lastArchived: lastArchived,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    nameQuery,
    statusFilter,
    failure,
    processingPersonId,
    lastArchived,
  ];
}
