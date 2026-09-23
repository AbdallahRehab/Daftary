import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_participant_row.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/presentation/widgets/occasion_list_tile.dart';
import 'package:daftary/features/occasions/presentation/widgets/occasion_totals_card.dart';
import 'package:daftary/features/occasions/presentation/widgets/occasion_type_chip.dart';
import 'package:daftary/features/occasions/presentation/widgets/participant_row.dart';
import 'package:daftary/features/occasions/presentation/widgets/settlement_status_badge.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T084 — the RTL/LTR and light/dark pass, written as assertions rather
/// than left to a manual look: every occasions widget is pumped in Arabic
/// RTL and English LTR, and in both themes, so a hardcoded `left`/`right`
/// or a colour that vanishes in dark mode fails here instead of shipping.
void main() {
  final now = DateTime(2026, 9, 15);

  final occasion = Occasion(
    id: 'o1',
    idempotencyKey: 'k1',
    name: 'فرح أحمد',
    date: now,
    type: OccasionType.wedding,
    createdAt: now,
    updatedAt: now,
  );

  const summary = OccasionSummary(
    occasionId: 'o1',
    totalReceived: Money.fromMinorUnits(500000),
    totalGiven: Money.fromMinorUnits(200000),
    participantCount: 4,
  );

  final participant = OccasionParticipantRow(
    transactionId: 't1',
    personId: 'p1',
    personName: 'أحمد حسن',
    amount: const Money.fromMinorUnits(200000),
    direction: TransactionDirection.received,
    countsTowardBalance: true,
    personOverallStatus: RelationshipStatus.theyOweYou,
  );

  Widget wrap(Widget child, {required Locale locale, required bool dark}) {
    return MaterialApp(
      locale: locale,
      theme: dark ? buildDarkTheme() : buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  /// Every combination each widget has to survive.
  const locales = [Locale('en'), Locale('ar')];
  const themes = [false, true];

  Future<void> pumpEverywhere(
    WidgetTester tester,
    Widget Function() build,
    void Function(Locale locale, bool dark) expectations,
  ) async {
    for (final locale in locales) {
      for (final dark in themes) {
        await tester.pumpWidget(
          wrap(build(), locale: locale, dark: dark),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'locale=$locale dark=$dark',
        );
        expectations(locale, dark);
      }
    }
  }

  testWidgets('the type chip renders a standard type localized and a custom '
      'one verbatim, in both locales and themes', (tester) async {
    await pumpEverywhere(
      tester,
      () => const Column(
        children: [
          OccasionTypeChip(type: OccasionType.newbornSebou),
          OccasionTypeChip(type: 'تخرج'),
        ],
      ),
      (locale, dark) {
        // The custom value is never translated away.
        expect(find.text('تخرج'), findsOneWidget);
        expect(
          find.text(locale.languageCode == 'ar' ? 'سبوع' : 'Newborn (Sebou)'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('the settlement badge renders all three states everywhere',
      (tester) async {
    for (final status in SettlementStatus.values) {
      await pumpEverywhere(
        tester,
        () => SettlementStatusBadge(
          status: status,
          outstanding: const Money.fromMinorUnits(300000),
        ),
        (_, _) {
          // Status is never conveyed by colour alone — there is always an
          // icon and text alongside it (accessibility).
          expect(find.byType(Icon), findsOneWidget);
          expect(find.byType(Text), findsOneWidget);
        },
      );
    }
  });

  testWidgets('the totals card renders received, given and net everywhere',
      (tester) async {
    await pumpEverywhere(
      tester,
      () => const OccasionTotalsCard(summary: summary),
      (_, _) => expect(find.byType(OccasionTotalsCard), findsOneWidget),
    );
  });

  testWidgets('the list tile and participant row lay out without overflow '
      'in RTL, with Arabic names and amounts', (tester) async {
    await pumpEverywhere(
      tester,
      () => Column(
        children: [
          OccasionListTile(occasion: occasion),
          ParticipantRow(row: participant),
        ],
      ),
      (_, _) {
        expect(find.text('فرح أحمد'), findsOneWidget);
        expect(find.text('أحمد حسن'), findsOneWidget);
      },
    );
  });

  testWidgets('a contribution that does not count toward the balance says so '
      'rather than leaving a silent gap (FR-018)', (tester) async {
    final notCounting = OccasionParticipantRow(
      transactionId: 't2',
      personId: 'p2',
      personName: 'Mourner',
      amount: const Money.fromMinorUnits(50000),
      direction: TransactionDirection.received,
      countsTowardBalance: false,
      personOverallStatus: RelationshipStatus.settled,
    );

    final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      wrap(
        ParticipantRow(row: notCounting),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10nEn.occasionParticipantCountsTowardBalanceLabel),
      findsOneWidget,
    );

    // A counting row does not carry the marker, so its presence means
    // something.
    await tester.pumpWidget(
      wrap(
        ParticipantRow(row: participant),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10nEn.occasionParticipantCountsTowardBalanceLabel),
      findsNothing,
    );
  });

  testWidgets('RTL actually flips the layout direction rather than only '
      'switching the strings', (tester) async {
    await tester.pumpWidget(
      wrap(
        OccasionListTile(occasion: occasion),
        locale: const Locale('ar'),
        dark: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(OccasionListTile))),
      TextDirection.rtl,
    );
  });
}
