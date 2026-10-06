import 'package:daftary/core/design_system/change_history/app_edited_marker.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(AppEditedMarker marker) => MaterialApp(
    home: Scaffold(body: Center(child: marker)),
  );

  testWidgets('without a tap handler it is plain text, not a button', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const AppEditedMarker(
          label: '(Edited)',
          semanticLabel: 'Edited',
          tooltip: 'Change history',
          style: AppTypography.bodyMuted,
        ),
      ),
    );

    expect(find.text('(Edited)'), findsOneWidget);
    expect(find.byKey(const ValueKey('edited-marker')), findsNothing);
  });

  testWidgets('with a tap handler it is a 48dp button labelled for screen '
      'readers and fires once per tap', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppEditedMarker(
          label: '(Edited)',
          semanticLabel: 'Edited',
          tooltip: 'Change history',
          style: AppTypography.bodyMuted,
          onTap: () => taps++,
        ),
      ),
    );

    final marker = find.byKey(const ValueKey('edited-marker'));
    final size = tester.getSize(marker);
    expect(size.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    expect(size.width, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    expect(
      tester.getSemantics(marker),
      isSemantics(label: 'Edited, Change history', isButton: true),
    );

    await tester.tap(marker);
    expect(taps, 1);
    handle.dispose();
  });
}
