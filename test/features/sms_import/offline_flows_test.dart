import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/platform/in_memory_review_lease_registry.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/ignore_import.dart';
import 'package:daftary/features/sms_import/domain/usecases/mute_sender.dart';
import 'package:daftary/features/sms_import/domain/usecases/show_original_message.dart';
import 'package:daftary/features/sms_import/domain/usecases/undo_ignore.dart';
import 'package:daftary/features/sms_import/domain/usecases/unmute_sender.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/test_daos.dart';
import 'helpers/pipeline_harness.dart';

/// Records and refuses every outbound socket and HTTP client: the device
/// has no connectivity at all.
final class _NoNetwork extends IOOverrides {
  final List<String> attempts = [];

  @override
  Future<Socket> socketConnect(
    host,
    int port, {
    sourceAddress,
    int sourcePort = 0,
    Duration? timeout,
  }) {
    attempts.add('socket');
    return Future.error(const SocketException('offline'));
  }

  @override
  Future<ConnectionTask<Socket>> socketStartConnect(
    host,
    int port, {
    sourceAddress,
    int sourcePort = 0,
  }) {
    attempts.add('socket');
    return Future.error(const SocketException('offline'));
  }
}

class _NoHttp extends HttpOverrides {
  _NoHttp(this.attempts);

  final List<String> attempts;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts.add('http');
    throw const SocketException('offline');
  }
}

// Synthetic messages (NBE profile and generic phrasing; invented names, no
// real card numbers, phone numbers or references).
const _nbePurchase =
    'NBE: Your card ending 4821 was charged EGP 250.00 at Example Market on '
    '05/03/2026 at 14:30. Available balance EGP 3,200.00';
const _nbeBill =
    'NBE: Bill payment of EGP 320.50 to Example Electricity was debited from '
    'your account ****4821 on 05/03/2026.';
const _cibIncoming =
    'CIB: Incoming transfer of EGP 1,500.00 to account ****2290 from Abdo '
    'Example on 05/03/2026.';
const _pasted =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with card '
    '****0000.';
const _shared =
    'Your account was debited with EGP 500.00 for a transfer to Mona Example '
    'on 05/03/2026. Ref: TRX12345';

/// The failures a flow would surface if it needed the network.
bool _isNetworkFailure(Failure f) =>
    f is NetworkFailure ||
    f is TimeoutFailure ||
    f is ServerFailure ||
    f is UnauthorizedFailure ||
    f is ForbiddenFailure;

