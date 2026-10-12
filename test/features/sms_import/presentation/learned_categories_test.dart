import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/sms_import/domain/entities/merchant_category_mapping.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_settings_repository.dart';
import 'package:daftary/features/sms_import/domain/usecases/clear_learned_mappings.dart';
import 'package:daftary/features/sms_import/domain/usecases/remove_learned_mapping.dart';
import 'package:daftary/features/sms_import/domain/usecases/watch_learned_mappings.dart';
import 'package:daftary/features/sms_import/presentation/cubit/learned_categories_cubit.dart';
import 'package:daftary/features/sms_import/presentation/pages/learned_categories_page.dart';
import 'package:daftary/features/sms_import/presentation/widgets/bidi_text.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/fakes.dart';
import '../helpers/review_harness.dart';
import '../helpers/widget_harness.dart';

/// T140 (T139) — `LearnedCategoriesCubit` and `LearnedCategoriesPage`
/// (FR-056, ui-contract §3.9): rows, "Category removed" for archived or
/// missing categories, remove one, clear all behind a destructive confirm,
/// every state, RTL x LTR x light x dark, 200% text and 48 dp targets.
/// Every merchant is synthetic.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late FakeSmsImportSettingsRepository settings;
  late FakeCategoryRepository categories;

  MerchantCategoryMapping mapping(
    String merchant,
    String categoryId, {
    FinanceEntryType type = FinanceEntryType.expense,
  }) => MerchantCategoryMapping(
    merchantKey: merchant,
    entryType: type,
    categoryId: categoryId,
    updatedAt: DateTime(2026, 3, 4),
  );

  void seed(List<MerchantCategoryMapping> mappings) {
    for (final m in mappings) {
      settings.mappings[(m.merchantKey, m.entryType.dbValue)] = m;
    }
  }

  LearnedCategoriesCubit build({SmsImportSettingsRepository? using}) {
    final repo = using ?? settings;
    return LearnedCategoriesCubit(
      WatchLearnedMappings(repo),
      RemoveLearnedMapping(repo),
      ClearLearnedMappings(repo),
      GetCategories(categories),
    );
  }

  setUp(() {
    settings = FakeSmsImportSettingsRepository();
    categories = FakeCategoryRepository([
      testCategory('seed_groceries', FinanceEntryType.expense, name: 'Food'),
      testCategory('cat_old', FinanceEntryType.expense, archived: true),
      testCategory('seed_salary', FinanceEntryType.income, name: 'Pay'),
    ]);
  });
  tearDown(() => settings.close());

  group('LearnedCategoriesCubit', () {
    late LearnedCategoriesCubit cubit;
    tearDown(() => cubit.close());

    test('empty when nothing was learned', () async {
      cubit = build();
      await cubit.open();
      expect(cubit.state.status, LearnedCategoriesStatus.empty);
    });

    test('rows sorted by merchant; archived, missing and wrong-type '
        'categories are "removed"', () async {
      seed([
        mapping('zed market', 'seed_groceries'),
        mapping('old shop', 'cat_old'),
        mapping('gone shop', 'cat_deleted'),
        mapping(
          'example employer',
          'seed_salary',
          type: FinanceEntryType.income,
        ),
        mapping('mixed', 'seed_salary'),
      ]);
      cubit = build();
      await cubit.open();
      final rows = cubit.state.rows;
      expect(cubit.state.status, LearnedCategoriesStatus.ready);
      expect(rows.map((r) => r.mapping.merchantKey), [
        'example employer',
        'gone shop',
        'mixed',
        'old shop',
        'zed market',
      ]);
      bool removed(String merchant) => rows
          .singleWhere((r) => r.mapping.merchantKey == merchant)
          .categoryRemoved;
      expect(removed('zed market'), isFalse);
      expect(removed('example employer'), isFalse);
      expect(removed('old shop'), isTrue);
      expect(removed('gone shop'), isTrue);
      expect(removed('mixed'), isTrue);
    });

    test('remove forgets only that mapping; the list follows', () async {
      seed([mapping('a shop', 'seed_groceries'), mapping('b shop', 'cat_old')]);
      cubit = build();
      await cubit.open();
      // Lets the fake's async* stream subscribe to its change feed.
      await pumpEventQueue();
      await cubit.remove(cubit.state.rows.last.mapping);
      await pumpEventQueue();
      expect(cubit.state.removed, isTrue);
      expect(cubit.state.rows.map((r) => r.mapping.merchantKey), ['a shop']);
      expect(settings.mappings, hasLength(1));
      // Categories are never touched.
      expect(categories.categories, hasLength(3));
    });

    test('clear all empties the list', () async {
      seed([mapping('a shop', 'seed_groceries'), mapping('b shop', 'cat_old')]);
      cubit = build();
      await cubit.open();
      await pumpEventQueue();
      await cubit.clearAll();
      await pumpEventQueue();
      expect(cubit.state.cleared, isTrue);
      expect(cubit.state.status, LearnedCategoriesStatus.empty);
      expect(settings.mappings, isEmpty);
    });

    test('a failed remove keeps the row and reports the failure', () async {
      seed([mapping('a shop', 'seed_groceries')]);
      cubit = build();
      await cubit.open();
      settings.nextFailure = const CacheFailure('sms_mapping_write_failed');
      await cubit.remove(cubit.state.rows.single.mapping);
      expect(cubit.state.actionFailure, isA<CacheFailure>());
      expect(cubit.state.removing, isNull);
      expect(cubit.state.rows, hasLength(1));
      cubit.consumeActionFailure();
      expect(cubit.state.actionFailure, isNull);
    });

    test('remove and clear are single-flight', () async {
      seed([mapping('a shop', 'seed_groceries')]);
      final gated = _GatedSettings(settings);
      cubit = build(using: gated);
      await cubit.open();
      final first = cubit.remove(cubit.state.rows.single.mapping);
      await cubit.clearAll(); // ignored while Remove runs
      await cubit.remove(cubit.state.rows.single.mapping); // ignored
      gated.gate.complete();
      await first;
      expect(gated.removes, 1);
      expect(gated.clears, 0);
    });

    test('a read failure shows the error; retry recovers', () async {
      final failing = _FailingWatch(settings);
      cubit = build(using: failing);
      await cubit.open();
      expect(cubit.state.status, LearnedCategoriesStatus.error);
      failing.fail = false;
      await cubit.retry();
      expect(cubit.state.status, LearnedCategoriesStatus.empty);
    });

    test('toString names no merchant or category', () async {
      seed([mapping('secret merchant', 'seed_groceries')]);
      cubit = build();
      await cubit.open();
      expect(cubit.state.toString(), isNot(contains('secret')));
      expect(cubit.state.rows.single.toString(), isNot(contains('secret')));
      expect(cubit.state.toString(), isNot(contains('Food')));
    });
  });

  group('LearnedCategoriesPage', () {
    Future<void> pump(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      ThemeData? theme,
      double textScale = 1,
    }) => pumpSmsPage(
      tester,
      LearnedCategoriesPage(cubit: build()),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );

    testWidgets('empty state', (tester) async {
      await pump(tester);
      expect(find.text(en.smsImportMappingsEmptyTitle), findsOneWidget);
    });

    testWidgets('rows: merchant, type and category; "Category removed" for '
        'an archived one', (tester) async {
      seed([
        mapping('zed market', 'seed_groceries'),
        mapping('old shop', 'cat_old'),
      ]);
      await pump(tester);
      expect(find.text(en.smsImportMappingsCount(2)), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('learned_category_removed_expense_old shop')),
        findsOneWidget,
      );
      expect(find.text(en.smsImportMappingsCategoryRemoved), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(en.smsImportMappingsCategoryRemoved)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Remove forgets one row and announces it', (tester) async {
      seed([
        mapping('zed market', 'seed_groceries'),
        mapping('old shop', 'cat_old'),
      ]);
      await pump(tester);
      // The button keeps its tap action and names the merchant for
      // screen readers.
      final handle = tester.ensureSemantics();
      final label = find.bySemanticsLabel(
        en.smsImportMappingsRemoveSemantics(BidiIsolate.auto('old shop')),
      );
      expect(label, findsOneWidget);
      expect(
        tester
            .getSemantics(label)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      handle.dispose();
      await tester.tap(
        find.byKey(const ValueKey('learned_category_remove_expense_old shop')),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportMappingsRemoved), findsOneWidget);
      expect(find.text(en.smsImportMappingsCategoryRemoved), findsNothing);
      expect(settings.mappings, hasLength(1));
    });

    testWidgets('Clear asks first (destructive); Cancel keeps everything', (
      tester,
    ) async {
      seed([mapping('zed market', 'seed_groceries')]);
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('learned_categories_clear')));
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportMappingsClearConfirmTitle), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(settings.mappings, hasLength(1));

      await tester.tap(find.byKey(const ValueKey('learned_categories_clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.smsImportMappingsClearConfirm));
      await tester.pumpAndSettle();
      expect(settings.mappings, isEmpty);
      expect(find.text(en.smsImportMappingsCleared), findsOneWidget);
      expect(find.text(en.smsImportMappingsEmptyTitle), findsOneWidget);
    });

    testWidgets('error with Retry', (tester) async {
      final failing = _FailingWatch(settings);
      await pumpSmsPage(
        tester,
        LearnedCategoriesPage(cubit: build(using: failing)),
      );
      expect(find.text(en.smsImportMappingsLoadError), findsOneWidget);
      failing.fail = false;
      await tester.tap(find.text(en.smsImportPendingRetry));
      await tester.pumpAndSettle();
      expect(find.text(en.smsImportMappingsEmptyTitle), findsOneWidget);
    });

    for (final locale in smsLocales) {
      for (final theme in smsThemes) {
        testWidgets('renders in ${locale.name} / ${theme.name}', (
          tester,
        ) async {
          seed([
            mapping('zed market', 'seed_groceries'),
            mapping('old shop', 'cat_old'),
          ]);
          await pump(tester, locale: locale.locale, theme: theme.theme);
          expect(tester.takeException(), isNull);
          expectTapTargets(tester, find.byType(LearnedCategoriesPage));
        });
      }
    }

    testWidgets('200% Arabic renders without overflow', (tester) async {
      seed([
        mapping('a very long example merchant name', 'seed_groceries'),
        mapping('old shop', 'cat_old'),
      ]);
      await pump(tester, locale: const Locale('ar'), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Delegates to [inner]; Remove and Clear wait on [gate].
class _GatedSettings extends _Delegating {
  _GatedSettings(super.inner);

  final Completer<void> gate = Completer();
  int removes = 0;
  int clears = 0;

  @override
  Future<Either<Failure, Unit>> removeMapping(
    String merchantKey,
    String entryType,
  ) async {
    removes++;
    await gate.future;
    return inner.removeMapping(merchantKey, entryType);
  }

  @override
  Future<Either<Failure, Unit>> clearMappings() async {
    clears++;
    await gate.future;
    return inner.clearMappings();
  }
}

/// The mapping stream fails while [fail] is true.
class _FailingWatch extends _Delegating {
  _FailingWatch(super.inner);

  bool fail = true;

  @override
  Stream<Either<Failure, List<MerchantCategoryMapping>>> watchMappings() => fail
      ? Stream.value(const Left(CacheFailure('sms_mappings_read_failed')))
      : inner.watchMappings();
}

class _Delegating implements SmsImportSettingsRepository {
  _Delegating(this.inner);

  final FakeSmsImportSettingsRepository inner;

  @override
  Stream<Either<Failure, List<MerchantCategoryMapping>>> watchMappings() =>
      inner.watchMappings();

  @override
  Future<Either<Failure, Unit>> removeMapping(
    String merchantKey,
    String entryType,
  ) => inner.removeMapping(merchantKey, entryType);

  @override
  Future<Either<Failure, Unit>> clearMappings() => inner.clearMappings();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
