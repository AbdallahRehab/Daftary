import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_navigation_bar.dart';
import 'package:daftary/core/design_system/glass/app_scaffold.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/ai_assistant/domain/entities/ai_message.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/ai_settings_state.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_cubit.dart';
import 'package:daftary/features/ai_assistant/presentation/cubit/chat_state.dart';
import 'package:daftary/features/ai_assistant/presentation/pages/ai_settings_page.dart';
import 'package:daftary/features/ai_assistant/presentation/pages/chat_page.dart';
import 'package:daftary/features/app_lock/presentation/cubit/app_lock_settings_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/app_lock_settings_state.dart';
import 'package:daftary/features/app_lock/presentation/cubit/pin_setup_cubit.dart';
import 'package:daftary/features/app_lock/presentation/cubit/pin_setup_state.dart';
import 'package:daftary/features/app_lock/presentation/pages/pin_setup_page.dart';
import 'package:daftary/features/app_lock/presentation/pages/security_settings_page.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_account_cubit.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/delete_account_state.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/export_cubit.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/export_state.dart';
import 'package:daftary/features/data_privacy/presentation/pages/data_export_page.dart';
import 'package:daftary/features/data_privacy/presentation/pages/delete_data_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../core/design_system/glass/glass_test_harness.dart';

class MockAISettingsCubit extends MockCubit<AISettingsState>
    implements AISettingsCubit {}

class MockChatCubit extends MockCubit<ChatState> implements ChatCubit {}

class MockAppLockSettingsCubit extends MockCubit<AppLockSettingsState>
    implements AppLockSettingsCubit {}

class MockPinSetupCubit extends MockCubit<PinSetupState>
    implements PinSetupCubit {}

class MockExportCubit extends MockCubit<ExportState> implements ExportCubit {}

class MockDeleteAccountCubit extends MockCubit<DeleteAccountState>
    implements DeleteAccountCubit {}

