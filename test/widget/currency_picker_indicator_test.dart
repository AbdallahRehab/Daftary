import 'package:daftary/core/design_system/currency_indicator_chip.dart';
import 'package:daftary/core/design_system/currency_picker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// 018 T018 — the shared CurrencyPicker and CurrencyIndicatorChip.
void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: buildLightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('CurrencyPicker', () {
    testWidgets('shows the selected currency with its English name and code '
        'and the localized label', (tester) async {
      await tester.pumpWidget(
        wrap(CurrencyPicker(value: Currency.egp, onChanged: (_) {})),
      );

      expect(find.byKey(CurrencyPicker.fieldKey), findsOneWidget);
      expect(find.text('Egyptian Pound (EGP)'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
    });

    testWidgets('lists every catalog currency by English name and code when '
        'opened', (tester) async {
      await tester.pumpWidget(
        wrap(CurrencyPicker(value: Currency.egp, onChanged: (_) {})),
      );
      await tester.tap(find.byKey(CurrencyPicker.fieldKey));
      await tester.pumpAndSettle();

      for (final currency in Currency.catalog) {
        expect(
          find.text('${currency.nameEn} (${currency.code})'),
          findsWidgets,
          reason: currency.code,
        );
      }
    });

    testWidgets('shows Arabic names (with the Latin code) under ar', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CurrencyPicker(value: Currency.usd, onChanged: (_) {}),
          locale: const Locale('ar'),
        ),
      );

      expect(find.text('دولار أمريكي (USD)'), findsOneWidget);
      expect(find.text('العملة'), findsOneWidget);
      expect(find.text('US Dollar (USD)'), findsNothing);

      await tester.tap(find.byKey(CurrencyPicker.fieldKey));
      await tester.pumpAndSettle();
      for (final currency in Currency.catalog) {
        expect(
          find.text('${currency.nameAr} (${currency.code})'),
          findsWidgets,
          reason: currency.code,
        );
      }
    });

    testWidgets('changing the selection calls onChanged with the chosen '
        'currency', (tester) async {
      final changes = <Currency>[];
      await tester.pumpWidget(
        wrap(CurrencyPicker(value: Currency.egp, onChanged: changes.add)),
      );

      await tester.tap(find.byKey(CurrencyPicker.fieldKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Euro (EUR)').last);
      await tester.pumpAndSettle();

      expect(changes, [Currency.eur]);
    });

    testWidgets('a disabled picker cannot be opened or changed', (
      tester,
    ) async {
      final changes = <Currency>[];
      await tester.pumpWidget(
        wrap(
          CurrencyPicker(
            value: Currency.egp,
            onChanged: changes.add,
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.byKey(CurrencyPicker.fieldKey));
      await tester.pumpAndSettle();

      expect(find.text('Euro (EUR)'), findsNothing);
      expect(changes, isEmpty);
    });
  });

  group('CurrencyIndicatorChip', () {
    testWidgets('renders the ISO code', (tester) async {
      await tester.pumpWidget(
        wrap(const CurrencyIndicatorChip(currency: Currency.usd)),
      );

      expect(find.byKey(const Key('currency_chip_USD')), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('renders the code LTR even under an RTL ambient '
        'Directionality', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: CurrencyIndicatorChip(currency: Currency.egp),
          ),
          locale: const Locale('ar'),
        ),
      );

      final codeText = find.text('EGP');
      expect(codeText, findsOneWidget);

      // The ambient direction around the chip really is RTL...
      final chipContext = tester.element(
        find.byKey(const Key('currency_chip_EGP')),
      );
      expect(Directionality.of(chipContext), TextDirection.rtl);

      // ...but the code itself is laid out LTR.
      expect(Directionality.of(tester.element(codeText)), TextDirection.ltr);
      final paragraph = tester.renderObject<RenderParagraph>(codeText);
      expect(paragraph.textDirection, TextDirection.ltr);
    });
  });
}
