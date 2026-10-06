import 'dart:async';

import 'package:daftary/core/design_system/change_history/app_change_history_sheet.dart';
import 'package:daftary/core/design_system/change_history/change_history_cubit.dart';
import 'package:daftary/core/design_system/change_history/change_history_row.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  final rows = [
    ChangeHistoryRow(label: 'Created', timestamp: DateTime(2026, 1, 1)),
    ChangeHistoryRow(
      label: 'Edited',
      timestamp: DateTime(2026, 2, 3),
      fields: const [
        ChangeHistoryField(label: 'Amount (before)', value: '1000.00 EGP'),
        ChangeHistoryField(label: 'Note', value: 'rent'),
      ],
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    Either<Failure, List<ChangeHistoryRow>>? result, {
    required Locale locale,
    required ThemeData theme,
  }) async {
    final controller =
        StreamController<Either<Failure, List<ChangeHistoryRow>>>();
    addTearDown(() {
      controller.close();
    });
    if (result != null) controller.add(result);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(
            create: (_) => ChangeHistoryCubit(controller.stream),
            child: const AppChangeHistorySheet(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final theme in {
      'light': buildLightTheme(),
      'dark': buildDarkTheme(),
    }.entries) {
      group('${locale.languageCode} / ${theme.key}', () {
        testWidgets('lists rows with title, values and a semantic label', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await pump(tester, Right(rows), locale: locale, theme: theme.value);
          final l10n = lookupAppLocalizations(locale);

          expect(find.text(l10n.changeHistoryTitle), findsOneWidget);
          expect(find.text('1000.00 EGP'), findsOneWidget);
          expect(find.text('rent'), findsOneWidget);
          expect(find.text('Edited'), findsOneWidget);
          expect(find.bySemanticsLabel(RegExp('Edited')), findsWidgets);
          for (final tile in tester.widgetList<ConstrainedBox>(
            find.byKey(const ValueKey('change-history-row')),
          )) {
            expect(tile.constraints.minHeight, greaterThanOrEqualTo(48));
          }
          expect(
            find.byKey(const ValueKey('change-history-row')),
            findsNWidgets(2),
          );
          handle.dispose();
        });

        testWidgets('loading state', (tester) async {
          await pump(tester, null, locale: locale, theme: theme.value);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });

        testWidgets('empty state', (tester) async {
          await pump(
            tester,
            const Right([]),
            locale: locale,
            theme: theme.value,
          );
          final l10n = lookupAppLocalizations(locale);
          expect(find.text(l10n.changeHistoryEmpty), findsOneWidget);
        });

        testWidgets('error state', (tester) async {
          await pump(
            tester,
            const Left(CacheFailure('x')),
            locale: locale,
            theme: theme.value,
          );
          final l10n = lookupAppLocalizations(locale);
          expect(find.text(l10n.changeHistoryLoadError), findsOneWidget);
        });
      });
    }
  }
}
