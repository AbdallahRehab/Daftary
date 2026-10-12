import 'dart:async';

import 'package:daftary/core/database/app_database.dart' hide isNotNull, isNull;
import 'package:daftary/core/design_system/app_button.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/features/app_lock/data/datasources/secure_app_lock_storage.dart';
import 'package:daftary/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:daftary/features/app_lock/domain/services/biometric_service.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/app_lock/presentation/cubit/lock_screen_cubit.dart';
import 'package:daftary/features/app_lock/presentation/pages/lock_screen_page.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_sender_mute.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_settings_repository.dart';
import 'package:daftary/features/sms_import/domain/services/app_lifecycle_state_source.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/services/sms_permission_service.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/presentation/pages/bank_messages_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/import_review_page.dart';
import 'package:daftary/features/sms_import/presentation/pages/paste_bank_message_page.dart';
import 'package:daftary/features/sms_import/presentation/routes.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_router.dart';
import 'package:daftary/features/sms_import/presentation/widgets/pending_import_card.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

/// 023 T158 — the bank-message import flows end to end against the real
/// app shell: real DI graph, real router, real `AppLockGate`, real Cubits,
/// use cases, parser, fingerprint hasher, AES-GCM vault, staging repository
/// and the real `SmsImportRepositoryImpl.confirm` write path. **Device
/// only, not CI**:
///
/// ```sh
/// fvm flutter test integration_test/sms_import_flows_test.dart -d <device>
/// ```
///
/// Only the OS-facing seams are replaced, so every case also runs on the
/// macOS desktop (where the real adapters are the `Unavailable*` ones):
///
/// - `SmsInboxGateway` → [_FakeInboxGateway] (a capability build's inbox
///   served from memory; no READ_SMS needed);
/// - `SmsPermissionService` → [_FakePermission] (counts prompts, so a test
///   can assert none happened);
/// - `SharedTextSource` → [_FakeShares] (cold `takeInitial` + warm stream,
///   exactly the port the Android `ShareTargetActivity` feeds);
/// - `AppLifecycleStateSource` → always resumed (the scan's foreground
///   check);
/// - `FlutterSecureStorage` → the package's in-memory test platform (the
///   SMS keys and the App Lock PIN never touch the real Keychain/Keystore);
/// - `AppDatabase` → an in-memory drift database per test;
/// - App Lock's clock, inactivity timers, biometrics and PIN hashing → the
///   same seams `app_lock_flows_test.dart` uses.
///
/// What this cannot cover (owner walkthrough, T160 / quickstart.md §2):
/// the real READ_SMS dialog, Android 15 restricted settings, the real
/// Messages-app share intent and the "no second MainActivity" check.
///
/// All SMS below are synthetic: invented merchants, no real card numbers,
/// phone numbers or references.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const correctPin = '1234';
  const uuid = Uuid();

  late _TestClock lockClock;
  late _ManualTimers timers;
  late _FakeInboxGateway gateway;
  late _FakePermission permission;
  late _FakeShares shares;
  AppDatabase? db;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    lockClock = _TestClock();
    timers = _ManualTimers();
    gateway = _FakeInboxGateway();
    permission = _FakePermission();
    shares = _FakeShares();
    db = null;
  });

  tearDown(() async {
    await getIt.reset();
    await db?.close();
    unawaited(shares.close());
  });

  String two(int v) => v.toString().padLeft(2, '0');

  /// `dd/MM/yyyy` of [daysAgo] days before today (the parser infers
  /// nothing here: the year is explicit).
  String smsDate(int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  DateTime localDay(int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return DateTime(d.year, d.month, d.day);
  }

  String purchase(String amount, {int daysAgo = 1}) =>
      'Purchase of EGP $amount at Example Cafe on ${smsDate(daysAgo)} 10:15 '
      'with card ****0000.';

  String nbePurchase(String amount, {int daysAgo = 1}) =>
      'NBE: Your card ending 4821 was charged EGP $amount at Example Market '
      'on ${smsDate(daysAgo)} at 14:30. Available balance EGP 3,200.00';

  /// App Lock's persisted state, written before the app boots.
  Future<void> configureAppLock() async {
    final repo = AppLockRepositoryImpl(
      SecureAppLockStorageImpl(const FlutterSecureStorage()),
      Pbkdf2PinHasher(iterations: 5),
      const EscalatingLockoutPolicy(),
      clock: lockClock.call,
      runPinWork: runPinWorkInline,
    );
    (await repo.setPin(correctPin)).getOrElse((f) => throw StateError('$f'));
    (await repo.enableAppLock()).getOrElse((f) => throw StateError('$f'));
    (await repo.setInactivityTimeout(
      InactivityTimeout.after1min,
    )).getOrElse((f) => throw StateError('$f'));
  }

  /// Registers the fakes over a fresh DI graph and an in-memory database,
  /// without pumping anything yet.
  Future<void> wireDependencies() async {
    await getIt.reset();
    await configureDependencies();
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    db = database;
    getIt
      ..unregister<AppDatabase>()
      ..registerSingleton<AppDatabase>(database)
      ..unregister<SmsInboxGateway>()
      ..registerSingleton<SmsInboxGateway>(gateway)
      ..unregister<SmsPermissionService>()
      ..registerSingleton<SmsPermissionService>(permission)
      ..unregister<SharedTextSource>()
      ..registerSingleton<SharedTextSource>(shares)
      ..unregister<AppLifecycleStateSource>()
      ..registerSingleton<AppLifecycleStateSource>(_AlwaysResumed())
      ..unregister<BiometricService>()
      ..registerSingleton<BiometricService>(_NoBiometrics())
      ..unregister<PinHasher>()
      ..registerLazySingleton<PinHasher>(() => Pbkdf2PinHasher(iterations: 5))
      ..unregister<AppLockRepository>()
      ..registerLazySingleton<AppLockRepository>(
        () => AppLockRepositoryImpl(
          getIt<SecureAppLockStorage>(),
          getIt<PinHasher>(),
          getIt<LockoutPolicy>(),
          clock: lockClock.call,
          runPinWork: runPinWorkInline,
        ),
      )
      ..unregister<AppLifecycleObserver>()
      ..registerLazySingleton<AppLifecycleObserver>(
        () => AppLifecycleObserver(
          getIt(),
          clock: lockClock.call,
          timerFactory: timers.create,
        ),
        dispose: (observer) => observer.dispose(),
      )
      ..unregister<LockScreenCubit>()
      ..registerFactory<LockScreenCubit>(
        () => LockScreenCubit(
          getIt(),
          getIt(),
          getIt(),
          getIt(),
          getIt(),
          getIt(),
          clock: lockClock.call,
        ),
      );
    // Opens the database (seeds the default categories).
    await database.select(database.financeCategories).get();
    await getIt<OnboardingRepository>().completeOnboarding();
  }

  /// Boots the app the way `main()` does and lands on [location].
  Future<void> bootApp(
    WidgetTester tester, {
    String location = BankMessagesRoutes.hub,
    bool startShareRouter = false,
    bool glass = false,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await getIt<AppStartupCubit>().start();
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    // The flows run with Liquid Glass OFF so the shell's bottom bar does
    // not overlap the page body; the glass-ON layout has its own case
    // below ("review actions are reachable ... with Liquid Glass ON").
    await getIt<SettingsCubit>().setGlassEnabled(glass);
    if (startShareRouter) {
      await getIt<SharedTextRouter>().start(appRouter);
    }
    appRouter.go(location);
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  /// Brings [finder] to the middle of the screen, first scrolling the
  /// screen's main vertical list until it is built: the review's action
  /// bar sits below the fold, inside a lazily built list.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
    }
    // Centered, not merely on screen: the shell's bottom bar would cover a
    // control scrolled only to the bottom edge.
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tap(tester, find.byKey(Key('pin_pad.digit.$digit')));
    }
    await tap(tester, find.byKey(const Key('pin_pad.submit')));
  }

  Future<List<PendingSmsImportRow>> pendingRows() =>
      db!.select(db!.pendingSmsImports).get();

  Future<List<FinanceEntry>> financeEntries() =>
      db!.select(db!.financeEntries).get();

  Future<int> transactionsCount() async =>
      (await db!.select(db!.moneyTransactions).get()).length;

  /// Stages [text] through the real paste pipeline, before the app boots.
  Future<void> stageByPaste(String text) async {
    final result = await getIt<ImportPastedText>()(
      text: text,
      source: SmsSource.paste,
    );
    final staged = result.getOrElse((f) => throw StateError('paste: $f'));
    expect(staged.newIds, hasLength(1));
  }

  Finder pendingCard() => find.byType(PendingImportCard);

  testWidgets('paste -> review -> Add: one SMS-sourced expense is saved only '
      'on the explicit Add, and the original text is purged '
      '(US4 + US1; quickstart §2 steps 5-6, 9)', (tester) async {
    await wireDependencies();
    await bootApp(tester, location: BankMessagesRoutes.paste);
    expect(find.byType(PasteBankMessagePage), findsOneWidget);

    final field = find.descendant(
      of: find.byKey(const ValueKey('paste_bank_message_field')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, purchase('125.50'));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('paste_bank_message_process')));

    // One recognized message opens its review directly (ui-contract §3.5).
    expect(find.byType(ImportReviewPage), findsOneWidget);
    // Staged, nothing saved.
    final staged = await pendingRows();
    expect(staged, hasLength(1));
    expect(staged.single.status, SmsImportStatus.pending.dbValue);
    expect(staged.single.origin, SmsSource.paste.dbValue);
    expect(staged.single.rawBlob, isNotNull);
    expect(await financeEntries(), isEmpty);

    final add = find.byKey(const ValueKey('import_review_add'));
    await reveal(tester, add);
    expect(add, findsOneWidget);
    expect(tester.widget<AppButton>(add).onPressed, isNotNull);
    expect(await financeEntries(), isEmpty, reason: 'opening review saves 0');

    await tap(tester, add);

    final entries = await financeEntries();
    expect(entries, hasLength(1));
    expect(entries.single.amountMinorUnits, 12550);
    expect(entries.single.currencyCode, 'EGP');
    expect(entries.single.type, 'expense');
    expect(entries.single.importSource, 'sms');
    expect(await transactionsCount(), 0);

    final decided = (await pendingRows()).single;
    expect(decided.status, SmsImportStatus.added.dbValue);
    expect(decided.rawBlob, isNull, reason: 'raw text purged on decision');
    expect(decided.savedRecordId, entries.single.id);
    // Back on the (now empty) hub.
    expect(find.byType(ImportReviewPage), findsNothing);
    expect(find.byType(BankMessagesPage), findsOneWidget);
    expect(pendingCard(), findsNothing);
  });

  testWidgets('capability build: scan with a fake inbox gateway, then Ignore '
      'one item: nothing is saved (US2 + US6; quickstart §2 steps 3, 11)', (
    tester,
  ) async {
    gateway
      ..capability = const SmsCapability(readSmsDeclared: true, isAndroid: true)
      ..rows.addAll([
        InboxSmsMessage(
          id: 1,
          address: 'NBE',
          date: DateTime.now().subtract(const Duration(days: 1)),
          body: nbePurchase('250.00'),
        ),
        // Not an allow-listed sender: never read.
        InboxSmsMessage(
          id: 2,
          address: 'EXAMPLESHOP',
          date: DateTime.now().subtract(const Duration(days: 1)),
          body: 'Your order of EGP 99.00 has shipped.',
        ),
      ]);
    permission.status = SmsPermissionStatus.granted;
    await wireDependencies();
    (await getIt<SmsImportSettingsRepository>().setEnabled(
      true,
    )).getOrElse((f) => throw StateError('$f'));

    await bootApp(tester, location: BankMessagesRoutes.hubScan);

    expect(gateway.queries, greaterThan(0));
    expect(find.byKey(const ValueKey('sms_scan_summary_card')), findsOneWidget);
    expect(pendingCard(), findsOneWidget);
    expect(await financeEntries(), isEmpty);
    expect(permission.requests, 0, reason: 'a granted scan never prompts');

    await tap(tester, pendingCard());
    expect(find.byType(ImportReviewPage), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('import_review_ignore')));

    final row = (await pendingRows()).single;
    expect(row.origin, SmsSource.inboxScan.dbValue);
    expect(row.status, SmsImportStatus.ignored.dbValue);
    expect(row.rawBlob, isNull);
    expect(await financeEntries(), isEmpty);
    expect(await transactionsCount(), 0);
    expect(pendingCard(), findsNothing);
  });

  testWidgets('duplicate warning: a manual expense with the same amount a day '
      'apart opens the side-by-side choice; "same" closes the item and saves '
      'nothing (US5; quickstart §2 step 10)', (tester) async {
    await wireDependencies();
    final category = (await db!.select(db!.financeCategories).get()).firstWhere(
      (c) => c.type == 'expense' && !c.isArchived,
    );
    (await getIt<FinanceRepository>().addEntry(
      idempotencyKey: uuid.v4(),
      categoryId: category.id,
      type: FinanceEntryType.expense,
      amount: const Money.egp(12550),
      date: localDay(2),
    )).getOrElse((f) => throw StateError('$f'));
    await stageByPaste(purchase('125.50'));

    await bootApp(tester);
    await tap(tester, pendingCard());
    expect(find.byType(ImportReviewPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('import_review_duplicate_banner')),
      findsOneWidget,
    );

    // Add does not save: it raises the side-by-side choice instead.
    await tap(tester, find.byKey(const ValueKey('import_review_add')));
    expect(
      find.byKey(const ValueKey('probable_duplicate_sheet')),
      findsOneWidget,
    );
    expect(await financeEntries(), hasLength(1));

    await tap(tester, find.byKey(const ValueKey('probable_duplicate_same')));

    final entries = await financeEntries();
    expect(entries, hasLength(1), reason: 'no record added or changed');
    expect(entries.single.importSource, isNull);
    final row = (await pendingRows()).single;
    expect(row.status, SmsImportStatus.duplicateClosed.dbValue);
    expect(row.rawBlob, isNull);
  });

  testWidgets('permission off: a revoked permission shows the banner, no Scan '
      'now, no prompt, and pending items stay reviewable (US8; quickstart §2 '
      'step 13)', (tester) async {
    gateway.capability = const SmsCapability(
      readSmsDeclared: true,
      isAndroid: true,
    );
    permission.status = SmsPermissionStatus.revoked;
    await wireDependencies();
    (await getIt<SmsImportSettingsRepository>().setEnabled(
      true,
    )).getOrElse((f) => throw StateError('$f'));
    await stageByPaste(purchase('80.00'));

    await bootApp(tester);

    expect(
      find.byKey(const ValueKey('sms_permission_banner_revoked')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bank_messages_scan_now')), findsNothing);
    expect(pendingCard(), findsOneWidget);

    await tap(tester, pendingCard());
    expect(find.byType(ImportReviewPage), findsOneWidget);
    final add = find.byKey(const ValueKey('import_review_add'));
    await reveal(tester, add);
    expect(tester.widget<AppButton>(add).onPressed, isNotNull);
    expect(permission.requests, 0, reason: 'never prompts on its own');
    expect(gateway.queries, 0, reason: 'no inbox read without permission');
  });

  testWidgets('feature off, permission never asked: the hub offers "Turn on" '
      'and no scan, and asks nothing (FR-010 / CHK036)', (tester) async {
    gateway.capability = const SmsCapability(
      readSmsDeclared: true,
      isAndroid: true,
    );
    permission.status = SmsPermissionStatus.denied;
    await wireDependencies();

    await bootApp(tester);

    expect(find.byKey(const ValueKey('bank_messages_turn_on')), findsOneWidget);
    expect(find.byKey(const ValueKey('bank_messages_scan_now')), findsNothing);
    expect(permission.requests, 0);
    expect(gateway.queries, 0);
  });

  testWidgets('review actions are reachable above the bottom bar with Liquid '
      'Glass ON, the default (ui-contract §3.4; AppScaffold contract: '
      'scrollables add AppGlassInsets)', (tester) async {
    await wireDependencies();
    await stageByPaste(purchase('60.00'));
    await bootApp(tester, glass: true);
    await tap(tester, pendingCard());
    expect(find.byType(ImportReviewPage), findsOneWidget);

    for (final key in ['import_review_add', 'import_review_ignore']) {
      final control = find.byKey(ValueKey(key));
      await reveal(tester, control);
      final hit = tester.hitTestOnBinding(tester.getCenter(control));
      final target = tester.renderObject(control);
      expect(
        hit.path.any((entry) => entry.target == target),
        isTrue,
        reason: '$key must not sit under the shell bottom bar',
      );
    }
  });

  testWidgets('share with App Lock, cold then warm: the shared text is staged '
      'and the Paste screen opens only after unlock (US4; FR-016a; '
      'quickstart §2 step 9)', (tester) async {
    shares.initial = SharedText(text: purchase('45.00'));
    await configureAppLock();
    await wireDependencies();
    await bootApp(tester, location: '/overview', startShareRouter: true);

    // Cold: locked, nothing parsed or routed behind the lock screen.
    expect(find.byType(LockScreenPage), findsOneWidget);
    expect(
      find.byType(PasteBankMessagePage, skipOffstage: false),
      findsNothing,
    );
    expect(find.byType(ImportReviewPage, skipOffstage: false), findsNothing);
    expect(await pendingRows(), isEmpty);

    await enterPin(tester, correctPin);
    expect(find.byType(LockScreenPage), findsNothing);
    // Routed to Paste, staged there, then on to the one item's review.
    expect(find.byType(ImportReviewPage), findsOneWidget);
    expect((await pendingRows()).single.origin, SmsSource.share.dbValue);

    // Warm: leave the app past the timeout, so it locks on return.
    appRouter.go('/overview');
    await tester.pumpAndSettle();
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    lockClock.advance(const Duration(seconds: 61));
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(LockScreenPage), findsOneWidget);

    // The warm share lands while the lock screen shows.
    shares.share(purchase('46.00'));
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.byType(LockScreenPage), findsOneWidget);
    // Not routed and not parsed behind the lock screen. (The People
    // branch keeps the earlier review offstage, so the check is the
    // router location, not the widget tree.)
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/overview');
    expect(await pendingRows(), hasLength(1), reason: 'held until unlock');

    await enterPin(tester, correctPin);
    expect(find.byType(LockScreenPage), findsNothing);
    expect(find.byType(ImportReviewPage), findsOneWidget);
    final rows = await pendingRows();
    expect(rows, hasLength(2));
    expect(rows.every((r) => r.origin == SmsSource.share.dbValue), isTrue);
    expect(await financeEntries(), isEmpty, reason: 'sharing never saves');
  });
}

