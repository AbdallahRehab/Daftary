import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/settings/data/datasources/settings_dao.dart';
import 'package:daftary/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepositoryImpl(SettingsDao(db));
  });

  tearDown(() => db.close());

  test('getLanguagePreference returns null when no row exists yet', () async {
    final result = await repository.getLanguagePreference();

    expect(result, const Right<Object, AppLanguage?>(null));
  });

  test(
    'persists then reads back a language preference (restart-persistence)',
    () async {
      final setResult = await repository.setLanguagePreference(
        AppLanguage.arabic,
      );
      expect(setResult.isRight(), isTrue);

      final getResult = await repository.getLanguagePreference();

      expect(getResult.isRight(), isTrue);
      expect(getResult.getOrElse((_) => null), AppLanguage.arabic);
    },
  );

  test(
    'overwrites a previously persisted preference on the next write',
    () async {
      await repository.setLanguagePreference(AppLanguage.arabic);
      await repository.setLanguagePreference(AppLanguage.english);

      final result = await repository.getLanguagePreference();

      expect(result.getOrElse((_) => null), AppLanguage.english);
    },
  );
}
