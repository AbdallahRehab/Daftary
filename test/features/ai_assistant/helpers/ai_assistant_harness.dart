import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/features/ai_assistant/data/datasources/ai_assistant_dao.dart';
import 'package:daftary/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:drift/native.dart';

import 'fake_secure_credential_store.dart';

/// A real in-memory database behind a real [AIAssistantRepositoryImpl],
/// with the keychain faked — so every settings/conversation rule under test
/// is exercised against real SQL and real transactions.
class AIAssistantHarness {
  AIAssistantHarness._(this.db, this.dao, this.store, this.repository);

  static AIAssistantHarness open() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final dao = AIAssistantDao(db);
    final store = FakeSecureCredentialStore();
    return AIAssistantHarness._(
      db,
      dao,
      store,
      AIAssistantRepositoryImpl(dao, store),
    );
  }

  final AppDatabase db;
  final AIAssistantDao dao;
  final FakeSecureCredentialStore store;
  final AIAssistantRepositoryImpl repository;

  Future<void> close() => db.close();
}

/// A well-formed (shape-valid) test key. Never a real credential.
const testApiKey = 'sk-test-0123456789abcdef';
const otherTestApiKey = 'sk-test-fedcba9876543210';