// ---------------------------------------------------------------------------
// Fakes for the OS-facing ports.
// ---------------------------------------------------------------------------

/// A capability build's inbox served from memory, paged the way the
/// platform query is: allow-listed senders only, strictly after the
/// `(date, id)` cursor, ascending, at most `limit`.
class _FakeInboxGateway implements SmsInboxGateway {
  SmsCapability capability = SmsCapability.unavailable;
  final List<InboxSmsMessage> rows = [];
  int queries = 0;

  @override
  Future<SmsCapability> getCapability() async => capability;

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    queries++;
    if (!capability.available) {
      return const Left(SmsCapabilityUnavailableFailure());
    }
    final allowed = senders.map(canonicalSmsSenderId).toSet();
    final page =
        rows
            .where((m) => allowed.contains(canonicalSmsSenderId(m.address)))
            .where((m) {
              final cmp = m.date.compareTo(afterDate);
              if (cmp != 0) return cmp > 0;
              return afterId != null && m.id > afterId;
            })
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    return Right(page.take(limit).toList());
  }
}

/// A scripted READ_SMS permission that counts prompts.
class _FakePermission implements SmsPermissionService {
  SmsPermissionStatus status = SmsPermissionStatus.unavailable;
  int requests = 0;

  @override
  Future<Either<Failure, SmsPermissionStatus>> getStatus() async =>
      Right(status);

  @override
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  }) async {
    requests++;
    return Right(status);
  }

  @override
  Future<Either<Failure, Unit>> openAppInfo() async => const Right(unit);
}

/// The Android share port: one cold-start share and warm shares.
class _FakeShares implements SharedTextSource {
  SharedText? initial;
  final StreamController<SharedText> _controller = StreamController();

  void share(String text) => _controller.add(SharedText(text: text));

  @override
  Future<SharedText?> takeInitial() async {
    final value = initial;
    initial = null;
    return value;
  }

  @override
  Stream<SharedText> get stream => _controller.stream;

  Future<void> close() => _controller.close();
}

class _AlwaysResumed implements AppLifecycleStateSource {
  @override
  bool get isResumed => true;
}

class _NoBiometrics implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}

/// App Lock's wall clock, moved by hand.
class _TestClock {
  DateTime _now = DateTime(2026, 9, 24, 12);

  DateTime call() => _now;

  void advance(Duration duration) => _now = _now.add(duration);
}

/// App Lock's inactivity timers; never fired by these flows.
class _ManualTimers {
  Timer create(Duration duration, void Function() callback) => _IdleTimer();
}

class _IdleTimer implements Timer {
  bool _active = true;

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}
