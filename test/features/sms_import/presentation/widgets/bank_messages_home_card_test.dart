import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/dashboard/presentation/pages/home_page.dart';
import 'package:daftary/features/dashboard/presentation/widgets/bank_messages_home_card.dart';
import 'package:daftary/features/dashboard/presentation/widgets/insights_placeholder_card.dart';
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

import '../../helpers/fakes.dart';
import '../../helpers/scan_presentation.dart';
import '../../helpers/widget_harness.dart';

class _MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

/// T122/T123 — the Home onboarding card (FR-004, ui-contract §2): shown
/// only with the flag and the capability, while off and never dismissed;
/// "Set up" opens the enable flow, "Dismiss" is permanent; its cubit is
/// created only with the flag (the count variant works without the
/// capability); it never prompts and sits below the people summary.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  late HubScanDeps deps;
  late int cubitsCreated;
  late int capabilityReads;

  setUp(() {
    cubitsCreated = 0;
    capabilityReads = 0;
  });
  tearDown(() => deps.settings.close());

  Future<void> pumpCard(
    WidgetTester tester, {
    bool flag = true,
    bool capability = true,
    SmsImportSettings settings = const SmsImportSettings(),
    Locale locale = const Locale('en'),
    ThemeData? theme,
    bool reuseDeps = false,
  }) async {
    if (!reuseDeps) {
      deps = HubScanDeps(
        capability: capability,
        settings: FakeSmsImportSettingsRepository(settings: settings),
      );
    }
    await pumpSmsPage(
      tester,
      Scaffold(
        body: ListView(
          children: [
            BankMessagesHomeCard(
              enabled: flag,
              capabilityAvailable: () async {
                capabilityReads++;
                return (await deps.capability()).available;
              },
              createCubit: () {
                cubitsCreated++;
                return buildHomeCubit(deps);
              },
            ),
          ],
        ),
      ),
      locale: locale,
      theme: theme,
    );
  }

  Finder card() => find.byKey(const ValueKey('bank_messages_home_onboarding'));

  testWidgets('flag off: nothing is read and no cubit is created', (
    tester,
  ) async {
    await pumpCard(tester, flag: false);
    expect(card(), findsNothing);
    expect(capabilityReads, 0);
    expect(cubitsCreated, 0);
  });

  testWidgets('no capability (iOS, macOS, SMS-free build): no onboarding '
      'card; the cubit only feeds the pending count (CHK036)', (tester) async {
    await pumpCard(tester, capability: false);
    expect(card(), findsNothing);
    expect(capabilityReads, 1);
    expect(cubitsCreated, 1);
    expect(deps.permissions.statusChecks, 0);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('capability, off, not dismissed: the card, without a prompt', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(card(), findsOneWidget);
    expect(find.text(en.smsImportHomeOnboardingText), findsOneWidget);
    expect(cubitsCreated, 1);
    expect(deps.permissions.requests, 0);
    expect(deps.permissions.statusChecks, 0);
  });

  testWidgets('already on: no card', (tester) async {
    await pumpCard(tester, settings: const SmsImportSettings(isEnabled: true));
    expect(card(), findsNothing);
  });

  testWidgets('Set up opens the enable flow, never the system prompt', (
    tester,
  ) async {
    await pumpCard(tester);
    await tester.tap(find.byKey(const ValueKey('bank_messages_home_set_up')));
    await tester.pumpAndSettle();
    expect(find.text('enable-route'), findsOneWidget);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('Dismiss is permanent', (tester) async {
    await pumpCard(tester);
    await tester.tap(find.byKey(const ValueKey('bank_messages_home_dismiss')));
    await tester.pumpAndSettle();
    expect(card(), findsNothing);
    expect(deps.settings.settings.onboardingDismissed, isTrue);

    // A later Home (a new card and cubit over the same settings).
    await tester.pumpWidget(const SizedBox());
    await pumpCard(tester, reuseDeps: true);
    expect(card(), findsNothing);
    expect(deps.permissions.requests, 0);
  });

  testWidgets('a failed dismiss keeps the card', (tester) async {
    await pumpCard(tester);
    deps.settings.nextFailure = const CacheFailure('x');
    await tester.tap(find.byKey(const ValueKey('bank_messages_home_dismiss')));
    await tester.pumpAndSettle();
    expect(card(), findsOneWidget);
  });

  for (final locale in smsLocales) {
    for (final theme in smsThemes) {
      testWidgets('renders in ${locale.name} / ${theme.name}', (tester) async {
        await pumpCard(tester, locale: locale.locale, theme: theme.theme);
        expect(tester.takeException(), isNull);
        expect(card(), findsOneWidget);
        expectTapTargets(tester, card());
      });
    }
  }

  group('on Home', () {
    late _MockDashboardCubit dashboard;

    setUp(() {
      deps = HubScanDeps(capability: true);
      getIt
        ..registerFactory<GetSmsCapability>(() => deps.capability)
        ..registerFactory<BankMessagesHomeCubit>(() => buildHomeCubit(deps));
      dashboard = _MockDashboardCubit();
      when(() => dashboard.refresh()).thenAnswer((_) async {});
    });
    tearDown(() async {
      await getIt.unregister<GetSmsCapability>();
      await getIt.unregister<BankMessagesHomeCubit>();
    });

    testWidgets('the card sits below the people summary; the dashboard '
        'cubit is untouched', (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
      expect(card(), findsOneWidget);
      final person = tester.getTopLeft(find.text('Person A')).dy;
      final onboarding = tester.getTopLeft(card()).dy;
      final insights = tester
          .getTopLeft(find.byType(InsightsPlaceholderCard))
          .dy;
      expect(person, lessThan(onboarding));
      expect(onboarding, lessThan(insights));
      verifyNever(() => dashboard.refresh());
      verifyNever(() => dashboard.load());
      expect(deps.permissions.requests, 0);
    });
  });
}
