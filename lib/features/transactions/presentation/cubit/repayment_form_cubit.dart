import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/numeral_parser.dart';
import '../../domain/usecases/record_repayment.dart';
import 'repayment_form_state.dart';

/// Pre-bound to a known [personId] (opened from that person's detail page),
/// with its own idempotency key (FR-020 — same guarantee as
/// [TransactionFormCubit], independently).
@injectable
class RepaymentFormCubit extends Cubit<RepaymentFormState> {
  RepaymentFormCubit(
    this._recordRepayment,
    this._egpFormatter,
    @factoryParam String personId,
  ) : super(
        RepaymentFormState(
          personId: personId,
          idempotencyKey: const Uuid().v4(),
        ),
      );

  final RecordRepayment _recordRepayment;
  final EgpFormatter _egpFormatter;

  void amountChanged(String text) {
    emit(state.copyWith(amountInput: text, clearAmountError: true));
  }

  void dateChanged(DateTime date) {
    emit(state.copyWith(date: date));
  }

  void noteChanged(String note) {
    emit(state.copyWith(note: note));
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final Money amount;
    try {
      final normalized = NumeralParser.toWesternDigits(state.amountInput);
      final parsed = _egpFormatter.parse(normalized);
      if (!parsed.isPositive) {
        throw const FormatException('Amount must be greater than zero');
      }
      amount = parsed;
    } on FormatException {
      emit(state.copyWith(amountInvalid: true));
      return;
    }

    emit(
      state.copyWith(
        status: RepaymentFormStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    final result = await _recordRepayment(
      idempotencyKey: state.idempotencyKey,
      personId: state.personId,
      amount: amount,
      date: state.date,
      note: state.note,
    );

    result.match(
      (failure) => emit(
        state.copyWith(
          status: RepaymentFormStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: RepaymentFormStatus.success)),
    );
  }
}
