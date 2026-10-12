import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/dashboard/presentation/pages/home_page.dart';
import 'package:daftary/features/dashboard/presentation/widgets/bank_messages_home_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/insights_placeholder_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/overview_summary_card.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_home_cubit.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../sms_import/helpers/builders.dart';
import '../../sms_import/helpers/fakes.dart';
import '../../sms_import/helpers/scan_presentation.dart';
import '../../sms_import/helpers/widget_harness.dart';

class _MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

/// T129 — the count variant of the Home bank-messages card (FR-050,
/// ui-contract §2): rendered only while items wait, a plural count with no
/// merchant, amount or text, tap opens the hub, no tab badge; plus the
/// dashboard ordering: every new Home surface sits below the people
/// summary.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));
  late HubScanDeps deps;
  late FakeSmsImportRepository repository;

  setUp(() {
    repository = FakeSmsImportRepository();
  });
  tearDown(() async {
    await deps.settings.close();
    await repository.close();
  });

  Finder countCard() => find.byKey(const ValueKey('bank_messages_home_count'));

  Future<void> pumpCard(
    WidgetTester tester, {
    bool capability = true,
    SmsImportSettings settings = const SmsImportSettings(isEnabled: true),
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
  }) async {
    deps = HubScanDeps(
      capability: capability,
      settings: FakeSmsImportSettingsRepository(settings: settings),
    );
    await pumpSmsPage(
      tester,
      Scaffold(
        body: ListView(
          children: [
            BankMessagesHomeCard(
              capabilityAvailable: () async =>
                  (await deps.capability()).available,
              createCubit: () => buildHomeCubit(deps, repository: repository),
            ),
          ],
        ),
      ),
      locale: locale,
      theme: theme,
      textScale: textScale,
    );
  }

  List<Object> seedPending(int count) {
    final items = [
      for (var i = 0; i < count; i++)
        buildPendingImport(
          id: 'p$i',
          fingerprint: 'fp$i',
          merchant: 'Secret Merchant $i',
        ),
    ];
    repository.seed(items);
    return items;
  }

  testWidgets('no pending items: no count card', (tester) async {
    await pumpCard(tester);
    expect(countCard(), findsNothing);
  });

  testWidgets('shows the plural count only: no merchant, amount or text', (
    tester,
  ) async {
    seedPending(3);
    await pumpCard(tester);
    expect(countCard(), findsOneWidget);
    expect(find.text(en.smsImportHomeCardCount(3)), findsOneWidget);
    expect(find.textContaining('Secret Merchant'), findsNothing);
    expect(find.textContaining('125'), findsNothing);
    expect(find.textContaining('EGP'), findsNothing);
    // No tab or icon badge (FR-050).
    expect(find.byType(Badge), findsNothing);
  });

  testWidgets('follows the count live and hides at zero', (tester) async {
    await pumpCard(tester);
    expect(countCard(), findsNothing);
    seedPending(1);
    await tester.pumpAndSettle();
    expect(find.text(en.smsImportHomeCardCount(1)), findsOneWidget);
    await repository.ignore({'p0'});
    await tester.pumpAndSettle();
    expect(countCard(), findsNothing);
  });

  testWidgets('tap opens the hub', (tester) async {
    seedPending(2);
    await pumpCard(tester);
    await tester.tap(countCard());
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
  });

  testWidgets('without the capability (paste-only platforms) the count '
      'still shows and opens the hub; no onboarding, no prompt', (
    tester,
  ) async {
    seedPending(2);
    await pumpCard(tester, capability: false);
    expect(find.text(en.smsImportHomeCardCount(2)), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bank_messages_home_onboarding')),
      findsNothing,
    );
    expect(deps.permissions.statusChecks, 0);
    expect(deps.permissions.requests, 0);
    await tester.tap(countCard());
    await tester.pumpAndSettle();
    expect(find.text('hub-route'), findsOneWidget);
  });

  testWidgets('without the capability and nothing pending: no card', (
    tester,
  ) async {
    await pumpCard(
      tester,
      capability: false,
      settings: const SmsImportSettings(),
    );
    expect(countCard(), findsNothing);
    expect(
      find.byKey(const ValueKey('bank_messages_home_onboarding')),
      findsNothing,
    );
  });

  testWidgets('one screen-reader button with the count and a hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    seedPending(2);
    await pumpCard(tester);
    expect(
      tester.getSemantics(countCard()),
      isSemantics(
        label: en.smsImportHomeCardCount(2),
        hint: en.smsImportHomeCardHint,
        isButton: true,
      ),
    );
    expect(tester.getSize(countCard()).height, greaterThanOrEqualTo(48));
    handle.dispose();
  });

  test('Arabic count uses every plural form', () {
    final forms = {
      for (final n in [0, 1, 2, 3, 11, 100]) n: ar.smsImportHomeCardCount(n),
    };
    expect(forms.values.toSet(), hasLength(6));
    expect(forms[2], isNot(contains('2')));
    expect(forms[11], contains('11'));
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('renders in ${locale.name} / ${theme.name}', (tester) async {
        seedPending(12);
        await pumpCard(tester, locale: locale.locale, theme: theme.theme);
        expect(tester.takeException(), isNull);
        expect(countCard(), findsOneWidget);
      });
    }
  }

  testWidgets('200% Arabic text does not overflow', (tester) async {
    seedPending(25);
    await pumpCard(tester, locale: const Locale('ar'), textScale: 2);
    expect(tester.takeException(), isNull);
  });

  group('dashboard ordering', () {
    late _MockDashboardCubit dashboard;

    setUp(() {
      deps = HubScanDeps(capability: true);
      getIt
        ..registerFactory<GetSmsCapability>(() => deps.capability)
        ..registerFactory<BankMessagesHomeCubit>(
          () => buildHomeCubit(deps, repository: repository),
        );
      dashboard = _MockDashboardCubit();
      when(() => dashboard.refresh()).thenAnswer((_) async {});
    });
    tearDown(() async {
      await getIt.unregister<GetSmsCapability>();
      await getIt.unregister<BankMessagesHomeCubit>();
    });

    testWidgets('the quick action, count card and onboarding card all sit '
        'below the people summary', (tester) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      seedPending(2);
      when(() => dashboard.state).thenReturn(
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: OverviewSummary(
            totalOwedToUser: const Money.egp(1000),
            totalUserOwes: const Money.egp(0),
            peopleTheyOweYou: const [
              PersonSummary(
                personId: 'p1',
                name: 'Person A',
                net: Money.egp(1000),
                isArchived: false,
              ),
            ],
            peopleYouOweThem: const [],
            settledCount: 0,
          ),
          financeStatus: LoadStatus.success,
          financeSummary: FinanceSummary(
            totalIncome: const Money.egp(0),
            totalExpense: const Money.egp(0),
            period: DateRange(
              start: DateTime(2026, 9),
              end: DateTime(2026, 9, 30),
            ),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<DashboardCubit>.value(
            value: dashboard,
            child: const HomeView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double top(Finder f) => tester.getTopLeft(f).dy;
      final summary = top(find.byType(OverviewSummaryCard));
      final quickAction = top(find.text(en.smsImportHomeQuickAction));
      final person = top(find.text('Person A'));
      final count = top(countCard());
      final onboarding = top(
        find.byKey(const ValueKey('bank_messages_home_onboarding')),
      );
      final insights = top(find.byType(InsightsPlaceholderCard));

      expect(summary, lessThan(quickAction));
      expect(summary, lessThan(count));
      expect(summary, lessThan(onboarding));
      expect(person, lessThan(count));
      expect(count, lessThan(onboarding));
      expect(onboarding, lessThan(insights));
      expect(find.textContaining('Secret Merchant'), findsNothing);
      verifyNever(() => dashboard.refresh());
      verifyNever(() => dashboard.load());
      expect(deps.permissions.requests, 0);
    });
  });
}