/// T153 — offline-first (constitution, FR-100 area; plan "Offline"): every
/// bank-message flow — scan through the fake gateway, catch-up, paste,
/// share, review (open, Show original, duplicate check), Add, Ignore,
/// Undo, mute/unmute and expiry — succeeds with no connectivity at all,
/// and no flow surfaces a network error. Outbound sockets and HTTP
/// clients are refused and recorded for the whole run (the
/// no-connectivity fake). Real pipeline and database; only
/// platform edges are fakes. Every value is synthetic.
void main() {
  late PipelineHarness h;
  late _NoNetwork io;

  setUp(() async {
    h = PipelineHarness();
    await h.open();
    io = _NoNetwork();
  });
  tearDown(() => h.close());

  /// Runs [body] with every socket and HTTP client refused.
  Future<T> offline<T>(Future<T> Function() body) =>
      IOOverrides.runWithIOOverrides(
        () => HttpOverrides.runWithHttpOverrides(body, _NoHttp(io.attempts)),
        io,
      );

  T right<T>(Either<Failure, T> result, String flow) {
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      expect(
        _isNetworkFailure(failure),
        isFalse,
        reason: '$flow surfaced a network failure',
      );
      fail('$flow failed offline: $failure');
    }
    return result.getOrElse((_) => throw StateError('unreachable'));
  }

  ImportReviewCubit reviewCubit() {
    final people = PeopleRepositoryImpl(
      testPeopleDao(h.database),
      const FindPossibleDuplicatePerson(),
      h.database,
    );
    return ImportReviewCubit(
      GetPendingImport(h.repository),
      GetPendingImports(h.repository),
      h.add,
      h.checkDuplicates,
      ShowOriginalMessage(h.repository),
      InMemoryReviewLeaseRegistry(),
      GetCategories(CategoryRepositoryImpl(testFinanceDao(h.database))),
      people,
      CreatePerson(people),
      h.closeAsDuplicate,
    );
  }

  test('the guard sees an attempt (positive control)', () async {
    await offline(() async {
      await expectLater(
        Socket.connect('example.invalid', 443),
        throwsA(isA<SocketException>()),
      );
      expect(() => HttpClient(), throwsA(isA<SocketException>()));
    });
    expect(io.attempts, ['socket', 'http']);
  });

  test('scan, catch-up, paste and share stage items offline', () async {
    await offline(() async {
      final scan = await h.scan([
        inboxRow(1, _nbePurchase),
        inboxRow(2, _nbeBill),
        inboxRow(3, _cibIncoming, address: 'CIB'),
      ]);
      expect(scan.createdPending, 3);
      final catchUp = await h.catchUp([
        inboxRow(4, _nbeBill.replaceFirst('320.50', '410.00')),
      ]);
      expect(catchUp.createdPending, 1);
      expect((await h.pasteText(_pasted)).newIds, hasLength(1));
      expect((await h.shareText(_shared)).newIds, hasLength(1));
    });
    expect(await h.pending(), hasLength(6));
    expect(io.attempts, isEmpty);
  });

  test('review (open, Show original, duplicate check) and Add succeed '
      'offline', () async {
    await offline(() async {
      final id = (await h.pasteText(_pasted)).newIds.single;
      final cubit = reviewCubit();
      try {
        await cubit.load(id);
        expect(cubit.state.status, ImportReviewStatus.ready);
        expect(cubit.state.failure, isNull);
        await cubit.toggleOriginal();
        expect(cubit.state.original, isNotNull);
        await cubit.runDuplicateCheck();
        expect(cubit.state.failure, isNull);
        if (cubit.state.draft!.categoryId == null) {
          cubit.categorySelected('seed_groceries');
        }
        await cubit.add();
        expect(cubit.state.failure, isNull);
        expect(cubit.state.status, ImportReviewStatus.success);
      } finally {
        await cubit.close();
      }
    });
    expect(await h.savedRecords(), 1);
    expect(io.attempts, isEmpty);
  });

  test('Ignore, Undo, mute and unmute succeed offline', () async {
    final realSettings = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(h.database),
      h.clock,
    );
    await offline(() async {
      await h.scan([inboxRow(1, _nbePurchase), inboxRow(2, _nbeBill)]);
      final items = await h.pending();
      final bill = items.singleWhere((i) => i.kind == SmsKind.billPayment);

      right(await IgnoreImport(h.repository)(ids: {bill.id}), 'ignore');
      expect(await h.pending(), hasLength(1));
      final undo = right(await UndoIgnore(h.repository)(bill.id), 'undo');
      expect(undo.needsRescan, isTrue);
      expect(
        (await h.scan([inboxRow(2, _nbeBill)])).createdPending,
        1,
        reason: 'the undone message comes back on the next scan',
      );

      // The harness settings drive the scan's allow-list.
      right(await MuteSender(h.settings)('CIB'), 'mute');
      final muted = await h.scan([inboxRow(3, _cibIncoming, address: 'CIB')]);
      expect(muted.createdPending, 0);
      right(await UnmuteSender(h.settings)('CIB'), 'unmute');

      // And the real settings store, on the same database.
      right(await MuteSender(realSettings)('CIB'), 'mute (real store)');
      right(await UnmuteSender(realSettings)('CIB'), 'unmute (real store)');
    });
    expect(io.attempts, isEmpty);
  });

  test('expiry and purge run offline', () async {
    await offline(() async {
      await h.pasteText(_pasted);
      h.clock.advance(const Duration(days: 31));
      final expired = right(
        await ExpirePendingImports(h.repository, h.clock)(),
        'expire',
      );
      expect(expired, 1);
    });
    expect(await h.pending(), isEmpty);
    expect(io.attempts, isEmpty);
  });

  test('no file of the feature imports a network, sync-remote or '
      'connectivity library', () {
    final banned = RegExp(
      r'''import\s+['"](?:package:(?:http|dio|supabase_flutter|supabase|'''
      r'''connectivity_plus|web_socket_channel)/|[^'"]*core/sync/remote/|'''
      r'''[^'"]*connectivity_monitor\.dart)''',
    );
    final hits = <String>[];
    for (final file
        in Directory('lib/features/sms_import')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      if (banned.hasMatch(file.readAsStringSync())) hits.add(file.path);
    }
    expect(hits, isEmpty);
    // Positive control.
    expect(banned.hasMatch("import 'package:http/http.dart' as http;"), isTrue);
  });
}
