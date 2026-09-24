// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:flutter/services.dart' as _i281;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/finance/data/datasources/finance_dao.dart' as _i443;
import '../../features/finance/data/repositories/category_repository_impl.dart'
    as _i816;
import '../../features/finance/data/repositories/finance_repository_impl.dart'
    as _i250;
import '../../features/finance/domain/repositories/category_repository.dart'
    as _i228;
import '../../features/finance/domain/repositories/finance_repository.dart'
    as _i137;
import '../../features/finance/domain/usecases/add_finance_entry.dart' as _i159;
import '../../features/finance/domain/usecases/create_category.dart' as _i24;
import '../../features/finance/domain/usecases/delete_finance_entry.dart'
    as _i1065;
import '../../features/finance/domain/usecases/edit_category.dart' as _i611;
import '../../features/finance/domain/usecases/edit_finance_entry.dart'
    as _i416;
import '../../features/finance/domain/usecases/get_categories.dart' as _i1;
import '../../features/finance/domain/usecases/get_category_breakdown.dart'
    as _i853;
import '../../features/finance/domain/usecases/get_finance_history.dart'
    as _i27;
import '../../features/finance/domain/usecases/get_finance_summary.dart'
    as _i844;
import '../../features/finance/domain/usecases/remove_category.dart' as _i490;
import '../../features/finance/domain/usecases/restore_finance_entry.dart'
    as _i1008;
import '../../features/finance/domain/usecases/seed_default_categories.dart'
    as _i717;
import '../../features/finance/presentation/cubit/category_form_cubit.dart'
    as _i1030;
import '../../features/finance/presentation/cubit/category_management_cubit.dart'
    as _i109;
import '../../features/finance/presentation/cubit/finance_entry_form_cubit.dart'
    as _i505;
import '../../features/finance/presentation/cubit/finance_history_cubit.dart'
    as _i987;
import '../../features/finance/presentation/cubit/finance_month_summary_cubit.dart'
    as _i231;
import '../../features/financial_education/data/datasources/bundled_education_content_data_source.dart'
    as _i445;
import '../../features/financial_education/data/repositories/education_content_repository_impl.dart'
    as _i549;
import '../../features/financial_education/domain/repositories/education_content_repository.dart'
    as _i1055;
import '../../features/financial_education/domain/services/compound_growth_calculator.dart'
    as _i585;
import '../../features/financial_education/domain/services/doubling_time_calculator.dart'
    as _i466;
import '../../features/financial_education/domain/services/savings_rate_calculator.dart'
    as _i35;
import '../../features/financial_education/domain/usecases/calculate_compound_growth.dart'
    as _i217;
import '../../features/financial_education/domain/usecases/calculate_doubling_time.dart'
    as _i435;
import '../../features/financial_education/domain/usecases/calculate_savings_rate.dart'
    as _i897;
import '../../features/financial_education/domain/usecases/get_article.dart'
    as _i481;
import '../../features/financial_education/domain/usecases/get_category_articles.dart'
    as _i657;
import '../../features/financial_education/domain/usecases/get_education_categories.dart'
    as _i805;
import '../../features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart'
    as _i60;
import '../../features/financial_education/presentation/cubit/article_cubit.dart'
    as _i274;
import '../../features/financial_education/presentation/cubit/category_cubit.dart'
    as _i518;
import '../../features/financial_education/presentation/cubit/compound_growth_calculator_cubit.dart'
    as _i896;
import '../../features/financial_education/presentation/cubit/content_library_cubit.dart'
    as _i265;
import '../../features/financial_education/presentation/cubit/doubling_time_calculator_cubit.dart'
    as _i811;
import '../../features/financial_education/presentation/cubit/savings_rate_calculator_cubit.dart'
    as _i66;
import '../../features/insights_notifications/data/datasources/in_memory_notification_last_run_store.dart'
    as _i770;
import '../../features/insights_notifications/data/datasources/notifications_dao.dart'
    as _i338;
import '../../features/insights_notifications/data/datasources/unavailable_budget_insights_source.dart'
    as _i763;
import '../../features/insights_notifications/data/datasources/unavailable_savings_insights_source.dart'
    as _i386;
