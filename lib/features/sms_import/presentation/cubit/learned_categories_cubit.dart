import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/category.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/usecases/get_categories.dart';
import '../../domain/entities/merchant_category_mapping.dart';
import '../../domain/usecases/clear_learned_mappings.dart';
import '../../domain/usecases/remove_learned_mapping.dart';
import '../../domain/usecases/watch_learned_mappings.dart';

/// The Learned categories screen's phases (ui-contract §3.9).
enum LearnedCategoriesStatus { initial, loading, ready, empty, error }

/// One learned merchant -> category row. [category] is `null` when the
/// mapped category was archived or deleted: the row shows "Category
/// removed" and the mapping is skipped at suggestion time (data-model
/// §3.4).
class LearnedCategoryRow extends Equatable {
  const LearnedCategoryRow({required this.mapping, this.category});

  final MerchantCategoryMapping mapping;
  final Category? category;

  bool get categoryRemoved => category == null;

  @override
  List<Object?> get props => [mapping, category];

  /// Redacted: the merchant key and the category name are user data.
  @override
  String toString() =>
      'LearnedCategoryRow(type: ${mapping.entryType.name}, '
      'removed: $categoryRemoved)';
}

/// Immutable state of [LearnedCategoriesCubit].
class LearnedCategoriesState extends Equatable {
  LearnedCategoriesState({
    this.status = LearnedCategoriesStatus.initial,
    List<LearnedCategoryRow> rows = const [],
    this.removing,
    this.clearing = false,
    this.removed = false,
    this.cleared = false,
    this.failure,
    this.actionFailure,
  }) : rows = List.unmodifiable(rows);

  final LearnedCategoriesStatus status;

  /// Sorted by merchant, then type.
  final List<LearnedCategoryRow> rows;

  /// The mapping whose Remove runs.
  final MerchantCategoryMapping? removing;

  /// "Clear learned categories" runs.
  final bool clearing;

  /// One-shot outcomes; the page announces them and calls `consume*`.
  final bool removed;
  final bool cleared;

  /// The load failure (error state).
  final Failure? failure;

  /// A failed Remove or Clear; the list stays.
  final Failure? actionFailure;

  bool get isSubmitting => removing != null || clearing;

