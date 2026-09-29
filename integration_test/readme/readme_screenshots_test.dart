import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/savings/domain/repositories/savings_repository.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/settings/presentation/debug/debug_seed_tile.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Captures the screenshots used by README.md into `docs/screenshots/`.
///
/// Not a behavior test: it seeds a fresh in-memory database with the debug
/// seeder plus a couple of savings goals, then visits each screen and prints
/// a `README_SHOT:<name>` marker. `tool/readme_screenshots.sh` watches for
/// the marker and takes a real simulator screenshot, so the Liquid Glass
/// shaders and the status bar are captured as the user sees them.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false;
    await configureDependencies();
    getIt
      ..unregister<db.AppDatabase>()
      ..registerSingleton<db.AppDatabase>(
        db.AppDatabase.forTesting(NativeDatabase.memory()),
      );
    await getIt<OnboardingRepository>().completeOnboarding();
    await getIt<AppStartupCubit>().start();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> shot(WidgetTester tester, String route, String name) async {
    appRouter.go(route);
    await settle(tester);
    debugPrint('README_SHOT:$name');
    // Give the host script time to grab the simulator screen.
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  testWidgets('README screenshots', (tester) async {
    await getIt<CurrencyRepository>().setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 48.5,
    );
    await DebugSeeder().seed();

    final savings = getIt<SavingsRepository>();
    final now = DateTime.now();
    final goal = (await savings.createSavingsGoal(
      idempotencyKey: 'readme-goal-car',
      name: 'عربية جديدة',
      currency: Currency.egp,
      targetAmountMinorUnits: 40000000,
      startingAmountMinorUnits: 12000000,
      monthlyContributionMinorUnits: 1500000,
    )).getOrElse((f) => throw StateError(f.message));
    for (var m = 1; m <= 3; m++) {
      await savings.logContribution(
        idempotencyKey: 'readme-goal-car-$m',
        goalId: goal.id,
        amount: Money.egp(1500000),
        date: DateTime(now.year, now.month - m, 5),
      );
    }
    await savings.createSavingsGoal(
      idempotencyKey: 'readme-goal-hajj',
      name: 'صندوق الطوارئ',
      currency: Currency.egp,
      targetAmountMinorUnits: 10000000,
      startingAmountMinorUnits: 6500000,
      targetDate: DateTime(now.year + 1, 6),
    );

    final people = (await getIt<PeopleRepository>().searchActivePeople())
        .getOrElse((f) => throw StateError(f.message));
    final ahmed = people.firstWhere((p) => p.name == 'أحمد مصطفى');
    final occasions = (await getIt<OccasionsRepository>().getOccasionsList())
        .getOrElse((f) => throw StateError(f.message));

    final settings = getIt<SettingsCubit>();
    await settings.changeLanguage(AppLanguage.english);
    await settings.changeThemeMode(AppThemeMode.light);

    appRouter.go('/overview');
    await tester.pumpWidget(const DaftaryApp());
    await settle(tester);

    await shot(tester, '/overview', 'en_home');
    await shot(tester, '/', 'en_people');
    await shot(tester, '/people/${ahmed.id}', 'en_person_detail');
    if (occasions.isNotEmpty) {
      await shot(tester, '/occasions/${occasions.first.id}', 'en_occasion');
    }
    await shot(tester, '/finance', 'en_finance');
    await shot(tester, '/budgets', 'en_budget');
    await shot(tester, '/savings', 'en_savings');
    await shot(tester, '/savings/${goal.id}', 'en_savings_goal');
    await shot(tester, '/finance/reports', 'en_reports');
    await shot(tester, '/financial-education', 'en_education');
    await shot(tester, '/settings', 'en_settings');

    await settings.changeLanguage(AppLanguage.arabic);
    await settle(tester);
    await shot(tester, '/overview', 'ar_home');
    await shot(tester, '/', 'ar_people');
    await shot(tester, '/people/${ahmed.id}', 'ar_person_detail');
    await shot(tester, '/budgets', 'ar_budget');

    await settings.changeThemeMode(AppThemeMode.dark);
    await settle(tester);
    await shot(tester, '/overview', 'ar_home_dark');
    await shot(tester, '/savings/${goal.id}', 'ar_savings_goal_dark');

    await settings.changeLanguage(AppLanguage.english);
    await settle(tester);
    await shot(tester, '/overview', 'en_home_dark');
    await shot(tester, '/people/${ahmed.id}', 'en_person_detail_dark');
  });
}
