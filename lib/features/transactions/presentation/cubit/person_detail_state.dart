import 'package:equatable/equatable.dart';

import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/person_balance.dart';

enum PersonDetailStatus { loading, success, failure }

/// Immutable state for [PersonDetailCubit] (constitution Principle IV).
class PersonDetailState extends Equatable {
  const PersonDetailState({
    this.status = PersonDetailStatus.loading,
    this.person,
    this.balance,
    this.history = const [],
    this.errorMessage,
  });

  final PersonDetailStatus status;
  final Person? person;
  final PersonBalance? balance;

  /// Chronological (oldest first) — mirrors `GetPersonHistory` (FR-010).
  final List<MoneyTransaction> history;
  final String? errorMessage;

  bool get isLoading => status == PersonDetailStatus.loading;

  PersonDetailState copyWith({
    PersonDetailStatus? status,
    Person? person,
    PersonBalance? balance,
    List<MoneyTransaction>? history,
    String? errorMessage,
  }) {
    return PersonDetailState(
      status: status ?? this.status,
      person: person ?? this.person,
      balance: balance ?? this.balance,
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, person, balance, history, errorMessage];
}
