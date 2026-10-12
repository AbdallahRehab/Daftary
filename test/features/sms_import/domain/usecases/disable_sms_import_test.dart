import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/usecases/clear_sms_import_data.dart';
import 'package:daftary/features/sms_import/domain/usecases/disable_sms_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pipeline_harness.dart';

/// A gateway that disables the feature after its first page, the way the
/// user turning it off mid-scan does.
class _DisablingGateway extends FakeSmsInboxGateway {
  _DisablingGateway({super.rows, required this.onFirstPage});

  final Future<void> Function() onFirstPage;
  var _fired = false;

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    final page = await super.queryInbox(
      senders: senders,
      afterDate: afterDate,
      afterId: afterId,
      limit: limit,
    );
    if (!_fired) {
      _fired = true;
      await onFirstPage();
    }
    return page;
  }
}

/// T141 — `DisableSmsImport` and `ClearSmsImportData` (FR-056, FR-078,
/// domain-interfaces §5.1, §5.4) over the real staging and settings
/// repositories on one in-memory database. Every value is synthetic.
void main() {
  late PipelineHarness h;
  late SmsImportSettingsRepositoryImpl settings;
  late DisableSmsImport disable;
  late ClearSmsImportData clear;

  const body = 'Purchase EGP 125.50 at Example Cafe';

  setUp(() async {
    h = PipelineHarness(now: DateTime(2026, 3, 4, 12));
    await h.open();
    settings = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(h.database),
      h.clock,
    );
    await settings.setEnabled(true);
    disable = DisableSmsImport(settings, h.repository);
    clear = ClearSmsImportData(h.repository, settings);
  });
  tearDown(() => h.close());

  /// Two pending items, one ignored (tombstoned), one mute, one mapping.
  Future<void> seedEverything() async {
    await h.stage(buildPendingImport(), raw: body);
    await h.stage(
      buildPendingImport(id: 'pending-2', fingerprint: 'fp-2'),
      raw: body,
    );
    await h.stage(
      buildPendingImport(id: 'pending-3', fingerprint: 'fp-3'),
      raw: body,
    );
    await h.repository.ignore({'pending-3'});
    await settings.muteSender('OTHERBANK');
    await h.database
        .into(h.database.smsMerchantCategoryMappings)
        .insert(
          h.database.smsMerchantCategoryMappings.map({
            'merchant_key': 'example cafe',
            'entry_type': 'expense',
            'category_id': 'seed_rent',
            'updated_at': 1,
          }),
        );
  }

  Future<SmsImportSettings> stored() async =>
      (await settings.getSettings()).getOrElse((f) => fail('$f'));

  group('DisableSmsImport', () {
    test('keeps pending items when not asked to delete them', () async {
      await seedEverything();

      expect(await disable(deletePending: false), const Right<Failure, int>(0));

      expect((await stored()).isEnabled, isFalse);
      final statuses = (await h.rows()).map((r) => r.status).toList()..sort();
      expect(statuses, ['ignored', 'pending', 'pending']);
    });

    test('deletes every pending item with no tombstone when asked; keeps '
        'mutes, mappings, tombstones and the Undo list', () async {
      await seedEverything();
      final tombstonesBefore = await h.database
          .select(h.database.smsImportTombstones)
          .get();

      expect(await disable(deletePending: true), const Right<Failure, int>(2));

      expect((await stored()).isEnabled, isFalse);
      final rows = await h.rows();
      expect(rows.map((r) => r.id), ['pending-3']); // the ignored one
      expect(
        await h.database.select(h.database.smsImportTombstones).get(),
        tombstonesBefore,
      );
      expect(
        await h.database.select(h.database.smsSenderMutes).get(),
        hasLength(1),
      );
      expect(
        await h.database.select(h.database.smsMerchantCategoryMappings).get(),
        hasLength(1),
      );
      expect(await h.savedRecords(), 0);
    });

    test('switches off first: when that fails, nothing is deleted', () async {
      final fakeSettings = FakeSmsImportSettingsRepository(
        settings: const SmsImportSettings(isEnabled: true),
      )..nextFailure = const CacheFailure('sms_settings_store_failed');
      await h.stage(buildPendingImport(), raw: body);

      final result = await DisableSmsImport(fakeSettings, h.repository)(
        deletePending: true,
      );

      expect(result.isLeft(), isTrue);
      expect(fakeSettings.settings.isEnabled, isTrue);
      expect(await h.rows(), hasLength(1));
    });

    test(
      'a running scan stops at its next page once disabled (FR-078)',
      () async {
        final rows = [
          for (var i = 1; i <= 205; i++)
            inboxRow(
              i,
              'NBE: Your card ending 4821 was charged EGP $i.00 at Example '
              'Market on 03/03/2026.',
              date: DateTime(2026, 3, 3, 9).add(Duration(minutes: i)),
            ),
        ];
        final gateway = _DisablingGateway(
          rows: rows,
          onFirstPage: () async {
            final disabled = await DisableSmsImport(h.settings, h.repository)(
              deletePending: false,
            );
            expect(disabled.isRight(), isTrue);
          },
        );
        final capability = GetSmsCapability(gateway);
        final summary =
            (await RunInboxScan(
                  capability,
                  GetSmsPermissionStatus(
                    capability,
                    FakeSmsPermissionService(
                      status: SmsPermissionStatus.granted,
                    ),
                  ),
                  h.settings,
                  h.parser,
                  gateway,
                  h.ingestion,
                  h.coordinator,
                  FakeLifecycle(),
                  h.clock,
                )(window: ScanWindow.days30, token: ScanCancellationToken()))
                .getOrElse((f) => fail('$f'));

        expect(gateway.calls, hasLength(1));
        expect(summary.cancelled, isTrue);
        // The page already read is kept (FR-007).
        expect(summary.createdPending, 200);
        expect(await h.savedRecords(), 0);
      },
    );
  });

  group('ClearSmsImportData', () {
    test('pending: deletes pending items only, no tombstone', () async {
      await seedEverything();
      expect(await clear(ClearScope.pending), const Right<Failure, Unit>(unit));
      expect((await h.rows()).map((r) => r.status), ['ignored']);
      expect(
        await h.database.select(h.database.smsImportTombstones).get(),
        hasLength(1),
      );
      expect((await stored()).isEnabled, isTrue);
    });

    test('learned mappings: clears them and nothing else', () async {
      await seedEverything();
      expect(
        await clear(ClearScope.learnedMappings),
        const Right<Failure, Unit>(unit),
      );
      expect(
        await h.database.select(h.database.smsMerchantCategoryMappings).get(),
        isEmpty,
      );
      expect(await h.rows(), hasLength(3));
      expect(
        await h.database.select(h.database.smsSenderMutes).get(),
        hasLength(1),
      );
    });

    test('muted senders: clears every mute and nothing else', () async {
      await seedEverything();
      await settings.muteSender('THIRDBANK');
      expect(
        await clear(ClearScope.mutedSenders),
        const Right<Failure, Unit>(unit),
      );
      expect(await h.database.select(h.database.smsSenderMutes).get(), isEmpty);
      expect(await h.rows(), hasLength(3));
      expect(
        await h.database.select(h.database.smsMerchantCategoryMappings).get(),
        hasLength(1),
      );
    });

    test('no scope ever clears tombstones', () async {
      await seedEverything();
      for (final scope in ClearScope.values) {
        await clear(scope);
      }
      expect(
        (await h.database.select(h.database.smsImportTombstones).get())
            .single
            .outcome,
        TombstoneOutcome.ignored.dbValue,
      );
    });
  });
}
