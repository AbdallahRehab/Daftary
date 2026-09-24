import 'package:daftary/core/security/app_lifecycle_observer.dart';
import 'package:daftary/core/security/app_lock_gate.dart';
import 'package:daftary/core/security/app_lock_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Enabled implements AppLockStatusProvider {
  @override
  Future<Duration?> lockTimeoutIfEnabled() async => const Duration(minutes: 1);
}

/// T023 — the MaterialApp.router builder gate hides routed content while
/// locked and keeps it mounted for after unlock.
void main() {
  testWidgets('covers the routed child while locked', (tester) async {
    final observer = AppLifecycleObserver(_Enabled());
    addTearDown(observer.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: TextField(key: Key('secret'))),
        builder: (context, child) => AppLockGate(
          observer: observer,
          lockScreenBuilder: (_) => const Scaffold(body: Text('LOCKED')),
          child: child!,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('secret')), 'balance');
    expect(find.text('LOCKED'), findsNothing);

    observer.lock();
    await tester.pump();
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('balance'), findsNothing); // offstage, not rendered
    expect(find.text('balance', skipOffstage: false), findsOneWidget);

    observer.unlock();
    await tester.pump();
    expect(find.text('LOCKED'), findsNothing);
    expect(find.text('balance'), findsOneWidget); // state survived
  });

  group('system back while locked (Android back button)', () {
    late AppLifecycleObserver observer;
    late GoRouter router;
    late List<String> platformCalls;

    setUp(() {
      observer = AppLifecycleObserver(_Enabled());
      router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HOME')),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, _) => const Scaffold(body: Text('DETAIL')),
              ),
            ],
          ),
        ],
      );
      platformCalls = [];
    });

    tearDown(() {
      observer.dispose();
      router.dispose();
    });

    Future<void> pumpApp(WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => AppLockGate(
            observer: observer,
            lockScreenBuilder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('FORGOT')),
                  ),
                ),
                child: const Text('LOCKED'),
              ),
            ),
            child: child!,
          ),
        ),
      );
      router.go('/detail');
      await tester.pumpAndSettle();
      expect(find.text('DETAIL'), findsOneWidget);
    }

    testWidgets('never pops the routed page underneath the lock screen; '
        'leaves the app instead', (tester) async {
      await pumpApp(tester);
      observer.lock();
      await tester.pumpAndSettle();

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('LOCKED'), findsOneWidget);
      expect(router.state.uri.path, '/detail');
      expect(find.text('DETAIL', skipOffstage: false), findsOneWidget);
      expect(platformCalls, contains('SystemNavigator.pop'));

      observer.unlock();
      await tester.pumpAndSettle();
      expect(find.text('DETAIL'), findsOneWidget);
    });

    testWidgets('pops a page pushed on the lock screen (e.g. Forgot PIN) '
        'first', (tester) async {
      await pumpApp(tester);
      observer.lock();
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOCKED'));
      await tester.pumpAndSettle();
      expect(find.text('FORGOT'), findsOneWidget);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('FORGOT'), findsNothing);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(router.state.uri.path, '/detail');
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('once unlocked, back reaches the router again', (tester) async {
      await pumpApp(tester);
      observer
        ..lock()
        ..unlock();
      await tester.pumpAndSettle();

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
