import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_form_cubit.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_form_state.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_list_cubit.dart';
import 'package:daftary/features/currency/presentation/cubit/exchange_rate_list_state.dart';
import 'package:daftary/features/currency/presentation/cubit/primary_currency_cubit.dart';
import 'package:daftary/features/currency/presentation/cubit/primary_currency_state.dart';
import 'package:daftary/features/currency/presentation/pages/currency_settings_page.dart';
import 'package:daftary/features/currency/presentation/pages/exchange_rate_form_page.dart';
import 'package:daftary/features/currency/presentation/pages/exchange_rate_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPrimaryCubit extends MockCubit<PrimaryCurrencyState>
    implements PrimaryCurrencyCubit {}

class _MockListCubit extends MockCubit<ExchangeRateListState>
    implements ExchangeRateListCubit {}

class _MockFormCubit extends MockCubit<ExchangeRateFormState>
    implements ExchangeRateFormCubit {}

/// T050/T053 — the three currency screens, including the FR-012 forced-rate
/// prompt and an RTL/LTR × light/dark rendering pass.
void main() {
  setUpAll(() => registerFallbackValue(Currency.egp));

  Widget wrap(
    Widget home, {
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      locale: locale,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  group('CurrencySettingsView', () {
    late _MockPrimaryCubit cubit;

    setUp(() {
      cubit = _MockPrimaryCubit();
      when(() => cubit.changePrimary(any())).thenAnswer((_) async {});
      when(() => cubit.confirmSwitchWithRate(any())).thenAnswer((_) async {});
      when(() => cubit.cancelPendingSwitch()).thenReturn(null);
    });

    const ready = PrimaryCurrencyState(status: PrimaryCurrencyStatus.ready);

    testWidgets('shows the primary currency and changes it via the dialog', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ready);
      await tester.pumpWidget(
        wrap(
          BlocProvider<PrimaryCurrencyCubit>.value(
            value: cubit,
            child: const CurrencySettingsView(),
          ),
        ),
      );

      expect(find.text('Egyptian Pound (EGP)'), findsOneWidget);
      expect(find.text('Exchange rates'), findsOneWidget);

      await tester.tap(find.byKey(CurrencySettingsView.changeButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('primary_currency_option_USD')));
      await tester.pumpAndSettle();

      verify(() => cubit.changePrimary(Currency.usd)).called(1);
    });

    testWidgets('Change is disabled while a switch is in flight', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ready.copyWith(isSubmitting: true));
      await tester.pumpWidget(
        wrap(
          BlocProvider<PrimaryCurrencyCubit>.value(
            value: cubit,
            child: const CurrencySettingsView(),
          ),
        ),
      );

      final button = tester.widget<TextButton>(
        find.byKey(CurrencySettingsView.changeButtonKey),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a refused switch prompts for the rate, validates, then '
        'confirms (FR-012)', (tester) async {
      const pending = PrimaryCurrencyState(
        status: PrimaryCurrencyStatus.ready,
        pendingTarget: Currency.usd,
        rateRequiredFor: Currency.egp,
      );
      whenListen(
        cubit,
        Stream<PrimaryCurrencyState>.fromIterable([pending]),
        initialState: ready,
      );
      await tester.pumpWidget(
        wrap(
          BlocProvider<PrimaryCurrencyCubit>.value(
            value: cubit,
            child: const CurrencySettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exchange rate needed'), findsOneWidget);
      expect(find.textContaining('You have records in EGP'), findsOneWidget);

      await tester.tap(find.byKey(SwitchRateDialog.confirmKey));
      await tester.pump();
      expect(find.text('Enter a rate greater than zero'), findsOneWidget);
      verifyNever(() => cubit.confirmSwitchWithRate(any()));

      await tester.enterText(find.byKey(SwitchRateDialog.rateFieldKey), '0.02');
      await tester.tap(find.byKey(SwitchRateDialog.confirmKey));
      await tester.pumpAndSettle();

      verify(() => cubit.confirmSwitchWithRate('0.02')).called(1);
      expect(find.byType(SwitchRateDialog), findsNothing);
    });

    testWidgets('cancelling the rate prompt cancels the switch', (
      tester,
    ) async {
      whenListen(
        cubit,
        Stream<PrimaryCurrencyState>.fromIterable([
          const PrimaryCurrencyState(
            status: PrimaryCurrencyStatus.ready,
            pendingTarget: Currency.usd,
            rateRequiredFor: Currency.egp,
          ),
        ]),
        initialState: ready,
      );
      await tester.pumpWidget(
        wrap(
          BlocProvider<PrimaryCurrencyCubit>.value(
            value: cubit,
            child: const CurrencySettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verify(() => cubit.cancelPendingSwitch()).called(1);
    });
  });

  group('ExchangeRateListView', () {
    late _MockListCubit cubit;

    final loaded = ExchangeRateListState(
      status: ExchangeRateListStatus.ready,
      rates: [
        ExchangeRate(
          currency: Currency.usd,
          relativeTo: Currency.egp,
          rateMicros: 50250000,
          lastUpdatedAt: DateTime(2026, 9, 3),
        ),
      ],
    );

    setUp(() {
      cubit = _MockListCubit();
      when(() => cubit.remove(any())).thenAnswer((_) async {});
      when(() => cubit.subscribe()).thenAnswer((_) async {});
    });

    testWidgets('each rate reads "1 USD = 50.25 EGP" with its date, under '
        'the manual disclosure (FR-007)', (tester) async {
      when(() => cubit.state).thenReturn(loaded);
      await tester.pumpWidget(
        wrap(
          BlocProvider<ExchangeRateListCubit>.value(
            value: cubit,
            child: const ExchangeRateListView(),
          ),
        ),
      );

      expect(find.text('1 USD = 50.25 EGP'), findsOneWidget);
      expect(find.textContaining('Updated'), findsOneWidget);
      expect(find.byKey(ExchangeRateListView.disclosureKey), findsOneWidget);
      expect(find.byKey(ExchangeRateListView.addButtonKey), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      when(() => cubit.state).thenReturn(
        const ExchangeRateListState(status: ExchangeRateListStatus.ready),
      );
      await tester.pumpWidget(
        wrap(
          BlocProvider<ExchangeRateListCubit>.value(
            value: cubit,
            child: const ExchangeRateListView(),
          ),
        ),
      );

      expect(find.text('No exchange rates yet'), findsOneWidget);
      expect(find.byKey(ExchangeRateListView.disclosureKey), findsOneWidget);
    });

    testWidgets('remove asks for confirmation first', (tester) async {
      when(() => cubit.state).thenReturn(loaded);
      await tester.pumpWidget(
        wrap(
          BlocProvider<ExchangeRateListCubit>.value(
            value: cubit,
            child: const ExchangeRateListView(),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('exchange_rate_remove_USD')));
      await tester.pumpAndSettle();
      verifyNever(() => cubit.remove(any()));

      await tester.tap(find.widgetWithText(FilledButton, 'Remove rate'));
      await tester.pumpAndSettle();
      verify(() => cubit.remove('USD')).called(1);
    });
  });

  group('ExchangeRateFormView', () {
    late _MockFormCubit cubit;

    const form = ExchangeRateFormState(
      status: ExchangeRateFormStatus.ready,
      currency: Currency.usd,
      availableCurrencies: [Currency.usd, Currency.eur],
    );

    setUp(() {
      cubit = _MockFormCubit();
      when(() => cubit.save()).thenAnswer((_) async {});
      when(() => cubit.rateChanged(any())).thenReturn(null);
    });

    testWidgets('typing forwards the rate and Save calls save', (tester) async {
      when(() => cubit.state).thenReturn(form);
      await tester.pumpWidget(
        wrap(
          BlocProvider<ExchangeRateFormCubit>.value(
            value: cubit,
            child: const ExchangeRateFormView(),
          ),
        ),
      );

      expect(find.text('Value of 1 USD in EGP'), findsOneWidget);
      await tester.enterText(
        find.byKey(ExchangeRateFormView.rateFieldKey),
        '50.25',
      );
      verify(() => cubit.rateChanged('50.25')).called(1);

      await tester.tap(find.byKey(ExchangeRateFormView.saveButtonKey));
      verify(() => cubit.save()).called(1);
    });

    testWidgets('Save is disabled while submitting and the error shows', (
      tester,
    ) async {
      when(
        () => cubit.state,
      ).thenReturn(form.copyWith(isSubmitting: true, showRateError: true));
      await tester.pumpWidget(
        wrap(
          BlocProvider<ExchangeRateFormCubit>.value(
            value: cubit,
            child: const ExchangeRateFormView(),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(ExchangeRateFormView.saveButtonKey),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Enter a rate greater than zero'), findsOneWidget);
    });
  });

  group('RTL/LTR × light/dark rendering (T053)', () {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('${locale.languageCode} / ${mode.name}', (tester) async {
          final primary = _MockPrimaryCubit();
          when(() => primary.state).thenReturn(
            const PrimaryCurrencyState(status: PrimaryCurrencyStatus.ready),
          );
          await tester.pumpWidget(
            wrap(
              BlocProvider<PrimaryCurrencyCubit>.value(
                value: primary,
                child: const CurrencySettingsView(),
              ),
              locale: locale,
              themeMode: mode,
            ),
          );
          expect(tester.takeException(), isNull);
          final expected = locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr;
          expect(
            Directionality.of(
              tester.element(find.byKey(CurrencySettingsView.primaryTileKey)),
            ),
            expected,
          );

          final list = _MockListCubit();
          when(() => list.state).thenReturn(
            ExchangeRateListState(
              status: ExchangeRateListStatus.ready,
              rates: [
                ExchangeRate(
                  currency: Currency.usd,
                  relativeTo: Currency.egp,
                  rateMicros: 50250000,
                  lastUpdatedAt: DateTime(2026, 9, 3),
                ),
              ],
            ),
          );
          await tester.pumpWidget(
            wrap(
              BlocProvider<ExchangeRateListCubit>.value(
                value: list,
                child: const ExchangeRateListView(),
              ),
              locale: locale,
              themeMode: mode,
            ),
          );
          expect(tester.takeException(), isNull);
          // The pair stays LTR and Western-digit even under Arabic.
          expect(find.text('1 USD = 50.25 EGP'), findsOneWidget);
        });
      }
    }
  });
}
