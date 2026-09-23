// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:image_picker/image_picker.dart' as _i183;
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
import '../../features/occasions/data/datasources/occasions_dao.dart' as _i791;
import '../../features/occasions/data/repositories/occasions_repository_impl.dart'
    as _i454;
import '../../features/occasions/domain/repositories/occasions_repository.dart'
    as _i72;
import '../../features/occasions/domain/usecases/add_occasion_attachment.dart'
    as _i247;
import '../../features/occasions/domain/usecases/add_participant_contribution.dart'
    as _i415;
import '../../features/occasions/domain/usecases/archive_occasion.dart'
    as _i847;
import '../../features/occasions/domain/usecases/create_occasion.dart' as _i905;
import '../../features/occasions/domain/usecases/delete_occasion.dart'
    as _i1046;
import '../../features/occasions/domain/usecases/edit_occasion.dart' as _i712;
import '../../features/occasions/domain/usecases/edit_participant_contribution.dart'
    as _i152;
import '../../features/occasions/domain/usecases/get_occasion_detail.dart'
    as _i431;
import '../../features/occasions/domain/usecases/get_occasions_list.dart'
    as _i957;
import '../../features/occasions/domain/usecases/remove_occasion_attachment.dart'
    as _i191;
import '../../features/occasions/domain/usecases/remove_participant_contribution.dart'
    as _i192;
import '../../features/occasions/domain/usecases/restore_occasion.dart'
    as _i154;
import '../../features/occasions/presentation/cubit/archived_occasions_cubit.dart'
    as _i185;
import '../../features/occasions/presentation/cubit/occasion_detail_cubit.dart'
    as _i52;
import '../../features/occasions/presentation/cubit/occasion_form_cubit.dart'
    as _i13;
import '../../features/occasions/presentation/cubit/occasions_list_cubit.dart'
    as _i193;
import '../../features/occasions/presentation/cubit/participant_form_cubit.dart'
    as _i218;
import '../../features/ocr/data/datasources/ocr_dao.dart' as _i976;
import '../../features/ocr/data/parsing/candidate_entry_parser.dart' as _i918;
import '../../features/ocr/data/preparation/image_preparation_service_impl.dart'
    as _i450;
import '../../features/ocr/data/recognition/text_recognition_service_impl.dart'
    as _i428;
import '../../features/ocr/data/repositories/ocr_repository_impl.dart' as _i457;
import '../../features/ocr/domain/repositories/image_preparation_service.dart'
    as _i235;
import '../../features/ocr/domain/repositories/ocr_repository.dart' as _i577;
import '../../features/ocr/domain/repositories/text_recognition_service.dart'
    as _i176;
import '../../features/ocr/domain/usecases/cancel_scan.dart' as _i377;
import '../../features/ocr/domain/usecases/confirm_scan_batch.dart' as _i664;
import '../../features/ocr/domain/usecases/delete_scan.dart' as _i413;
import '../../features/ocr/domain/usecases/discard_candidate_entry.dart'
    as _i256;
import '../../features/ocr/domain/usecases/edit_candidate_entry.dart' as _i506;
import '../../features/ocr/domain/usecases/get_candidate_entries.dart' as _i302;
import '../../features/ocr/domain/usecases/get_possible_duplicate_for_candidate.dart'
    as _i20;
import '../../features/ocr/domain/usecases/get_scan_detail.dart' as _i267;
import '../../features/ocr/domain/usecases/get_scan_history.dart' as _i331;
import '../../features/ocr/domain/usecases/run_ocr_extraction.dart' as _i350;
import '../../features/ocr/domain/usecases/set_batch_default_direction.dart'
    as _i1011;
import '../../features/ocr/domain/usecases/start_scan.dart' as _i856;
import '../../features/ocr/domain/usecases/tag_batch_to_occasion.dart' as _i237;
import '../../features/ocr/presentation/cubit/image_prep_cubit.dart' as _i427;
import '../../features/ocr/presentation/cubit/scan_capture_cubit.dart' as _i354;
import '../../features/ocr/presentation/cubit/scan_detail_cubit.dart' as _i919;
import '../../features/ocr/presentation/cubit/scan_history_cubit.dart' as _i622;
import '../../features/ocr/presentation/cubit/scan_review_cubit.dart' as _i621;
import '../../features/onboarding/data/datasources/onboarding_dao.dart'
    as _i360;
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i452;
import '../../features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i430;
import '../../features/onboarding/domain/usecases/resolve_onboarding_status.dart'
    as _i792;
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
    as _i793;
