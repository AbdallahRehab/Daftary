import 'package:equatable/equatable.dart';

import '../../../../core/money/currency.dart';

enum ExchangeRateFormStatus { loading, ready, loadFailure }

/// Immutable state for `ExchangeRateFormCubit`.
class ExchangeRateFormState extends Equatable {
  const ExchangeRateFormState({
    this.status = ExchangeRateFormStatus.loading,
    this.isEditing = false,
    this.relativeTo = Currency.egp,
    this.currency,
    this.availableCurrencies = const [],
    this.rateText = '',
    this.showRateError = false,
    this.isSubmitting = false,
    this.isSaved = false,
    this.isSaveFailing = false,
  });

  final ExchangeRateFormStatus status;

  /// Editing an existing pair — the currency is then fixed.
  final bool isEditing;

  /// The quote currency: the primary currency for a new rate, or the
  /// stored pair's own `relativeTo` when editing.
  final Currency relativeTo;

  /// The currency being priced ("1 [currency] = x [relativeTo]").
  final Currency? currency;

  /// Catalog minus [relativeTo].
  final List<Currency> availableCurrencies;

  final String rateText;

  /// Set once a save was attempted with an invalid rate (FR-006).
  final bool showRateError;

  /// Save is disabled while `true` (duplicate-action protection).
  final bool isSubmitting;

  /// The rate was stored; the page pops.
  final bool isSaved;

  final bool isSaveFailing;

  bool get canSave =>
      status == ExchangeRateFormStatus.ready &&
      currency != null &&
      !isSubmitting &&
      !isSaved;

  ExchangeRateFormState copyWith({
    ExchangeRateFormStatus? status,
    bool? isEditing,
    Currency? relativeTo,
    Currency? currency,
    List<Currency>? availableCurrencies,
    String? rateText,
    bool? showRateError,
    bool? isSubmitting,
    bool? isSaved,
    bool? isSaveFailing,
  }) {
    return ExchangeRateFormState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      relativeTo: relativeTo ?? this.relativeTo,
      currency: currency ?? this.currency,
      availableCurrencies: availableCurrencies ?? this.availableCurrencies,
      rateText: rateText ?? this.rateText,
      showRateError: showRateError ?? this.showRateError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSaved: isSaved ?? this.isSaved,
      isSaveFailing: isSaveFailing ?? this.isSaveFailing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isEditing,
    relativeTo,
    currency,
    availableCurrencies,
    rateText,
    showRateError,
    isSubmitting,
    isSaved,
    isSaveFailing,
  ];
}
