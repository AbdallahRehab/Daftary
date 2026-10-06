import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/person_balance.dart';
import '../../domain/services/deletion_impact.dart';

enum PersonDetailStatus { loading, success, failure }

/// A delete the user asked for and has yet to confirm, with what it would
/// leave behind (022 E6).
class PendingDelete extends Equatable {
  const PendingDelete({required this.transaction, required this.impact});

  final MoneyTransaction transaction;
  final DeletionImpact impact;

  @override
  List<Object?> get props => [transaction, impact];
}

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
    this.pendingDelete,
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

  /// Set while the delete confirmation is open.
  final PendingDelete? pendingDelete;

  bool get isLoading => status == PersonDetailStatus.loading;

  PersonDetailState copyWith({
    PersonDetailStatus? status,
    Person? person,
    PersonBalance? balance,
    List<MoneyTransaction>? history,
    Map<String, String>? occasionNames,
    Currency? primaryCurrency,
    Failure? failure,
    PendingDelete? pendingDelete,
    bool clearPendingDelete = false,
  }) {
    return PersonDetailState(
      status: status ?? this.status,
      person: person ?? this.person,
      balance: balance ?? this.balance,
      history: history ?? this.history,
      occasionNames: occasionNames ?? this.occasionNames,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      failure: failure,
      pendingDelete: clearPendingDelete
          ? null
          : (pendingDelete ?? this.pendingDelete),
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
    pendingDelete,
  ];
}
