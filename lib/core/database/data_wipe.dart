import 'app_database.dart';
import 'finance_category_seed.dart';

/// The "delete all my data" capability (013 FR-016/FR-018), as an extension
/// on [AppDatabase] — the same cross-feature precedent as
/// `balance_queries.dart`, since no single feature owns every table.
extension DataWipe on AppDatabase {
  /// Deletes every row from every table in one drift transaction, then
  /// re-inserts the default finance categories, so the database ends up in
  /// exactly the state a fresh install has.
  ///
  /// All-or-nothing (FR-018): if any statement throws — a delete or the
  /// re-seed — drift rolls back every earlier statement in this call and
  /// rethrows, leaving every table exactly as it was.
  ///
  /// Every table in `@DriftDatabase(tables: [...])` MUST appear below;
  /// `test/core/database/data_wipe_test.dart` enumerates [allTables] and
  /// fails if one is left holding rows. Order is children before parents,
  /// so the wipe stays valid even with `PRAGMA foreign_keys = ON`.
  ///
  /// Re-seeding happens here rather than being left to `beforeOpen`
  /// because `beforeOpen` only runs when the database is opened: without
  /// it, a user returning to onboarding in the same session would find no
  /// categories until the next app launch — not a fresh install's state.
  ///
  /// Idempotent: on an already-wiped database it deletes nothing new and
  /// the seed set is replaced by an identical one.
  Future<void> deleteAllUserData() {
    return transaction(() async {
      // people / transactions / occasions / OCR
      await delete(transactionAuditEntries).go();
      await delete(candidateEntries).go();
      await delete(moneyTransactions).go();
      await delete(ocrScans).go();
      await delete(occasionAttachments).go();
      await delete(occasions).go();
      await delete(people).go();
      // finance / budgets
      await delete(budgetCategoryAllocations).go();
      await delete(budgets).go();
      await delete(financeEntries).go();
      await delete(financeCategories).go();
      // single-row preference tables
      await delete(appSettings).go();
      await delete(onboardingStatus).go();

      await seedDefaultFinanceCategories(this);
    });
  }

  /// Paths of every app-owned file the database references — occasion
  /// photo attachments and OCR scan source images — including soft-deleted
  /// rows, whose files are still on disk.
  ///
  /// Read *before* [deleteAllUserData] so the files can be removed once
  /// (and only once) the wipe has committed. `People.avatarPath` is
  /// deliberately excluded: no flow in the app writes an app-owned copy
  /// there, so the app cannot know it owns whatever file it points at.
  Future<Set<String>> userFilePaths() async {
    final attachments = await select(occasionAttachments).get();
    final scans = await select(ocrScans).get();
    return {
      for (final attachment in attachments) attachment.filePath,
      for (final scan in scans) scan.sourceImagePath,
    };
  }
}
