import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
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
    this.occasionNames = const {},
    this.primaryCurrency = Currency.egp,
    this.failure,
  });

  final PersonDetailStatus status;
  final Person? person;
  final PersonBalance? balance;

  /// Chronological (oldest first) — mirrors `GetPersonHistory` (FR-010).
  final List<MoneyTransaction> history;

  /// Occasion id → occasion name for every occasion-linked row in [history]
  /// (008). Watched alongside the history so each list tile can label its
  /// contribution without a lookup of its own.
  final Map<String, String> occasionNames;

  /// The current primary currency (018): history rows in any other
  /// currency show a `CurrencyIndicatorChip` (FR-010).
  final Currency primaryCurrency;
  final Failure? failure;

  bool get isLoading => status == PersonDetailStatus.loading;

  PersonDetailState copyWith({
    PersonDetailStatus? status,
    Person? person,
    PersonBalance? balance,
    List<MoneyTransaction>? history,
    Map<String, String>? occasionNames,
    Currency? primaryCurrency,
    Failure? failure,
  }) {
    return PersonDetailState(
      status: status ?? this.status,
      person: person ?? this.person,
      balance: balance ?? this.balance,
      history: history ?? this.history,
      occasionNames: occasionNames ?? this.occasionNames,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    person,
    balance,
    history,
    occasionNames,
    primaryCurrency,
    failure,
  ];
}