import '../../features/transactions/data/datasources/transactions_dao.dart'
    as _i684;
import '../../features/transactions/data/repositories/transactions_repository_impl.dart'
    as _i373;
import '../../features/transactions/domain/repositories/transactions_repository.dart'
    as _i956;
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
import '../device/device_locale_provider.dart' as _i933;
import '../media/attachment_picker_service.dart' as _i780;
import '../media/attachment_picker_service_impl.dart' as _i157;
import '../money/egp_formatter.dart' as _i999;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i769.FindPossibleDuplicatePerson>(
      () => const _i769.FindPossibleDuplicatePerson(),
    );
    gh.lazySingleton<_i982.AppDatabase>(() => registerModule.appDatabase);
    gh.lazySingleton<_i999.EgpFormatter>(() => registerModule.egpFormatter);
    gh.lazySingleton<_i183.ImagePicker>(() => registerModule.imagePicker);
    gh.lazySingleton<_i780.DocumentsDirectory>(
      () => const _i780.DocumentsDirectory(),
    );
    gh.lazySingleton<_i918.CandidateEntryParser>(
      () => const _i918.CandidateEntryParser(),
    );
    gh.lazySingleton<_i450.ImageCropperClient>(
      () => const _i450.ImageCropperClient(),
    );
    gh.lazySingleton<_i933.DeviceLocaleProvider>(
      () => _i933.DeviceLocaleProviderImpl(),
    );
    gh.lazySingleton<_i176.TextRecognitionService>(
      () => _i428.TextRecognitionServiceImpl(),
    );
    gh.lazySingleton<_i780.AttachmentPickerService>(
      () => _i157.AttachmentPickerServiceImpl(
        gh<_i183.ImagePicker>(),
        gh<_i780.DocumentsDirectory>(),
      ),
    );
    gh.lazySingleton<_i235.ImagePreparationService>(
      () => _i450.ImagePreparationServiceImpl(
        gh<_i450.ImageCropperClient>(),
        gh<_i780.DocumentsDirectory>(),
      ),
    );
    gh.factory<_i354.ScanCaptureCubit>(
      () => _i354.ScanCaptureCubit(
        gh<_i780.AttachmentPickerService>(),
        gh<_i235.ImagePreparationService>(),
        gh<_i176.TextRecognitionService>(),
      ),
    );
    gh.factory<_i443.FinanceDao>(
      () => _i443.FinanceDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i791.OccasionsDao>(
      () => _i791.OccasionsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i976.OcrDao>(() => _i976.OcrDao(gh<_i982.AppDatabase>()));
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
    gh.lazySingleton<_i430.OnboardingRepository>(
      () => _i452.OnboardingRepositoryImpl(gh<_i360.OnboardingDao>()),
    );
    gh.lazySingleton<_i956.TransactionsRepository>(
      () => _i373.TransactionsRepositoryImpl(
        gh<_i684.TransactionsDao>(),
        gh<_i982.AppDatabase>(),
      ),
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
    gh.factory<_i20.GetPossibleDuplicateForCandidate>(
      () => _i20.GetPossibleDuplicateForCandidate(
        gh<_i646.PeopleRepository>(),
        gh<_i769.FindPossibleDuplicatePerson>(),
      ),
    );
    gh.lazySingleton<_i674.SettingsRepository>(
      () => _i955.SettingsRepositoryImpl(gh<_i586.SettingsDao>()),
    );
    gh.factory<_i792.ResolveOnboardingStatus>(
      () => _i792.ResolveOnboardingStatus(
        gh<_i430.OnboardingRepository>(),
        gh<_i646.PeopleRepository>(),
        gh<_i956.TransactionsRepository>(),
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
    gh.factory<_i5.AddTransaction>(
      () => _i5.AddTransaction(gh<_i956.TransactionsRepository>()),
    );
    gh.factory<_i645.DeleteTransaction>(
      () => _i645.DeleteTransaction(gh<_i956.TransactionsRepository>()),
    );
    gh.factory<_i554.EditTransaction>(
      () => _i554.EditTransaction(gh<_i956.TransactionsRepository>()),
    );
    gh.factory<_i941.GetOverview>(
      () => _i941.GetOverview(gh<_i956.TransactionsRepository>()),
    );
    gh.factory<_i750.GetPersonBalance>(
      () => _i750.GetPersonBalance(gh<_i956.TransactionsRepository>()),
    );
    gh.factory<_i610.GetPersonHistory>(
      () => _i610.GetPersonHistory(gh<_i956.TransactionsRepository>()),
    );
    gh.factory<_i426.RecordRepayment>(
      () => _i426.RecordRepayment(gh<_i956.TransactionsRepository>()),
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
    gh.lazySingleton<_i72.OccasionsRepository>(
      () => _i454.OccasionsRepositoryImpl(
        gh<_i791.OccasionsDao>(),
        gh<_i956.TransactionsRepository>(),
        gh<_i646.PeopleRepository>(),
        gh<_i982.AppDatabase>(),
      ),
    );
    gh.factory<_i1018.PersonListCubit>(
      () => _i1018.PersonListCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i750.GetPersonBalance>(),
        gh<_i221.ArchivePerson>(),
      ),
    );
    gh.factory<_i992.PersonDetailCubit>(
      () => _i992.PersonDetailCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i750.GetPersonBalance>(),
        gh<_i610.GetPersonHistory>(),
        gh<_i645.DeleteTransaction>(),
        gh<_i956.TransactionsRepository>(),
      ),
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
        gh<_i792.ResolveOnboardingStatus>(),
        gh<_i430.OnboardingRepository>(),
      ),
    );
    gh.factory<_i247.AddOccasionAttachment>(
      () => _i247.AddOccasionAttachment(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i415.AddParticipantContribution>(
      () => _i415.AddParticipantContribution(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i847.ArchiveOccasion>(
      () => _i847.ArchiveOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i905.CreateOccasion>(
      () => _i905.CreateOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i1046.DeleteOccasion>(
      () => _i1046.DeleteOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i712.EditOccasion>(
      () => _i712.EditOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i152.EditParticipantContribution>(
      () => _i152.EditParticipantContribution(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i431.GetOccasionDetail>(
      () => _i431.GetOccasionDetail(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i957.GetOccasionsList>(
      () => _i957.GetOccasionsList(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i191.RemoveOccasionAttachment>(
      () => _i191.RemoveOccasionAttachment(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i192.RemoveParticipantContribution>(
      () => _i192.RemoveParticipantContribution(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i154.RestoreOccasion>(
      () => _i154.RestoreOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i231.FinanceMonthSummaryCubit>(
      () => _i231.FinanceMonthSummaryCubit(gh<_i844.GetFinanceSummary>()),
    );
    gh.lazySingleton<_i793.SettingsCubit>(
      () => _i793.SettingsCubit(
        gh<_i1032.GetLanguagePreference>(),
        gh<_i90.ChangeLanguage>(),
        gh<_i933.DeviceLocaleProvider>(),
        gh<_i333.GetThemeModePreference>(),
        gh<_i46.ChangeThemeMode>(),
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
    gh.factory<_i218.ParticipantFormCubit>(
      () => _i218.ParticipantFormCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i789.CreatePerson>(),
        gh<_i415.AddParticipantContribution>(),
        gh<_i152.EditParticipantContribution>(),
        gh<_i999.EgpFormatter>(),
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
    gh.factory<_i52.OccasionDetailCubit>(
      () => _i52.OccasionDetailCubit(
        gh<_i431.GetOccasionDetail>(),
        gh<_i192.RemoveParticipantContribution>(),
        gh<_i247.AddOccasionAttachment>(),
        gh<_i191.RemoveOccasionAttachment>(),
        gh<_i847.ArchiveOccasion>(),
        gh<_i154.RestoreOccasion>(),
        gh<_i1046.DeleteOccasion>(),
        gh<_i780.AttachmentPickerService>(),
      ),
    );
    gh.factory<_i62.ArchivedPeopleCubit>(
      () => _i62.ArchivedPeopleCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i49.RestorePerson>(),
      ),
    );
    gh.lazySingleton<_i577.OcrRepository>(
      () => _i457.OcrRepositoryImpl(
        gh<_i976.OcrDao>(),
        gh<_i176.TextRecognitionService>(),
        gh<_i918.CandidateEntryParser>(),
        gh<_i956.TransactionsRepository>(),
        gh<_i72.OccasionsRepository>(),
        gh<_i646.PeopleRepository>(),
      ),
    );
    gh.factory<_i305.OverviewCubit>(
      () => _i305.OverviewCubit(gh<_i941.GetOverview>()),
    );
    gh.factory<_i185.ArchivedOccasionsCubit>(
      () => _i185.ArchivedOccasionsCubit(
        gh<_i957.GetOccasionsList>(),
        gh<_i154.RestoreOccasion>(),
      ),
    );
    gh.factory<_i1030.CategoryFormCubit>(
      () => _i1030.CategoryFormCubit(
        gh<_i24.CreateCategory>(),
        gh<_i611.EditCategory>(),
      ),
    );
    gh.factory<_i13.OccasionFormCubit>(
      () => _i13.OccasionFormCubit(
        gh<_i905.CreateOccasion>(),
        gh<_i712.EditOccasion>(),
      ),
    );
    gh.factory<_i109.CategoryManagementCubit>(
      () => _i109.CategoryManagementCubit(
        gh<_i1.GetCategories>(),
        gh<_i490.RemoveCategory>(),
      ),
    );
    gh.factory<_i377.CancelScan>(
      () => _i377.CancelScan(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i664.ConfirmScanBatch>(
      () => _i664.ConfirmScanBatch(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i413.DeleteScan>(
      () => _i413.DeleteScan(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i256.DiscardCandidateEntry>(
      () => _i256.DiscardCandidateEntry(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i506.EditCandidateEntry>(
      () => _i506.EditCandidateEntry(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i302.GetCandidateEntries>(
      () => _i302.GetCandidateEntries(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i267.GetScanDetail>(
      () => _i267.GetScanDetail(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i331.GetScanHistory>(
      () => _i331.GetScanHistory(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i350.RunOcrExtraction>(
      () => _i350.RunOcrExtraction(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i1011.SetBatchDefaultDirection>(
      () => _i1011.SetBatchDefaultDirection(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i856.StartScan>(
      () => _i856.StartScan(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i237.TagBatchToOccasion>(
      () => _i237.TagBatchToOccasion(gh<_i577.OcrRepository>()),
    );
    gh.factory<_i193.OccasionsListCubit>(
      () => _i193.OccasionsListCubit(gh<_i957.GetOccasionsList>()),
    );
    gh.factory<_i621.ScanReviewCubit>(
      () => _i621.ScanReviewCubit(
        gh<_i267.GetScanDetail>(),
        gh<_i302.GetCandidateEntries>(),
        gh<_i506.EditCandidateEntry>(),
        gh<_i256.DiscardCandidateEntry>(),
        gh<_i664.ConfirmScanBatch>(),
        gh<_i377.CancelScan>(),
        gh<_i1011.SetBatchDefaultDirection>(),
        gh<_i237.TagBatchToOccasion>(),
        gh<_i20.GetPossibleDuplicateForCandidate>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.factory<_i622.ScanHistoryCubit>(
      () => _i622.ScanHistoryCubit(
        gh<_i331.GetScanHistory>(),
        gh<_i413.DeleteScan>(),
      ),
    );
    gh.factory<_i919.ScanDetailCubit>(
      () => _i919.ScanDetailCubit(
        gh<_i267.GetScanDetail>(),
        gh<_i413.DeleteScan>(),
      ),
    );
    gh.factory<_i427.ImagePrepCubit>(
      () => _i427.ImagePrepCubit(
        gh<_i235.ImagePreparationService>(),
        gh<_i856.StartScan>(),
        gh<_i350.RunOcrExtraction>(),
        gh<_i1011.SetBatchDefaultDirection>(),
        gh<_i377.CancelScan>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
