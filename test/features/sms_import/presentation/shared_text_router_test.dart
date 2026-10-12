import 'dart:async';

import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:daftary/features/sms_import/presentation/routes.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_inbox.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fakes.dart';

class _MockImportPasted extends Mock implements ImportPastedText {}

const _secret = 'Purchase of EGP 125.50 at Example Cafe';

/// T097 — `SharedTextRouter`: waits for unlock, routes to the Paste
/// screen, puts the text only into the in-memory inbox (never the route,
/// URL or `extra`), and consumes each share once, cold and warm.
void main() {
  late FakeSharedTextSource source;
  late FakeLockStatus lock;
  late SharedTextInbox inbox;
  late SharedTextRouter sharedRouter;
  late List<GoRouterState> pasteVisits;
  late GoRouter router;

  setUp(() {
    source = FakeSharedTextSource();
    lock = FakeLockStatus();
    inbox = SharedTextInbox();
    sharedRouter = SharedTextRouter(
      ImportSharedText(source, lock, _MockImportPasted()),
      inbox,
    );
    pasteVisits = [];
  });
  tearDown(() async {
    await sharedRouter.dispose();
    unawaited(source.close());
    await lock.close();
    await inbox.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: BankMessagesRoutes.paste,
          builder: (_, state) {
            pasteVisits.add(state);
            return const Scaffold(body: Text('paste-route'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  void expectNoTextInRoute() {
    expect(pasteVisits, isNotEmpty);
    for (final state in pasteVisits) {
      expect(state.uri.toString(), BankMessagesRoutes.paste);
      expect(state.uri.toString(), isNot(contains('Cafe')));
      expect(state.extra, isNull);
      expect(state.uri.queryParameters, isEmpty);
    }
    expect(
      router.routeInformationProvider.value.uri.toString(),
      BankMessagesRoutes.paste,
    );
  }

  testWidgets('cold share: routes to Paste with the text only in the '
      'inbox', (tester) async {
    source.initial = const SharedText(text: _secret);
    await pumpApp(tester);
    await tester.runAsync(() => sharedRouter.start(router));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(find.text('paste-route'), findsOneWidget);
    expectNoTextInRoute();
    expect(inbox.take(), const SharedText(text: _secret));
    expect(inbox.take(), isNull);
    expect(source.initialReads, 1);
  });

  testWidgets('warm share while running routes after it arrives', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.runAsync(() => sharedRouter.start(router));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    source.share(_secret);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.text('paste-route'), findsOneWidget);
    expectNoTextInRoute();
    expect(inbox.take()!.text, _secret);
  });

  testWidgets('waits for unlock before routing or filling the inbox', (
    tester,
  ) async {
    lock.lock();
    source.initial = const SharedText(text: _secret);
    await pumpApp(tester);
    await tester.runAsync(() => sharedRouter.start(router));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(inbox.hasPending, isFalse);

    lock.unlock();
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(find.text('paste-route'), findsOneWidget);
    expect(inbox.hasPending, isTrue);
    expectNoTextInRoute();
  });

  testWidgets('start is idempotent: a share is routed once', (tester) async {
    source.initial = const SharedText(text: _secret);
    await pumpApp(tester);
    await tester.runAsync(() async {
      await sharedRouter.start(router);
      await sharedRouter.start(router);
    });
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
    expect(source.initialReads, 1);
    expect(pasteVisits, hasLength(1));
  });
}
