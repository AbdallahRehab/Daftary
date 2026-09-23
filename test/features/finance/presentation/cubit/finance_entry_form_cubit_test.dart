import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAddFinanceEntry extends Mock implements AddFinanceEntry {}

class MockEditFinanceEntry extends Mock implements EditFinanceEntry {}

class MockGetCategories extends Mock implements GetCategories {}

void main() {
  late MockAddFinanceEntry addFinanceEntry;
  late MockEditFinanceEntry editFinanceEntry;
  late MockGetCategories getCategories;
  late EgpFormatter egpFormatter;

  final now = DateTime(2026, 1, 1);

  final groceries = Category(
    id: 'seed_groceries',
    name: 'Groceries',
    type: FinanceEntryType.expense,
    icon: 'groceries',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );
  final rent = Category(
    id: 'seed_rent',
    name: 'Rent',
    type: FinanceEntryType.expense,
    icon: 'rent',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );
  final salary = Category(
    id: 'seed_salary',
    name: 'Salary',
    type: FinanceEntryType.income,
    icon: 'salary',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  );
  final archivedGadgets = Category(
    id: 'custom_gadgets',
    name: 'Gadgets',
    type: FinanceEntryType.expense,
    icon: 'shopping',
    isArchived: true,
    createdAt: now,
    updatedAt: now,
  );

  final savedEntry = FinanceEntry(
    id: 'e1',
    idempotencyKey: 'ignored-in-test',
    categoryId: groceries.id,
    type: FinanceEntryType.expense,
    amount: const Money.fromMinorUnits(15050),
    date: now,
    createdAt: now,
  );

  void stubCategories(Map<FinanceEntryType, List<Category>> byType) {
    when(
      () => getCategories(
        type: any(named: 'type'),
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((invocation) async {
      final type = invocation.namedArguments[#type] as FinanceEntryType;
      return Right(byType[type] ?? const <Category>[]);
    });
  }

  void stubAdd() {
    when(
      () => addFinanceEntry(
        idempotencyKey: any(named: 'idempotencyKey'),
        categoryId: any(named: 'categoryId'),
        type: any(named: 'type'),
        amountMinorUnits: any(named: 'amountMinorUnits'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Right(savedEntry));
  }

  setUpAll(() {
    registerFallbackValue(FinanceEntryType.expense);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    addFinanceEntry = MockAddFinanceEntry();
    editFinanceEntry = MockEditFinanceEntry();
    getCategories = MockGetCategories();
    egpFormatter = EgpFormatter();
    stubCategories({
      FinanceEntryType.expense: [groceries, rent],
      FinanceEntryType.income: [salary],
    });
  });

  FinanceEntryFormCubit buildCubit() => FinanceEntryFormCubit(
    addFinanceEntry,
    editFinanceEntry,
    getCategories,
    egpFormatter,
  );

  group('add mode', () {
    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'initialize loads the expense categories for the picker',
      build: buildCubit,
      act: (cubit) => cubit.initialize(type: FinanceEntryType.expense),
      expect: () => [
        isA<FinanceEntryFormState>().having(
          (s) => s.isLoadingCategories,
          'isLoadingCategories',
          isTrue,
        ),
        isA<FinanceEntryFormState>()
            .having((s) => s.categories, 'categories', [groceries, rent])
            .having((s) => s.isLoadingCategories, 'isLoadingCategories', false),
      ],
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'happy path: a valid amount + category saves the expense',
      build: buildCubit,
      setUp: stubAdd,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.categorySelected(groceries.id);
        cubit.amountChanged('150.50');
        await cubit.submit();
      },
      skip: 4,
      expect: () => [
        isA<FinanceEntryFormState>().having(
          (s) => s.status,
          'status',
          FinanceEntryFormStatus.submitting,
        ),
        isA<FinanceEntryFormState>()
            .having((s) => s.status, 'status', FinanceEntryFormStatus.success)
            .having((s) => s.savedEntry, 'savedEntry', savedEntry),
      ],
      verify: (_) {
        verify(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: groceries.id,
            type: FinanceEntryType.expense,
            amountMinorUnits: 15050,
            date: any(named: 'date'),
            note: null,
          ),
        ).called(1);
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'a zero amount is rejected without discarding the entered fields '
      '(FR-003)',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.categorySelected(groceries.id);
        cubit.amountChanged('0');
        cubit.noteChanged('Taxi');
        await cubit.submit();
      },
      skip: 5,
      expect: () => [
        isA<FinanceEntryFormState>()
            .having((s) => s.amountInvalid, 'amountInvalid', isTrue)
            .having((s) => s.amountInput, 'amountInput', '0')
            .having((s) => s.note, 'note', 'Taxi')
            .having(
              (s) => s.selectedCategoryId,
              'selectedCategoryId',
              groceries.id,
            ),
      ],
      verify: (_) {
        verifyNever(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        );
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'an empty amount is rejected the same way as a zero one (FR-003)',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.categorySelected(groceries.id);
        await cubit.submit();
      },
      skip: 3,
      expect: () => [
        isA<FinanceEntryFormState>().having(
          (s) => s.amountInvalid,
          'amountInvalid',
          isTrue,
        ),
      ],
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'submitting with no category selected is blocked (FR-003)',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.amountChanged('150.50');
        await cubit.submit();
      },
      skip: 3,
      expect: () => [
        isA<FinanceEntryFormState>()
            .having(
              (s) => s.categorySelectionRequired,
              'categorySelectionRequired',
              isTrue,
            )
            // The typed amount survives the rejection.
            .having((s) => s.amountInput, 'amountInput', '150.50'),
      ],
      verify: (_) {
        verifyNever(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        );
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'the date defaults to today when the user never changes it (FR-001)',
      build: buildCubit,
      verify: (cubit) {
        final today = DateTime.now();
        expect(cubit.state.date.year, today.year);
        expect(cubit.state.date.month, today.month);
        expect(cubit.state.date.day, today.day);
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'a future date is accepted as a planned entry',
      build: buildCubit,
      setUp: stubAdd,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.categorySelected(groceries.id);
        cubit.amountChanged('150.50');
        cubit.dateChanged(DateTime(2030, 6, 1));
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, FinanceEntryFormStatus.success);
        verify(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: groceries.id,
            type: FinanceEntryType.expense,
            amountMinorUnits: 15050,
            date: DateTime(2030, 6, 1),
            note: null,
          ),
        ).called(1);
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'a rapid double-tap only ever invokes AddFinanceEntry once (FR-021)',
      build: buildCubit,
      setUp: stubAdd,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.categorySelected(groceries.id);
        cubit.amountChanged('150.50');
        final firstTap = cubit.submit();
        final secondTap = cubit.submit(); // before the first resolves
        await Future.wait([firstTap, secondTap]);
      },
      verify: (_) {
        verify(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        ).called(1);
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'switching the type swaps the category set and drops a selection that '
      'no longer applies (T031)',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize(type: FinanceEntryType.expense);
        cubit.categorySelected(groceries.id);
        await cubit.typeChanged(FinanceEntryType.income);
      },
      verify: (cubit) {
        expect(cubit.state.type, FinanceEntryType.income);
        expect(cubit.state.categories, [salary]);
        expect(cubit.state.selectedCategoryId, isNull);
      },
    );
  });

  group('edit mode', () {
    final archivedEntry = FinanceEntry(
      id: 'e9',
      idempotencyKey: 'k9',
      categoryId: archivedGadgets.id,
      type: FinanceEntryType.expense,
      amount: const Money.fromMinorUnits(45075),
      date: DateTime(2026, 1, 5),
      createdAt: DateTime(2026, 1, 5),
      note: 'Headphones',
    );

    void stubEdit() {
      when(
        () => editFinanceEntry(
          entryId: any(named: 'entryId'),
          categoryId: any(named: 'categoryId'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => Right(archivedEntry));
    }

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'loading an entry whose category is archived keeps that category '
      'selectable for this entry only (FR-011)',
      build: buildCubit,
      act: (cubit) => cubit.loadForEdit(archivedEntry, archivedGadgets),
      verify: (cubit) {
        final state = cubit.state;
        expect(state.isEditMode, isTrue);
        expect(state.editingEntryId, 'e9');
        expect(state.amountInput, '450.75');
        expect(state.note, 'Headphones');
        expect(state.date, DateTime(2026, 1, 5));
        // The active set never offers it, but it is appended so the entry
        // keeps the category it was recorded against.
        expect(state.categories, contains(archivedGadgets));
        expect(state.selectedCategoryId, archivedGadgets.id);
      },
    );

    blocTest<FinanceEntryFormCubit, FinanceEntryFormState>(
      'saving in edit mode calls EditFinanceEntry, never AddFinanceEntry',
      build: buildCubit,
      setUp: stubEdit,
      act: (cubit) async {
        await cubit.loadForEdit(archivedEntry, archivedGadgets);
        cubit.categorySelected(rent.id);
        cubit.amountChanged('500');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, FinanceEntryFormStatus.success);
        verify(
          () => editFinanceEntry(
            entryId: 'e9',
            categoryId: rent.id,
            amountMinorUnits: 50000,
            date: DateTime(2026, 1, 5),
            note: 'Headphones',
          ),
        ).called(1);
        verifyNever(
          () => addFinanceEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            date: any(named: 'date'),
            note: any(named: 'note'),
          ),
        );
      },
    );
  });
}
