import 'package:daftary/features/startup/presentation/widgets/splash_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplashGeometry', () {
    test('toCanvas maps the notebook centre to the canvas centre', () {
      final Offset c = SplashGeometry.toCanvas(const Offset(517, 515));
      expect(c.dx, closeTo(SplashGeometry.extent / 2, 1e-9));
      expect(c.dy, closeTo(SplashGeometry.extent / 2, 1e-9));
    });

    test('contentBottom sits just below the landed coin', () {
      expect(SplashGeometry.contentBottom, inInclusiveRange(60, 90));
    });

    test('person origin stays inside the canvas and mirrors', () {
      for (final TextDirection d in TextDirection.values) {
        expect(
          SplashGeometry.personOrigin(d).dx.abs(),
          lessThanOrEqualTo(SplashGeometry.extent / 2),
        );
      }
      expect(SplashGeometry.personOrigin(TextDirection.ltr).dx, isNegative);
      expect(SplashGeometry.personOrigin(TextDirection.rtl).dx, isPositive);
    });
  });

  group('SplashMark', () {
    for (final TextDirection dir in TextDirection.values) {
      for (final double t in <double>[0, 0.5, 1]) {
        testWidgets('paints at t=$t in ${dir.name}', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: dir,
                child: Center(
                  child: SplashMark(intro: AlwaysStoppedAnimation<double>(t)),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(SplashMark)),
            const Size.square(SplashGeometry.extent),
          );
        });
      }
    }
  });
}
