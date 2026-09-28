import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasions_list_cubit.dart';
import 'package:daftary/features/occasions/presentation/cubit/occasions_list_state.dart';
import 'package:daftary/features/occasions/presentation/pages/occasions_list_page.dart';
import 'package:daftary/features/occasions/presentation/widgets/occasion_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/design_system/glass/glass_test_harness.dart';

class _MockOccasionsListCubit extends MockCubit<OccasionsListState>
    implements OccasionsListCubit {}

/// 020: the occasions list under Liquid Glass. With glass ON the body runs
/// beneath the glass bars, so the list must pad itself clear of them; with
/// glass OFF the layout is unchanged. Either way the last occasion scrolls
/// clear of the FAB and the bottom bar.
void main() {
  // Inside the app's shell: a status bar on top and, with glass ON, the
  // glass navigation bar the shell reports as bottom padding (with glass
  // OFF the shell's opaque bar consumes it).
  const statusBar = 47.0;
  const glassNavBar = 114.0;

  final occasions = [
    for (var i = 0; i < 30; i++)
      Occasion(
        id: 'o$i',
        idempotencyKey: 'k$i',
        name: 'Occasion $i',
        date: DateTime(2026, 1, 1),
        type: OccasionType.wedding,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
  ];

  setUp(() {
    final cubit = _MockOccasionsListCubit();
    when(() => cubit.state).thenReturn(
      OccasionsListState(
        status: OccasionsListStatus.success,
        occasions: occasions,
        hasAnyOccasion: true,
      ),
    );
    when(cubit.subscribe).thenAnswer((_) async {});
    getIt.registerFactory<OccasionsListCubit>(() => cubit);
  });

  tearDown(() => getIt.reset());

  Future<void> pumpPage(WidgetTester tester, {required bool glassOn}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppGlassScope(
          style: glassOn ? onStyle : AppGlassStyle.off,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(
                top: statusBar,
                bottom: glassOn ? glassNavBar : 0,
              ),
            ),
            child: child!,
          ),
        ),
        home: const OccasionsListPage(),
      ),
    );
    await tester.pump();
  }

  ListView list(WidgetTester tester) =>
      tester.widget<ListView>(find.byType(ListView));

  testWidgets('glass ON: the list takes the bottom glass inset on top of '
      'its FAB clearance', (tester) async {
    await pumpPage(tester, glassOn: true);

    expect(
      list(tester).padding,
      const EdgeInsets.only(bottom: 88 + glassNavBar),
    );
  });

  testWidgets('glass OFF: the list keeps only its FAB clearance', (
    tester,
  ) async {
    await pumpPage(tester, glassOn: false);

    expect(list(tester).padding, const EdgeInsets.only(bottom: 88));
  });

  for (final glassOn in [true, false]) {
    testWidgets('glass ${glassOn ? 'ON' : 'OFF'}: the first occasion starts '
        'below the app bar and the last scrolls clear of the FAB and the '
        'bottom bar', (tester) async {
      await pumpPage(tester, glassOn: glassOn);
      final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
      expect(
        tester.getRect(find.byType(OccasionListTile).first).top,
        greaterThanOrEqualTo(appBarBottom),
      );

      await tester.fling(find.byType(ListView), const Offset(0, -20000), 10000);
      await tester.pumpAndSettle();

      final last = tester.getRect(find.text('Occasion 29'));
      final fab = tester.getRect(find.byType(FloatingActionButton));
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(last.bottom, lessThanOrEqualTo(fab.top));
      expect(
        last.bottom,
        lessThanOrEqualTo(screenHeight - (glassOn ? glassNavBar : 0)),
      );
    });
  }
}