import '../../features/insights_notifications/data/repositories/notification_history_repository_impl.dart'
    as _i551;
import '../../features/insights_notifications/data/repositories/notification_preference_repository_impl.dart'
    as _i701;
import '../../features/insights_notifications/data/services/flutter_local_notifications_scheduler.dart'
    as _i0;
import '../../features/insights_notifications/data/services/localized_notification_composer.dart'
    as _i900;
import '../../features/insights_notifications/data/services/settings_notification_language_provider.dart'
    as _i831;
import '../../features/insights_notifications/data/services/template_notification_phrasing_service.dart'
    as _i266;
import '../../features/insights_notifications/domain/ports/budget_insights_source.dart'
    as _i423;
import '../../features/insights_notifications/domain/ports/notification_language_provider.dart'
    as _i1003;
import '../../features/insights_notifications/domain/ports/savings_insights_source.dart'
    as _i842;
import '../../features/insights_notifications/domain/repositories/notification_history_repository.dart'
    as _i12;
import '../../features/insights_notifications/domain/repositories/notification_last_run_store.dart'
    as _i220;
import '../../features/insights_notifications/domain/repositories/notification_preference_repository.dart'
    as _i162;
import '../../features/insights_notifications/domain/services/evaluate_budget_notifications.dart'
    as _i983;
import '../../features/insights_notifications/domain/services/evaluate_savings_goal_notifications.dart'
    as _i371;
import '../../features/insights_notifications/domain/services/notification_composer.dart'
    as _i104;
import '../../features/insights_notifications/domain/services/notification_phrasing_service.dart'
    as _i721;
import '../../features/insights_notifications/domain/services/notification_scheduler.dart'
    as _i209;
import '../../features/insights_notifications/domain/usecases/handle_notification_tap.dart'
    as _i480;
import '../../features/insights_notifications/domain/usecases/notification_engine.dart'
    as _i552;
import '../../features/insights_notifications/domain/usecases/request_notification_permission.dart'
    as _i639;
import '../../features/insights_notifications/domain/usecases/set_notification_preferences.dart'
    as _i203;
import '../../features/insights_notifications/presentation/cubit/notification_settings_cubit.dart'
    as _i39;
import '../../features/insights_notifications/presentation/notification_recompute_trigger.dart'
    as _i548;
import '../../features/onboarding/data/datasources/onboarding_dao.dart'
    as _i360;
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i452;
import '../../features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i430;
import '../../features/onboarding/domain/usecases/resolve_onboarding_status.dart'
    as _i791;
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i807;
import '../../features/people/data/datasources/people_dao.dart' as _i735;
import '../../features/people/data/repositories/people_repository_impl.dart'
    as _i1029;
import '../../features/people/domain/repositories/people_repository.dart'
    as _i646;
import '../../features/people/domain/usecases/archive_person.dart' as _i221;
import '../../features/people/domain/usecases/create_person.dart' as _i789;
import '../../features/people/domain/usecases/delete_person.dart' as _i907;
import '../../features/people/domain/usecases/edit_person.dart' as _i101;
import '../../features/people/domain/usecases/find_possible_duplicate_person.dart'
    as _i769;
import '../../features/people/domain/usecases/restore_person.dart' as _i49;
import '../../features/people/presentation/cubit/archived_people_cubit.dart'
    as _i62;
import '../../features/people/presentation/cubit/person_form_cubit.dart'
    as _i668;
import '../../features/people/presentation/cubit/person_list_cubit.dart'
    as _i1018;
import '../../features/settings/data/datasources/settings_dao.dart' as _i586;
import '../../features/settings/data/repositories/settings_repository_impl.dart'
    as _i955;
import '../../features/settings/domain/repositories/settings_repository.dart'
    as _i674;
import '../../features/settings/domain/usecases/change_language.dart' as _i90;
import '../../features/settings/domain/usecases/change_theme_mode.dart' as _i46;
import '../../features/settings/domain/usecases/get_language_preference.dart'
    as _i1032;
import '../../features/settings/domain/usecases/get_theme_mode_preference.dart'
    as _i333;
import '../../features/settings/presentation/cubit/settings_cubit.dart'
    as _i792;
