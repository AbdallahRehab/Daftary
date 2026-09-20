// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

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
import '../../features/settings/domain/usecases/get_language_preference.dart'
    as _i1032;
import '../../features/settings/presentation/cubit/settings_cubit.dart'
    as _i792;
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
    gh.lazySingleton<_i933.DeviceLocaleProvider>(
      () => _i933.DeviceLocaleProviderImpl(),
    );
    gh.factory<_i735.PeopleDao>(() => _i735.PeopleDao(gh<_i982.AppDatabase>()));
    gh.factory<_i586.SettingsDao>(
      () => _i586.SettingsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i684.TransactionsDao>(
      () => _i684.TransactionsDao(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i646.PeopleRepository>(
      () => _i1029.PeopleRepositoryImpl(
        gh<_i735.PeopleDao>(),
        gh<_i769.FindPossibleDuplicatePerson>(),
        gh<_i982.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i956.TransactionsRepository>(
      () => _i373.TransactionsRepositoryImpl(
        gh<_i684.TransactionsDao>(),
        gh<_i982.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i674.SettingsRepository>(
      () => _i955.SettingsRepositoryImpl(gh<_i586.SettingsDao>()),
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
    gh.factory<_i305.OverviewCubit>(
      () => _i305.OverviewCubit(gh<_i941.GetOverview>()),
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
    gh.factory<_i1018.PersonListCubit>(
      () => _i1018.PersonListCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i750.GetPersonBalance>(),
        gh<_i221.ArchivePerson>(),
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
    gh.factory<_i62.ArchivedPeopleCubit>(
      () => _i62.ArchivedPeopleCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i49.RestorePerson>(),
      ),
    );
    gh.factory<_i90.ChangeLanguage>(
      () => _i90.ChangeLanguage(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i1032.GetLanguagePreference>(
      () => _i1032.GetLanguagePreference(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i992.PersonDetailCubit>(
      () => _i992.PersonDetailCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i750.GetPersonBalance>(),
        gh<_i610.GetPersonHistory>(),
        gh<_i645.DeleteTransaction>(),
      ),
    );
    gh.factoryParam<_i34.RepaymentFormCubit, String, dynamic>(
      (personId, _) => _i34.RepaymentFormCubit(
        gh<_i426.RecordRepayment>(),
        gh<_i999.EgpFormatter>(),
        personId,
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
    gh.lazySingleton<_i792.SettingsCubit>(
      () => _i792.SettingsCubit(
        gh<_i1032.GetLanguagePreference>(),
        gh<_i90.ChangeLanguage>(),
        gh<_i933.DeviceLocaleProvider>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
