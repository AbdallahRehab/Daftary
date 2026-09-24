import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

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
    this.primaryCurrency = Currency.egp,
    this.errorMessage,
  });

  final PersonDetailStatus status;
  final Person? person;
  final PersonBalance? balance;

  /// Chronological (oldest first) — mirrors `GetPersonHistory` (FR-010).
  final List<MoneyTransaction> history;

  /// The current primary currency (018): history rows in any other
  /// currency show a `CurrencyIndicatorChip` (FR-010).
  final Currency primaryCurrency;
  final String? errorMessage;

  bool get isLoading => status == PersonDetailStatus.loading;

  PersonDetailState copyWith({
    PersonDetailStatus? status,
    Person? person,
    PersonBalance? balance,
    List<MoneyTransaction>? history,
    Currency? primaryCurrency,
    String? errorMessage,
  }) {
    return PersonDetailState(
      status: status ?? this.status,
      person: person ?? this.person,
      balance: balance ?? this.balance,
      history: history ?? this.history,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    person,
    balance,
    history,
    primaryCurrency,
    errorMessage,
  ];
}