import '../../features/transactions/data/datasources/transactions_dao.dart'
    as _i684;
import '../../features/transactions/data/repositories/transactions_repository_impl.dart'
    as _i373;
import '../../features/transactions/domain/repositories/transactions_repository.dart'
    as _i957;
import '../../features/transactions/domain/usecases/add_transaction.dart'
    as _i5;
import '../../features/transactions/domain/usecases/delete_transaction.dart'
    as _i645;
import '../../features/transactions/domain/usecases/edit_transaction.dart'
    as _i554;
import '../../features/transactions/domain/usecases/get_overview.dart' as _i941;
import '../../features/transactions/domain/usecases/get_person_balance.dart'
    as _i750;
import '../../features/transactions/domain/usecases/get_person_history.dart'
    as _i610;
import '../../features/transactions/domain/usecases/record_repayment.dart'
    as _i426;
import '../../features/transactions/presentation/cubit/overview_cubit.dart'
    as _i305;
import '../../features/transactions/presentation/cubit/person_detail_cubit.dart'
    as _i992;
import '../../features/transactions/presentation/cubit/repayment_form_cubit.dart'
    as _i34;
import '../../features/transactions/presentation/cubit/transaction_form_cubit.dart'
    as _i593;
import '../database/app_database.dart' as _i982;
import '../date/app_clock.dart' as _i956;
import '../device/device_locale_provider.dart' as _i933;
import '../money/egp_formatter.dart' as _i999;
import '../routing/notification_tap_router.dart' as _i172;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i60.GetPrefillableSavingsGoalAmount>(
      () => const _i60.GetPrefillableSavingsGoalAmount(),
    );
    gh.factory<_i769.FindPossibleDuplicatePerson>(
      () => const _i769.FindPossibleDuplicatePerson(),
    );
    gh.lazySingleton<_i982.AppDatabase>(() => registerModule.appDatabase);
    gh.lazySingleton<_i999.EgpFormatter>(() => registerModule.egpFormatter);
    gh.lazySingleton<_i281.AssetBundle>(() => registerModule.assetBundle);
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => registerModule.localNotificationsPlugin,
    );
    gh.lazySingleton<_i423.BudgetInsightsSource>(
      () => const _i763.UnavailableBudgetInsightsSource(),
    );
    gh.lazySingleton<_i721.NotificationPhrasingService>(
      () => const _i266.TemplateNotificationPhrasingService(),
    );
    gh.lazySingleton<_i983.EvaluateBudgetNotifications>(
      () => const _i983.EvaluateBudgetNotificationsImpl(),
    );
    gh.lazySingleton<_i371.EvaluateSavingsGoalNotifications>(
      () => const _i371.EvaluateSavingsGoalNotificationsImpl(),
    );
    gh.lazySingleton<_i35.SavingsRateCalculator>(
      () => const _i35.SavingsRateCalculatorImpl(),
    );
    gh.lazySingleton<_i466.DoublingTimeCalculator>(
      () => const _i466.DoublingTimeCalculatorImpl(),
    );
    gh.lazySingleton<_i933.DeviceLocaleProvider>(
      () => _i933.DeviceLocaleProviderImpl(),
    );
    gh.lazySingleton<_i585.CompoundGrowthCalculator>(
      () => const _i585.CompoundGrowthCalculatorImpl(),
    );
    gh.lazySingleton<_i104.NotificationComposer>(
      () => const _i900.LocalizedNotificationComposer(),
    );
    gh.lazySingleton<_i956.AppClock>(() => const _i956.SystemAppClock());
    gh.lazySingleton<_i220.NotificationLastRunStore>(
      () => _i770.InMemoryNotificationLastRunStore(),
    );
    gh.lazySingleton<_i842.SavingsInsightsSource>(
      () => const _i386.UnavailableSavingsInsightsSource(),
    );
    gh.factory<_i897.CalculateSavingsRate>(
      () => _i897.CalculateSavingsRate(gh<_i35.SavingsRateCalculator>()),
    );
    gh.factory<_i435.CalculateDoublingTime>(
      () => _i435.CalculateDoublingTime(gh<_i466.DoublingTimeCalculator>()),
    );
    gh.lazySingleton<_i445.BundledEducationContentDataSource>(
      () => _i445.BundledEducationContentDataSource(gh<_i281.AssetBundle>()),
    );
    gh.lazySingleton<_i1055.EducationContentRepository>(
      () => _i549.EducationContentRepositoryImpl(
        gh<_i445.BundledEducationContentDataSource>(),
      ),
    );
    gh.factory<_i217.CalculateCompoundGrowth>(
      () => _i217.CalculateCompoundGrowth(gh<_i585.CompoundGrowthCalculator>()),
    );
    gh.factory<_i443.FinanceDao>(
      () => _i443.FinanceDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i338.NotificationsDao>(
      () => _i338.NotificationsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i360.OnboardingDao>(
      () => _i360.OnboardingDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i735.PeopleDao>(() => _i735.PeopleDao(gh<_i982.AppDatabase>()));
    gh.factory<_i586.SettingsDao>(
      () => _i586.SettingsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i684.TransactionsDao>(
      () => _i684.TransactionsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i896.CompoundGrowthCalculatorCubit>(
      () => _i896.CompoundGrowthCalculatorCubit(
        gh<_i217.CalculateCompoundGrowth>(),
        gh<_i60.GetPrefillableSavingsGoalAmount>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.lazySingleton<_i209.NotificationScheduler>(
      () => _i0.FlutterLocalNotificationsScheduler(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.factory<_i480.HandleNotificationTap>(
      () => _i480.HandleNotificationTap(
        gh<_i423.BudgetInsightsSource>(),
        gh<_i842.SavingsInsightsSource>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.lazySingleton<_i172.NotificationTapRouter>(
      () => _i172.NotificationTapRouter(
        gh<_i209.NotificationScheduler>(),
        gh<_i480.HandleNotificationTap>(),
      ),
    );
    gh.lazySingleton<_i430.OnboardingRepository>(
      () => _i452.OnboardingRepositoryImpl(gh<_i360.OnboardingDao>()),
    );
    gh.lazySingleton<_i957.TransactionsRepository>(
      () => _i373.TransactionsRepositoryImpl(
        gh<_i684.TransactionsDao>(),
        gh<_i982.AppDatabase>(),
      ),
    );
    gh.factory<_i66.SavingsRateCalculatorCubit>(
      () => _i66.SavingsRateCalculatorCubit(
        gh<_i897.CalculateSavingsRate>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.factory<_i811.DoublingTimeCalculatorCubit>(
      () => _i811.DoublingTimeCalculatorCubit(
        gh<_i435.CalculateDoublingTime>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.factory<_i481.GetArticle>(
      () => _i481.GetArticle(gh<_i1055.EducationContentRepository>()),
    );
    gh.factory<_i657.GetCategoryArticles>(
      () => _i657.GetCategoryArticles(gh<_i1055.EducationContentRepository>()),
    );
    gh.factory<_i805.GetEducationCategories>(
      () =>
          _i805.GetEducationCategories(gh<_i1055.EducationContentRepository>()),
    );
    gh.lazySingleton<_i137.FinanceRepository>(
      () => _i250.FinanceRepositoryImpl(gh<_i443.FinanceDao>()),
    );
    gh.lazySingleton<_i646.PeopleRepository>(
      () => _i1029.PeopleRepositoryImpl(
        gh<_i735.PeopleDao>(),
        gh<_i769.FindPossibleDuplicatePerson>(),
        gh<_i982.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i228.CategoryRepository>(
      () => _i816.CategoryRepositoryImpl(gh<_i443.FinanceDao>()),
    );
    gh.lazySingleton<_i674.SettingsRepository>(
      () => _i955.SettingsRepositoryImpl(gh<_i586.SettingsDao>()),
    );
    gh.factory<_i791.ResolveOnboardingStatus>(
      () => _i791.ResolveOnboardingStatus(
        gh<_i430.OnboardingRepository>(),
        gh<_i646.PeopleRepository>(),
        gh<_i957.TransactionsRepository>(),
      ),
    );
    gh.factory<_i221.ArchivePerson>(
      () => _i221.ArchivePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i789.CreatePerson>(
      () => _i789.CreatePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i907.DeletePerson>(
      () => _i907.DeletePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i101.EditPerson>(
      () => _i101.EditPerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i49.RestorePerson>(
      () => _i49.RestorePerson(gh<_i646.PeopleRepository>()),
    );
    gh.lazySingleton<_i12.NotificationHistoryRepository>(
      () =>
          _i551.NotificationHistoryRepositoryImpl(gh<_i338.NotificationsDao>()),
    );
    gh.lazySingleton<_i162.NotificationPreferenceRepository>(
      () => _i701.NotificationPreferenceRepositoryImpl(
        gh<_i338.NotificationsDao>(),
      ),
    );
    gh.factory<_i265.ContentLibraryCubit>(
      () => _i265.ContentLibraryCubit(gh<_i805.GetEducationCategories>()),
    );
    gh.factory<_i5.AddTransaction>(
      () => _i5.AddTransaction(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i645.DeleteTransaction>(
      () => _i645.DeleteTransaction(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i554.EditTransaction>(
      () => _i554.EditTransaction(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i941.GetOverview>(
      () => _i941.GetOverview(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i750.GetPersonBalance>(
      () => _i750.GetPersonBalance(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i610.GetPersonHistory>(
      () => _i610.GetPersonHistory(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i426.RecordRepayment>(
      () => _i426.RecordRepayment(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i90.ChangeLanguage>(
      () => _i90.ChangeLanguage(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i46.ChangeThemeMode>(
      () => _i46.ChangeThemeMode(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i1032.GetLanguagePreference>(
      () => _i1032.GetLanguagePreference(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i333.GetThemeModePreference>(
      () => _i333.GetThemeModePreference(gh<_i674.SettingsRepository>()),
    );
    gh.factoryParam<_i34.RepaymentFormCubit, String, dynamic>(
      (personId, _) => _i34.RepaymentFormCubit(
        gh<_i426.RecordRepayment>(),
        gh<_i999.EgpFormatter>(),
        personId,
      ),
    );
    gh.factory<_i274.ArticleCubit>(
      () => _i274.ArticleCubit(gh<_i481.GetArticle>()),
    );
    gh.factory<_i1018.PersonListCubit>(
      () => _i1018.PersonListCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i750.GetPersonBalance>(),
        gh<_i221.ArchivePerson>(),
      ),
    );
    gh.factory<_i518.CategoryCubit>(
      () => _i518.CategoryCubit(gh<_i657.GetCategoryArticles>()),
    );
    gh.factory<_i24.CreateCategory>(
      () => _i24.CreateCategory(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i611.EditCategory>(
      () => _i611.EditCategory(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i1.GetCategories>(
      () => _i1.GetCategories(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i490.RemoveCategory>(
      () => _i490.RemoveCategory(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i717.SeedDefaultCategories>(
      () => _i717.SeedDefaultCategories(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i159.AddFinanceEntry>(
      () => _i159.AddFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i1065.DeleteFinanceEntry>(
      () => _i1065.DeleteFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i416.EditFinanceEntry>(
      () => _i416.EditFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i853.GetCategoryBreakdown>(
      () => _i853.GetCategoryBreakdown(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i27.GetFinanceHistory>(
      () => _i27.GetFinanceHistory(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i844.GetFinanceSummary>(
      () => _i844.GetFinanceSummary(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i1008.RestoreFinanceEntry>(
      () => _i1008.RestoreFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i987.FinanceHistoryCubit>(
      () => _i987.FinanceHistoryCubit(
        gh<_i844.GetFinanceSummary>(),
        gh<_i853.GetCategoryBreakdown>(),
        gh<_i27.GetFinanceHistory>(),
        gh<_i1.GetCategories>(),
        gh<_i1065.DeleteFinanceEntry>(),
        gh<_i1008.RestoreFinanceEntry>(),
        gh<_i137.FinanceRepository>(),
      ),
    );
    gh.lazySingleton<_i807.OnboardingCubit>(
      () => _i807.OnboardingCubit(
        gh<_i791.ResolveOnboardingStatus>(),
        gh<_i430.OnboardingRepository>(),
      ),
    );
    gh.factory<_i203.SetNotificationPreferences>(
      () => _i203.SetNotificationPreferences(
        gh<_i162.NotificationPreferenceRepository>(),
      ),
    );
    gh.factory<_i231.FinanceMonthSummaryCubit>(
      () => _i231.FinanceMonthSummaryCubit(gh<_i844.GetFinanceSummary>()),
    );
    gh.lazySingleton<_i1003.NotificationLanguageProvider>(
      () => _i831.SettingsNotificationLanguageProvider(
        gh<_i1032.GetLanguagePreference>(),
        gh<_i933.DeviceLocaleProvider>(),
      ),
    );
    gh.lazySingleton<_i792.SettingsCubit>(
      () => _i792.SettingsCubit(
        gh<_i1032.GetLanguagePreference>(),
        gh<_i90.ChangeLanguage>(),
        gh<_i933.DeviceLocaleProvider>(),
        gh<_i333.GetThemeModePreference>(),
        gh<_i46.ChangeThemeMode>(),
      ),
    );
    gh.lazySingleton<_i552.NotificationEngine>(
      () => _i552.NotificationEngineImpl(
        gh<_i162.NotificationPreferenceRepository>(),
        gh<_i12.NotificationHistoryRepository>(),
        gh<_i423.BudgetInsightsSource>(),
        gh<_i842.SavingsInsightsSource>(),
        gh<_i983.EvaluateBudgetNotifications>(),
        gh<_i371.EvaluateSavingsGoalNotifications>(),
        gh<_i104.NotificationComposer>(),
        gh<_i721.NotificationPhrasingService>(),
        gh<_i209.NotificationScheduler>(),
        gh<_i956.AppClock>(),
        gh<_i1003.NotificationLanguageProvider>(),
        gh<_i220.NotificationLastRunStore>(),
      ),
    );
    gh.factory<_i505.FinanceEntryFormCubit>(
      () => _i505.FinanceEntryFormCubit(
        gh<_i159.AddFinanceEntry>(),
        gh<_i416.EditFinanceEntry>(),
        gh<_i1.GetCategories>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.factory<_i668.PersonFormCubit>(
      () => _i668.PersonFormCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i789.CreatePerson>(),
        gh<_i101.EditPerson>(),
        gh<_i221.ArchivePerson>(),
        gh<_i907.DeletePerson>(),
      ),
    );
    gh.factory<_i593.TransactionFormCubit>(
      () => _i593.TransactionFormCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i789.CreatePerson>(),
        gh<_i5.AddTransaction>(),
        gh<_i554.EditTransaction>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.lazySingleton<_i548.NotificationRecomputeTrigger>(
      () => _i548.NotificationRecomputeTrigger(
        gh<_i552.NotificationEngine>(),
        gh<_i220.NotificationLastRunStore>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.factory<_i62.ArchivedPeopleCubit>(
      () => _i62.ArchivedPeopleCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i49.RestorePerson>(),
      ),
    );
    gh.factory<_i639.RequestNotificationPermission>(
      () => _i639.RequestNotificationPermission(
        gh<_i209.NotificationScheduler>(),
        gh<_i162.NotificationPreferenceRepository>(),
      ),
    );
    gh.factory<_i992.PersonDetailCubit>(
      () => _i992.PersonDetailCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i750.GetPersonBalance>(),
        gh<_i610.GetPersonHistory>(),
        gh<_i645.DeleteTransaction>(),
      ),
    );
    gh.factory<_i305.OverviewCubit>(
      () => _i305.OverviewCubit(gh<_i941.GetOverview>()),
    );
    gh.factory<_i1030.CategoryFormCubit>(
      () => _i1030.CategoryFormCubit(
        gh<_i24.CreateCategory>(),
        gh<_i611.EditCategory>(),
      ),
    );
    gh.factory<_i109.CategoryManagementCubit>(
      () => _i109.CategoryManagementCubit(
        gh<_i1.GetCategories>(),
        gh<_i490.RemoveCategory>(),
      ),
    );
    gh.factory<_i39.NotificationSettingsCubit>(
      () => _i39.NotificationSettingsCubit(
        gh<_i203.SetNotificationPreferences>(),
        gh<_i639.RequestNotificationPermission>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
