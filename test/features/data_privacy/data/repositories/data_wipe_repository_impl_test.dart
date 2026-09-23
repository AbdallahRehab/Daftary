import 'dart:io';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/data_privacy/data/repositories/data_wipe_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// `DataWipeRepositoryImpl` against a real in-memory database: exceptions
/// become a typed [Failure], and the app-owned files a wiped row pointed at
/// are removed only after the wipe has committed.
void main() {
  late AppDatabase db;
  late Directory tempDir;
  late DataWipeRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('data_wipe_repo_test');
    repository = DataWipeRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<File> seedAttachment(String id) async {
    final file = File('${tempDir.path}/$id.jpg')..writeAsStringSync('x');
    await db
        .into(db.occasions)
        .insert(
          OccasionsCompanion.insert(
            id: 'o-$id',
            idempotencyKey: 'ok-$id',
            name: 'Wedding',
            date: 0,
            type: 'wedding',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
    await db
        .into(db.occasionAttachments)
        .insert(
          OccasionAttachmentsCompanion.insert(
            id: id,
            occasionId: 'o-$id',
            filePath: file.path,
            createdAt: 0,
          ),
        );
    return file;
  }

  Future<File> seedScan(String id) async {
    final file = File('${tempDir.path}/$id.jpg')..writeAsStringSync('x');
    await db
        .into(db.ocrScans)
        .insert(
          OcrScansCompanion.insert(
            id: id,
            idempotencyKey: 'sk-$id',
            sourceImagePath: file.path,
            status: 'confirmed',
            createdAt: 0,
          ),
        );
    return file;
  }

  test('wipes the database and deletes referenced attachment and scan '
      'files', () async {
    final photo = await seedAttachment('a1');
    final scan = await seedScan('s1');

    final result = await repository.deleteAllUserData();

    expect(result, const Right<Failure, Unit>(unit));
    expect(await db.select(db.occasionAttachments).get(), isEmpty);
    expect(await db.select(db.ocrScans).get(), isEmpty);
    expect(photo.existsSync(), isFalse);
    expect(scan.existsSync(), isFalse);
  });

  test('a file that is already missing does not fail the wipe', () async {
    final photo = await seedAttachment('a1');
    photo.deleteSync();

    final result = await repository.deleteAllUserData();

    expect(result, const Right<Failure, Unit>(unit));
    expect(await db.select(db.occasionAttachments).get(), isEmpty);
  });

  test('returns a CacheFailure and keeps every row and file when the wipe '
      'fails', () async {
    final photo = await seedAttachment('a1');
    await db.customStatement('''
      CREATE TRIGGER force_wipe_failure BEFORE DELETE ON occasions
      BEGIN SELECT RAISE(ABORT, 'forced'); END;
    ''');

    final result = await repository.deleteAllUserData();

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<CacheFailure>());
    expect(await db.select(db.occasionAttachments).get(), hasLength(1));
    expect(photo.existsSync(), isTrue);
  });
}