  LearnedCategoriesState copyWith({
    LearnedCategoriesStatus? status,
    List<LearnedCategoryRow>? rows,
    MerchantCategoryMapping? removing,
    bool clearRemoving = false,
    bool? clearing,
    bool? removed,
    bool? cleared,
    Failure? failure,
    bool clearFailure = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) => LearnedCategoriesState(
    status: status ?? this.status,
    rows: rows ?? this.rows,
    removing: clearRemoving ? null : (removing ?? this.removing),
    clearing: clearing ?? this.clearing,
    removed: removed ?? this.removed,
    cleared: cleared ?? this.cleared,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [
    status,
    rows,
    removing,
    clearing,
    removed,
    cleared,
    failure,
    actionFailure,
  ];

  /// Redacted: counts and codes only.
  @override
  String toString() =>
      'LearnedCategoriesState(status: ${status.name}, rows: ${rows.length}, '
      'removing: ${removing != null}, clearing: $clearing, '
      'failure: ${failure.runtimeType}, '
      'actionFailure: ${actionFailure.runtimeType})';
}

/// Learned categories (T139, FR-056, ui-contract §3.9): follows
/// `WatchLearnedMappings`, resolves each mapping's ACTIVE category (an
/// archived or deleted one shows as "Category removed"), removes one
/// mapping or clears them all. Categories and saved records are never
/// touched.
@injectable
class LearnedCategoriesCubit extends Cubit<LearnedCategoriesState> {
  LearnedCategoriesCubit(
    this._watch,
    this._remove,
    this._clear,
    this._getCategories,
  ) : super(LearnedCategoriesState());

  final WatchLearnedMappings _watch;
  final RemoveLearnedMapping _remove;
  final ClearLearnedMappings _clear;
  final GetCategories _getCategories;

  StreamSubscription<void>? _subscription;

  /// Opens the list. Completes once the first result was emitted.
  Future<void> open() {
    _cancelSubscription();
    emit(
      state.copyWith(
        status: LearnedCategoriesStatus.loading,
        clearFailure: true,
      ),
    );
    final first = Completer<void>();
    _subscription = _watch().asyncMap(_resolve).listen((next) {
      if (isClosed) return;
      // Applied to the state as it is NOW, so a one-shot outcome emitted
      // while the rows were resolving is never overwritten.
      final (:failure, :rows) = next;
      emit(
        failure != null
            ? state.copyWith(
                status: LearnedCategoriesStatus.error,
                failure: failure,
              )
            : state.copyWith(
                status: rows.isEmpty
                    ? LearnedCategoriesStatus.empty
                    : LearnedCategoriesStatus.ready,
                rows: rows,
                clearFailure: true,
              ),
      );
      if (!first.isCompleted) first.complete();
    });
    return first.future;
  }

  Future<void> retry() => open();

  /// Resolves each mapping's active category, sorted.
  Future<({Failure? failure, List<LearnedCategoryRow> rows})> _resolve(
    Either<Failure, List<MerchantCategoryMapping>> result,
  ) async {
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      return (failure: failure, rows: const <LearnedCategoryRow>[]);
    }
    final mappings = result.getOrElse((_) => const []);
    if (mappings.isEmpty) {
      return (failure: null, rows: const <LearnedCategoryRow>[]);
    }
    // Active categories only: an archived one is "removed" here, as it is
    // for suggestions.
    final active = <String, Category>{};
    for (final type in FinanceEntryType.values) {
      final categories = await _getCategories(type: type);
      if (categories case Left(:final value)) {
        return (failure: value, rows: const <LearnedCategoryRow>[]);
      }
      for (final c in categories.getOrElse((_) => const [])) {
        active[c.id] = c;
      }
    }
    final rows = [
      for (final m in mappings)
        LearnedCategoryRow(
          mapping: m,
          category: switch (active[m.categoryId]) {
            final c? when c.type == m.entryType => c,
            _ => null,
          },
        ),
    ]..sort(_byMerchantThenType);
    return (failure: null, rows: rows);
  }

  static int _byMerchantThenType(LearnedCategoryRow a, LearnedCategoryRow b) {
    final byMerchant = a.mapping.merchantKey.compareTo(b.mapping.merchantKey);
    if (byMerchant != 0) return byMerchant;
    return a.mapping.entryType.index.compareTo(b.mapping.entryType.index);
  }

  /// Forgets one mapping. Single-flight with [clearAll].
  Future<void> remove(MerchantCategoryMapping mapping) async {
    if (state.isSubmitting) return;
    emit(
      state.copyWith(
        removing: mapping,
        removed: false,
        clearActionFailure: true,
      ),
    );
    final result = await _remove(mapping);
    if (isClosed) return;
    emit(
      result.match(
        (failure) =>
            state.copyWith(clearRemoving: true, actionFailure: failure),
        (_) => state.copyWith(clearRemoving: true, removed: true),
      ),
    );
  }

  /// "Clear learned categories", after the page's confirmation.
  /// Single-flight with [remove].
  Future<void> clearAll() async {
    if (state.isSubmitting) return;
    emit(
      state.copyWith(clearing: true, cleared: false, clearActionFailure: true),
    );
    final result = await _clear();
    if (isClosed) return;
    emit(
      result.match(
        (failure) => state.copyWith(clearing: false, actionFailure: failure),
        (_) => state.copyWith(clearing: false, cleared: true),
      ),
    );
  }

  void consumeRemoved() => emit(state.copyWith(removed: false));

  void consumeCleared() => emit(state.copyWith(cleared: false));

  void consumeActionFailure() => emit(state.copyWith(clearActionFailure: true));

  /// Not awaited: see `BankMessagesHomeCubit._cancelSubscription`.
  void _cancelSubscription() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