/// 020 rollout to the 013–015 screens (AI assistant, App Lock, data
/// privacy): each page's app bar turns to glass when the user enables it,
/// its content starts clear of the bar although the body runs beneath it
/// (research Decision 6), and with glass OFF the layout is unchanged
/// (SC-003). The Reports screen has the same checks in
/// `reports_page_test.dart`.
void main() {
  late AppLocalizations en;
  const screen = Size(800, 1600);

  final t0 = DateTime(2026, 9, 24, 10);
  AIMessage message(int i) => AIMessage(
    id: 'm$i',
    conversationId: 'c',
    sender: i.isEven ? MessageSender.user : MessageSender.assistant,
    content: 'Message $i',
    status: i.isEven ? MessageStatus.sent : MessageStatus.answered,
    createdAt: t0.add(Duration(minutes: i)),
  );

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    registerFallbackValue(PinSetupMode.initialSetup);
  });

  tearDown(() => getIt.reset());

  /// Pumps [home] as production does: [style] (when non-null) in an
  /// [AppGlassScope] above the navigator. [inShell] hosts it in the compact
  /// shell's frame — an [AppScaffold] with an [AppNavigationBar] — whose
  /// body runs beneath the glass bottom bar and reports it as padding.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    AppGlassStyle? style,
    bool inShell = false,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: style == null
            ? null
            : (context, child) => AppGlassScope(style: style, child: child!),
        home: inShell
            ? AppScaffold(
                body: home,
                bottomNavigationBar: AppNavigationBar(
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.people),
                      label: 'People',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              )
            : home,
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect appBar(WidgetTester tester) => tester.getRect(find.byType(AppBar));

  Finder glassInAppBar() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(GlassContainer),
  );

  /// The page frame checks shared by every screen: ON is glass with
  /// [first] clear of the bar; OFF has no glass and puts [first] exactly
  /// where it sits with no glass scope at all.
  void frameTests(
    String name,
    Widget Function() page,
    Finder Function() first, {
    void Function()? setUp,
  }) {
    group(name, () {
      testWidgets('ON: glass app bar, content starts below it', (tester) async {
        setUp?.call();
        await pump(tester, page(), style: onStyle);

        expect(glassInAppBar(), findsOneWidget);
        expect(
          tester.getRect(first()).top,
          greaterThanOrEqualTo(appBar(tester).bottom),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('OFF: no glass, layout unchanged', (tester) async {
        setUp?.call();
        await pump(tester, page());
        final plain = tester.getRect(first());

        setUp?.call();
        await pump(tester, page(), style: AppGlassStyle.off);
        expect(find.byType(GlassContainer), findsNothing);
        expect(tester.getRect(first()), plain);
      });
    });
  }

  frameTests('AI settings', () {
    final cubit = MockAISettingsCubit();
    when(
      () => cubit.state,
    ).thenReturn(const AISettingsState(status: AISettingsStatus.ready));
    return BlocProvider<AISettingsCubit>.value(
      value: cubit,
      child: const AISettingsView(),
    );
  }, () => find.text(en.aiSettingsIntroTitle));

  frameTests(
    'Security settings',
    () => const SecuritySettingsPage(),
    () => find.text(en.appLockSettingsSectionTitle),
    setUp: () {
      getIt.allowReassignment = true;
      getIt.registerFactory<AppLockSettingsCubit>(() {
        final cubit = MockAppLockSettingsCubit();
        when(() => cubit.state).thenReturn(
          const AppLockSettingsState(status: AppLockSettingsStatus.ready),
        );
        when(cubit.load).thenAnswer((_) async {});
        return cubit;
      });
    },
  );

  frameTests(
    'PIN setup',
    () => const PinSetupPage(mode: PinSetupMode.initialSetup),
    () => find.byKey(const Key('pin_setup.prompt')),
    setUp: () {
      getIt.allowReassignment = true;
      getIt.registerFactoryParam<PinSetupCubit, PinSetupMode, dynamic>((
        mode,
        _,
      ) {
        final cubit = MockPinSetupCubit();
        when(
          () => cubit.state,
        ).thenReturn(PinSetupState(mode: mode, step: PinSetupStep.enterNew));
        when(cubit.start).thenAnswer((_) async {});
        return cubit;
      });
    },
  );

  frameTests('Export my data', () {
    final cubit = MockExportCubit();
    when(() => cubit.state).thenReturn(const ExportState());
    return BlocProvider<ExportCubit>.value(
      value: cubit,
      child: const DataExportView(),
    );
  }, () => find.byIcon(Icons.file_download_outlined));

  frameTests(
    'Delete my data',
    () => const DeleteDataConfirmationPage(),
    () => find.text(en.deleteDataWarningTitle),
    setUp: () {
      getIt.allowReassignment = true;
      getIt.registerFactory<DeleteAccountCubit>(() {
        final cubit = MockDeleteAccountCubit();
        when(() => cubit.state).thenReturn(const DeleteAccountState());
        when(() => cubit.setExpectedPhrase(any())).thenReturn(null);
        return cubit;
      });
    },
  );

  group('Chat', () {
    late MockChatCubit cubit;

    Widget chat() =>
        BlocProvider<ChatCubit>.value(value: cubit, child: const ChatView());

    setUp(() => cubit = MockChatCubit());

    void conversation(int count, {bool hasMore = false}) =>
        when(() => cubit.state).thenReturn(
          ChatState(
            status: ChatStatus.ready,
            messages: [for (var i = 0; i < count; i++) message(i)],
            hasMore: hasMore,
          ),
        );

    Rect composer(WidgetTester tester) =>
        tester.getRect(find.byType(TextField));

    testWidgets('ON: the oldest end of a long conversation scrolls clear of '
        'the glass bar', (tester) async {
      conversation(40, hasMore: true);
      await pump(tester, chat(), style: onStyle, inShell: true);
      expect(glassInAppBar(), findsOneWidget);

      // Reversed list: dragging down reaches the oldest messages.
      await tester.fling(find.text('Message 39'), const Offset(0, 6000), 3000);
      await tester.pumpAndSettle();

      final loadEarlier = find.text(en.aiChatLoadEarlierAction);
      expect(
        tester.getRect(loadEarlier).top,
        greaterThanOrEqualTo(appBar(tester).bottom),
      );
    });

    testWidgets('ON, in the shell: the composer sits above the glass bottom '
        'bar and the newest message above the composer', (tester) async {
      conversation(3);
      await pump(tester, chat(), style: onStyle, inShell: true);

      final bar = tester.getRect(find.byType(NavigationBar));
      expect(composer(tester).bottom, lessThanOrEqualTo(bar.top));
      expect(
        tester.getRect(find.text('Message 2')).bottom,
        lessThanOrEqualTo(composer(tester).top),
      );
    });

    testWidgets('ON, keyboard open: the composer and the newest message stay '
        'above the keyboard', (tester) async {
      conversation(3);
      await pump(tester, chat(), style: onStyle, inShell: true);

      const keyboard = 700.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(
        composer(tester).bottom,
        lessThanOrEqualTo(screen.height - keyboard),
      );
      final newest = tester.getRect(find.text('Message 2'));
      expect(newest.bottom, lessThanOrEqualTo(composer(tester).top));
      expect(newest.top, greaterThanOrEqualTo(appBar(tester).bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('ON: the interrupted question of a disabled assistant starts '
        'below the bar', (tester) async {
      when(() => cubit.state).thenReturn(
        const ChatState(
          status: ChatStatus.disabled,
          interruptedQuestion: 'How much on food?',
        ),
      );
      await pump(tester, chat(), style: onStyle, inShell: true);

      expect(
        tester.getRect(find.text('How much on food?')).top,
        greaterThanOrEqualTo(appBar(tester).bottom),
      );
    });

    testWidgets('OFF: no glass, layout unchanged', (tester) async {
      conversation(3);
      await pump(tester, chat(), inShell: true);
      final plainComposer = composer(tester);
      final plainNewest = tester.getRect(find.text('Message 2'));

      await pump(tester, chat(), style: AppGlassStyle.off, inShell: true);
      expect(find.byType(GlassContainer), findsNothing);
      expect(composer(tester), plainComposer);
      expect(tester.getRect(find.text('Message 2')), plainNewest);
    });
  });
}
