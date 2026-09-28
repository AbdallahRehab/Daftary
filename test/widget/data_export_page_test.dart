import 'dart:async';
import 'dart:io';

import 'package:daftary/core/design_system/app_button.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/data_privacy/domain/entities/export_result.dart';
import 'package:daftary/features/data_privacy/domain/services/share_service.dart';
import 'package:daftary/features/data_privacy/domain/usecases/export_user_data.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/export_cubit.dart';
import 'package:daftary/features/data_privacy/presentation/cubit/export_state.dart';
import 'package:daftary/features/data_privacy/presentation/pages/data_export_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockExportUserData extends Mock implements ExportUserData {}

class MockShareService extends Mock implements ShareService {}

/// T021 / T051 (export part) — the export screen across idle, generating,
/// ready, and error, driven by a real `ExportCubit` over mocked
/// dependencies; plus localization, RTL, and dark-mode rendering.
void main() {
  late MockExportUserData exportUserData;
  late MockShareService shareService;
  late ExportCubit cubit;
  late AppLocalizations en;
  late AppLocalizations ar;

  final export = ExportResult(
    filePath: '/tmp/daftary-export.csv',
    generatedAt: DateTime(2026, 9, 24),
    sectionCounts: const {
      'People': 2,
      'Transactions': 3,
      'FinanceEntries': 1,
      'Categories': 1,
      'Settings': 0,
    },
  );

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() {
    exportUserData = MockExportUserData();
    shareService = MockShareService();
    cubit = ExportCubit(exportUserData, shareService);
  });

  tearDown(() => cubit.close());

  void stubShare(Either<Failure, Unit> result) {
    when(
      () => shareService.shareFile(
        filePath: any(named: 'filePath'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ExportCubit>.value(
          value: cubit,
          child: const DataExportView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> generateSuccessfully(WidgetTester tester) async {
    when(() => exportUserData()).thenAnswer((_) async => Right(export));
    await tester.tap(find.text(en.exportGenerateAction));
    await tester.pumpAndSettle();
  }

  testWidgets('idle explains the export and offers to generate it', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(en.exportTitle), findsOneWidget);
    expect(find.text(en.exportDescription), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, en.exportGenerateAction),
      findsOneWidget,
    );
    verifyZeroInteractions(exportUserData);
  });

  testWidgets('shows an in-progress indicator while generating (FR-009)', (
    tester,
  ) async {
    final pending = Completer<Either<Failure, ExportResult>>();
    when(() => exportUserData()).thenAnswer((_) => pending.future);
    await pump(tester);

    await tester.tap(find.text(en.exportGenerateAction));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(en.exportGenerating), findsOneWidget);
    expect(find.text(en.exportGenerateAction), findsNothing);

    pending.complete(Right(export));
    await tester.pumpAndSettle();
  });

  testWidgets('offers the share action once ready (FR-010)', (tester) async {
    stubShare(const Right(unit));
    await pump(tester);
    await generateSuccessfully(tester);

    expect(find.text(en.exportReadyTitle), findsOneWidget);
    expect(find.text(en.exportReadyMessage(7)), findsOneWidget);
    expect(find.text(en.exportRegenerateAction), findsOneWidget);

    await tester.tap(find.text(en.exportShareAction));
    await tester.pumpAndSettle();

    verify(
      () => shareService.shareFile(
        filePath: export.filePath,
        subject: en.exportTitle,
      ),
    ).called(1);
  });

  testWidgets('canceling the share sheet returns to ready, never an error', (
    tester,
  ) async {
    // SharePlusService maps a dismissed sheet to Right(unit).
    stubShare(const Right(unit));
    await pump(tester);
    await generateSuccessfully(tester);

    await tester.tap(find.text(en.exportShareAction));
    await tester.pumpAndSettle();

    expect(cubit.state.status, ExportStatus.ready);
    expect(find.text(en.exportReadyTitle), findsOneWidget);
    expect(find.text(en.exportShareAction), findsOneWidget);
    expect(find.text(en.exportShareError), findsNothing);
    expect(find.text(en.exportError), findsNothing);
  });

  testWidgets('a sheet that cannot open says so and keeps the file ready', (
    tester,
  ) async {
    stubShare(const Left(ShareFailure('no sheet')));
    await pump(tester);
    await generateSuccessfully(tester);

    await tester.tap(find.text(en.exportShareAction));
    await tester.pumpAndSettle();

    expect(find.text(en.exportShareError), findsOneWidget);
    expect(find.text(en.exportShareAction), findsOneWidget);
    expect(find.text(en.exportError), findsNothing);
  });

  testWidgets('a failed export shows the error with a working retry '
      '(FR-011)', (tester) async {
    when(
      () => exportUserData(),
    ).thenAnswer((_) async => const Left(CacheFailure('disk')));
    await pump(tester);

    await tester.tap(find.text(en.exportGenerateAction));
    await tester.pumpAndSettle();

    expect(find.text(en.exportError), findsOneWidget);
    expect(find.text(en.retry), findsOneWidget);

    when(() => exportUserData()).thenAnswer((_) async => Right(export));
    await tester.tap(find.text(en.retry));
    await tester.pumpAndSettle();

    expect(find.text(en.exportReadyTitle), findsOneWidget);
    verify(() => exportUserData()).called(2);
  });

  group('localization, direction, and theme (T051)', () {
    testWidgets('renders in Arabic, right-to-left', (tester) async {
      await pump(tester, locale: const Locale('ar'));

      expect(find.text(ar.exportTitle), findsOneWidget);
      expect(find.text(ar.exportDescription), findsOneWidget);
      expect(find.text(ar.exportGenerateAction), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(DataExportView))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ready state renders in Arabic too', (tester) async {
      when(() => exportUserData()).thenAnswer((_) async => Right(export));
      await pump(tester, locale: const Locale('ar'));

      await tester.tap(find.text(ar.exportGenerateAction));
      await tester.pumpAndSettle();

      expect(find.text(ar.exportReadyTitle), findsOneWidget);
      expect(find.text(ar.exportReadyMessage(7)), findsOneWidget);
      expect(find.text(ar.exportShareAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode using theme colors', (tester) async {
      final dark = buildDarkTheme();
      await pump(tester, theme: dark);

      expect(find.text(en.exportDescription), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(DataExportView))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    test('the page source has no hardcoded user-facing Text', () {
      final source = File(
        'lib/features/data_privacy/presentation/pages/data_export_page.dart',
      ).readAsStringSync();

      expect(source, isNot(matches(RegExp(r'''Text\(\s*['"]'''))));
    });
  });
}
