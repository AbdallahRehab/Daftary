import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';

/// Geometry of the splash mark: the launcher-icon notebook re-drawn in Dart.
///
/// Every value here mirrors `SPLASH` / `SPLASH_TRANSFORM` and `MARK` in
/// `assets/icon/build_icon.py`. The native launch image (`splash_mark.png`)
/// is rendered from that script with the same transform, so the first Flutter
/// frame lands pixel-for-pixel on top of the native launch screen. Change one
/// side and the hand-off visibly jumps — keep them in sync.
///
/// Raw values are in the icon's 1024-unit space; [toCanvas] maps them into
/// the [extent]-sized canvas (logical px). Motion constants are logical px.
abstract final class SplashGeometry {
  /// Canvas edge in logical px, equal to the native 288 dp/pt splash canvas.
  static const double extent = 288;

  /// Scale applied to the raw mark inside the 1024-unit space.
  static const double markScale = 0.9;

  /// Canvas px per raw icon unit (≈ 0.253125).
  static const double unit = markScale * extent / 1024;

  /// Centre of the notebook bounding box (x 300–734, y 240–790, including
  /// the page-edge offset). Deliberately not `MARK_CENTRED`'s
  /// translate(-24, -20): the splash centres the notebook alone, because the
  /// coin is not part of the native launch image.
  static const Offset rawCentre = Offset(517, 515);

  /// Centre of the canvas, in canvas px.
  static const Offset canvasCentre = Offset(extent / 2, extent / 2);

  /// Maps a raw `MARK` point to canvas px:
  /// `translate(512,512) scale(0.9) translate(-517,-515)` in the 1024 space,
  /// then `× extent / 1024`. Identical to `SPLASH_TRANSFORM` in
  /// `build_icon.py`.
  static Offset toCanvas(Offset raw) {
    final double k = extent / 1024;
    return Offset(
      ((raw.dx - rawCentre.dx) * markScale + 512) * k,
      ((raw.dy - rawCentre.dy) * markScale + 512) * k,
    );
  }

  /// [toCanvas] expressed relative to the canvas centre.
  static Offset fromCentre(Offset raw) => toCanvas(raw) - canvasCentre;

  /// Column-major matrix equivalent of [toCanvas], for transforming raw
  /// [Path]s built straight from the SVG path data.
  static final Float64List rawToCanvasMatrix = Float64List.fromList(<double>[
    unit, 0, 0, 0, //
    0, unit, 0, 0, //
    0, 0, 1, 0, //
    canvasCentre.dx - rawCentre.dx * unit,
    canvasCentre.dy - rawCentre.dy * unit, 0, 1, //
  ]);

  // --- Raw MARK constants (1024-unit icon space) ---------------------------

  /// Page-stack edge rect behind the page.
  static const Rect pageEdgeRaw = Rect.fromLTWH(318, 262, 416, 528);

  /// Front page rect.
  static const Rect pageRaw = Rect.fromLTWH(300, 240, 416, 528);

  /// Corner radius of the page and page edge.
  static const double cornerRadiusRaw = 44;

  /// Spine path data: `M344 240 H392 V768 H344 A44 44 0 0 1 300 724 V284
  /// A44 44 0 0 1 344 240 Z`.
  static const Rect spineBoundsRaw = Rect.fromLTRB(300, 240, 392, 768);

  /// Binding holes (x346, r9).
  static const double holeXRaw = 346;
  static const List<double> holeYsRaw = <double>[318, 426, 534, 642];
  static const double holeRadiusRaw = 9;

  /// Ledger lines as (y, startX, endX), stroke [ledgerStrokeRaw], round caps.
  static const List<(double, double, double)> ledgerLinesRaw =
      <(double, double, double)>[
        (350, 448, 640),
        (440, 448, 656),
        (530, 448, 600),
      ];
  static const double ledgerStrokeRaw = 26;

  /// Ribbon path data: `M602 240 H654 V312 L628 294 L602 312 Z`.
  static const Rect ribbonBoundsRaw = Rect.fromLTRB(602, 240, 654, 312);

  /// Coin centre, radius, rim radius and rim stroke.
  static const Offset coinCentreRaw = Offset(676, 676);
  static const double coinRadiusRaw = 124;
  static const double coinRimRadiusRaw = 98;
  static const double coinRimStrokeRaw = 10;

  // --- Canvas-px derived values ---------------------------------------------

  static const double coinRadius = coinRadiusRaw * unit;
  static const double coinRimRadius = coinRimRadiusRaw * unit;
  static const double coinRimStroke = coinRimStrokeRaw * unit;
  static const double ledgerStroke = ledgerStrokeRaw * unit;

  /// Lowest painted y relative to the canvas centre once the coin has landed
  /// (≈ 75.1 px): the larger of the page-edge bottom (y 790) and the coin's
  /// bottom (y 800) plus its offset shadow. The notebook's soft blur tail is
  /// intentionally ignored; it fades to nothing well before this line.
  /// The wordmark is laid out below this value.
  static double get contentBottom => math.max(
    (pageEdgeRaw.bottom - rawCentre.dy) * unit,
    (coinCentreRaw.dy + coinRadiusRaw - rawCentre.dy) * unit +
        coinShadowOffset.dy,
  );

  /// Where the person glyph (head centre) stands, relative to the canvas
  /// centre. It sits on the reading-start side, so it mirrors with [d]; the
  /// notebook and coin do not (they are the logo).
  static Offset personOrigin(TextDirection d) =>
      Offset(d == TextDirection.ltr ? -135 : 135, 20);

  /// Control point of the person → coin quadratic, mirrored with [d].
  static Offset connectionControl(TextDirection d) =>
      Offset(d == TextDirection.ltr ? -60 : 60, -110);

  // --- Motion constants (logical px unless noted) ---------------------------

  static const double personHeadRadius = 7;
  static const Size personShoulders = Size(22, 11);
  static const double personHeadGap = 3;
  static const double connectionStroke = 2;
  static const double connectionAlpha = 0.45;
  static const Offset coinShadowOffset = Offset(0, 3);
  static const double coinShadowAlpha = 0.25;
  static const double coinStartScale = 0.7;
  static const double coinSettleOvershoot = 0.06;

  /// Multiplied by the coin radius (176 / 124 in the icon).
  static const double coinGlyphScale = 1.42;
  static const double coinRimAlpha = 0.7;
  static const double wordmarkRise = 8;
  static const double holesAlpha = 0.55;
  static const double faintLineAlpha = 0.28;

  // --- Notebook shadow, from the SVG `#shadow` filter -----------------------

  static const Offset notebookShadowOffset = Offset(0, 22 * unit);

  /// A Gaussian σ equals SVG `stdDeviation`, so only the unit scale applies.
  static const double notebookShadowSigma = 26 * unit;
  static const double notebookShadowAlpha = 0.45;
}

/// Beats of the 900 ms splash intro, as fractions of one controller.
///
/// See research Decision 8: person → connection → coin → ledger record, then
/// the person and path fade so the final frame matches the launcher icon.
abstract final class SplashTimeline {
  static const Duration introDuration = Duration(milliseconds: 900);
  static const Duration exitDuration = Duration(milliseconds: 280);

  static const Interval person = Interval(
    0.08,
    0.30,
    curve: Curves.easeOutCubic,
  );
  static const Interval connection = Interval(
    0.12,
    0.45,
    curve: Curves.easeInOutCubic,
  );
  static const Interval coinTravel = Interval(
    0.30,
    0.72,
    curve: Curves.easeInOutCubic,
  );
  static const Interval coinSettle = Interval(
    0.72,
    0.84,
    curve: Curves.easeOutBack,
  );
  static const Interval ledgerWrite = Interval(
    0.60,
    0.86,
    curve: Curves.easeOutCubic,
  );
  static const Interval connectionFade = Interval(
    0.78,
    1.0,
    curve: Curves.easeOut,
  );
  static const Interval wordmark = Interval(
    0.55,
    1.0,
    curve: Curves.easeOutCubic,
  );
}

/// Paints the static notebook: exactly what the native `splash_mark.png`
/// shows (no coin, all ledger lines faint). It never repaints.
class SplashNotebookPainter extends CustomPainter {
  const SplashNotebookPainter();

  static final _NotebookGeometry _g = _NotebookGeometry();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // The widget is always extent-sized; scale defensively if it is not.
    canvas.scale(size.width / SplashGeometry.extent);
    canvas.drawPath(_g.stackShadow, _g.shadowPaint);
    canvas.drawRRect(_g.pageEdge, _g.pageEdgePaint);
    canvas.drawRRect(_g.page, _g.pagePaint);
    canvas.drawPath(_g.spine, _g.spinePaint);
    for (final Offset hole in _g.holes) {
      canvas.drawCircle(hole, _g.holeRadius, _g.holePaint);
    }
    for (final (Offset, Offset) line in _g.ledgerLines) {
      canvas.drawLine(line.$1, line.$2, _g.faintLinePaint);
    }
    canvas.drawPath(_g.ribbon, _g.ribbonPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SplashNotebookPainter oldDelegate) => false;
}

/// Static notebook geometry and paints, built once in canvas px.
class _NotebookGeometry {
  _NotebookGeometry() {
    final Radius r = Radius.circular(
      SplashGeometry.cornerRadiusRaw * SplashGeometry.unit,
    );
    pageEdge = RRect.fromRectAndRadius(_rect(SplashGeometry.pageEdgeRaw), r);
    page = RRect.fromRectAndRadius(_rect(SplashGeometry.pageRaw), r);

    stackShadow =
        (Path()
              ..addRRect(pageEdge)
              ..addRRect(page))
            .shift(SplashGeometry.notebookShadowOffset);

    spine =
        (Path()
              ..moveTo(344, 240)
              ..lineTo(392, 240)
              ..lineTo(392, 768)
              ..lineTo(344, 768)
              ..arcToPoint(
                const Offset(300, 724),
                radius: const Radius.circular(44),
              )
              ..lineTo(300, 284)
              ..arcToPoint(
                const Offset(344, 240),
                radius: const Radius.circular(44),
              )
              ..close())
            .transform(SplashGeometry.rawToCanvasMatrix);

    ribbon =
        (Path()
              ..moveTo(602, 240)
              ..lineTo(654, 240)
              ..lineTo(654, 312)
              ..lineTo(628, 294)
              ..lineTo(602, 312)
              ..close())
            .transform(SplashGeometry.rawToCanvasMatrix);

    holes = <Offset>[
      for (final double y in SplashGeometry.holeYsRaw)
        SplashGeometry.toCanvas(Offset(SplashGeometry.holeXRaw, y)),
    ];
    ledgerLines = <(Offset, Offset)>[
      for (final (double y, double x1, double x2)
          in SplashGeometry.ledgerLinesRaw)
        (
          SplashGeometry.toCanvas(Offset(x1, y)),
          SplashGeometry.toCanvas(Offset(x2, y)),
        ),
    ];

    final Rect pageRect = page.outerRect;
    final Rect spineRect = _rect(SplashGeometry.spineBoundsRaw);
    final Rect ribbonRect = _rect(SplashGeometry.ribbonBoundsRaw);

    shadowPaint = Paint()
      ..color = AppBrandColors.shadow.withValues(
        alpha: SplashGeometry.notebookShadowAlpha,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        SplashGeometry.notebookShadowSigma,
      );
    pageEdgePaint = Paint()..color = AppBrandColors.pageEdge;
    pagePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[AppBrandColors.page, AppBrandColors.pageShade],
      ).createShader(pageRect);
    spinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[AppBrandColors.spine, AppBrandColors.spineLight],
      ).createShader(spineRect);
    holePaint = Paint()
      ..color = AppBrandColors.page.withValues(
        alpha: SplashGeometry.holesAlpha,
      );
    faintLinePaint = Paint()
      ..color = AppBrandColors.field.withValues(
        alpha: SplashGeometry.faintLineAlpha,
      )
      ..strokeWidth = SplashGeometry.ledgerStroke
      ..strokeCap = StrokeCap.round;
    ribbonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[AppBrandColors.ribbon, AppBrandColors.ribbonDeep],
      ).createShader(ribbonRect);
  }

  static Rect _rect(Rect raw) => Rect.fromPoints(
    SplashGeometry.toCanvas(raw.topLeft),
    SplashGeometry.toCanvas(raw.bottomRight),
  );

  late final RRect pageEdge;
  late final RRect page;
  late final Path stackShadow;
  late final Path spine;
  late final Path ribbon;
  late final List<Offset> holes;
  late final List<(Offset, Offset)> ledgerLines;
  final double holeRadius = SplashGeometry.holeRadiusRaw * SplashGeometry.unit;

  late final Paint shadowPaint;
  late final Paint pageEdgePaint;
  late final Paint pagePaint;
  late final Paint spinePaint;
  late final Paint holePaint;
  late final Paint faintLinePaint;
  late final Paint ribbonPaint;
}

/// Paints what moves: the person, the connection path, the top ledger line
/// being written and the coin travelling to its landing spot.
///
/// Frame-0 invariant: at `t == 0` this paints nothing, so the first Flutter
/// frame is exactly the [SplashNotebookPainter] layer, which equals the
/// native launch image. Only the motion mirrors in RTL (person on the
/// reading-start side, line written right-to-left); the notebook and the
/// coin's landing spot are the logo and never mirror.
class SplashMotionPainter extends CustomPainter {
  SplashMotionPainter(this.t, this.dir)
    : _path = _connectionPaths[dir]!,
      super(repaint: t);

  final Animation<double> t;
  final TextDirection dir;

  final _ConnectionPath _path;

  static final Map<TextDirection, _ConnectionPath> _connectionPaths =
      <TextDirection, _ConnectionPath>{
        for (final TextDirection d in TextDirection.values)
          d: _ConnectionPath(d),
      };

  static final Path _personShape = () {
    const double r = SplashGeometry.personHeadRadius;
    const Size s = SplashGeometry.personShoulders;
    const double top = r + SplashGeometry.personHeadGap;
    return Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r))
      ..addArc(
        Rect.fromLTWH(-s.width / 2, top, s.width, s.height * 2),
        math.pi,
        math.pi,
      )
      ..close();
  }();

  static final Offset _coinCentre = SplashGeometry.fromCentre(
    SplashGeometry.coinCentreRaw,
  );

  static final (Offset, Offset) _ledgerLine = () {
    final (double y, double x1, double x2) = SplashGeometry.ledgerLinesRaw[0];
    return (
      SplashGeometry.fromCentre(Offset(x1, y)),
      SplashGeometry.fromCentre(Offset(x2, y)),
    );
  }();

  // Coin paints live in coin-local coordinates (centre at origin, full
  // radius) so moving and scaling it is a canvas transform, not a new shader.
  static final Paint _coinFill = Paint()
    ..shader =
        const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppBrandColors.coinLight,
            AppBrandColors.coin,
            AppBrandColors.coinDeep,
          ],
          stops: <double>[0, 0.6, 1],
        ).createShader(
          Rect.fromCircle(
            center: Offset.zero,
            radius: SplashGeometry.coinRadius,
          ),
        );
  static final Paint _coinShadow = Paint()
    ..color = AppBrandColors.coinShadow.withValues(
      alpha: SplashGeometry.coinShadowAlpha,
    );
  static final Paint _coinRim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = SplashGeometry.coinRimStroke
    ..color = AppBrandColors.coinRim.withValues(
      alpha: SplashGeometry.coinRimAlpha,
    );
  static final Paint _ledgerPaint = Paint()
    ..color = AppBrandColors.field
    ..strokeWidth = SplashGeometry.ledgerStroke
    ..strokeCap = StrokeCap.round;

  /// The coin's "د", laid out once; the platform Arabic font draws it, as in
  /// the icon.
  static final TextPainter _glyph = TextPainter(
    text: const TextSpan(
      text: 'د',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppBrandColors.coinInk,
        fontSize: SplashGeometry.coinRadius * SplashGeometry.coinGlyphScale,
        height: 1,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();

  // Opacity-varying paints: one per painter, only their colour changes.
  final Paint _personPaint = Paint()..color = AppBrandColors.onField;
  final Paint _connectionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = SplashGeometry.connectionStroke
    ..strokeCap = StrokeCap.round
    ..color = AppBrandColors.onField;

  @override
  void paint(Canvas canvas, Size size) {
    final double v = t.value;
    if (v <= 0) return; // Frame-0 invariant: the notebook layer alone.

    final double person = SplashTimeline.person.transform(v);
    final double connection = SplashTimeline.connection.transform(v);
    final double travel = SplashTimeline.coinTravel.transform(v);
    final double settle = SplashTimeline.coinSettle.transform(v);
    final double write = SplashTimeline.ledgerWrite.transform(v);
    final double linger = 1 - SplashTimeline.connectionFade.transform(v);

    canvas.save();
    canvas.scale(size.width / SplashGeometry.extent);
    canvas.translate(
      SplashGeometry.canvasCentre.dx,
      SplashGeometry.canvasCentre.dy,
    );

    // Connection path, under the person and coin.
    final double connectionAlpha = SplashGeometry.connectionAlpha * linger;
    if (connection > 0 && connectionAlpha > 0) {
      _connectionPaint.color = AppBrandColors.onField.withValues(
        alpha: connectionAlpha,
      );
      canvas.drawPath(
        _path.metric.extractPath(0, _path.metric.length * connection),
        _connectionPaint,
      );
    }

    // Person on the reading-start side.
    final double personAlpha = person * linger;
    if (personAlpha > 0) {
      _personPaint.color = AppBrandColors.onField.withValues(
        alpha: personAlpha.clamp(0.0, 1.0),
      );
      final Offset o = _path.personOrigin;
      final double s = ui.lerpDouble(0.8, 1, person)!;
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.scale(s);
      canvas.drawPath(_personShape, _personPaint);
      canvas.restore();
    }

    // Top ledger line, written in reading direction over the faint line.
    if (write > 0) {
      final (Offset left, Offset right) = _ledgerLine;
      final (Offset from, Offset to) = dir == TextDirection.ltr
          ? (left, right)
          : (right, left);
      canvas.drawLine(from, Offset.lerp(from, to, write)!, _ledgerPaint);
    }

    // Coin, travelling along the connection and settling on its spot.
    if (travel > 0) {
      final Offset at = travel >= 1
          ? _coinCentre
          : _path.metric
                .getTangentForOffset(_path.metric.length * travel)!
                .position;
      final double scale =
          ui.lerpDouble(SplashGeometry.coinStartScale, 1, travel)! *
          (1 + SplashGeometry.coinSettleOvershoot * math.sin(math.pi * settle));
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(scale);
      canvas.drawCircle(
        SplashGeometry.coinShadowOffset,
        SplashGeometry.coinRadius,
        _coinShadow,
      );
      canvas.drawCircle(Offset.zero, SplashGeometry.coinRadius, _coinFill);
      canvas.drawCircle(Offset.zero, SplashGeometry.coinRimRadius, _coinRim);
      _glyph.paint(canvas, Offset(-_glyph.width / 2, -_glyph.height / 2));
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SplashMotionPainter oldDelegate) =>
      dir != oldDelegate.dir || t != oldDelegate.t;
}

/// The person → coin quadratic for one reading direction, measured once.
class _ConnectionPath {
  _ConnectionPath(TextDirection d)
    : personOrigin = SplashGeometry.personOrigin(d) {
    final Offset c = SplashGeometry.connectionControl(d);
    final Offset end = SplashMotionPainter._coinCentre;
    final Path path = Path()
      ..moveTo(personOrigin.dx, personOrigin.dy)
      ..quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
    metric = path.computeMetrics().first;
  }

  final Offset personOrigin;
  late final ui.PathMetric metric;
}

/// The branded splash mark: the static notebook plus the intro motion.
///
/// Decorative only, so it is excluded from semantics; the wordmark next to
/// it carries the accessible name.
class SplashMark extends StatelessWidget {
  const SplashMark({super.key, required this.intro});

  /// The 0→1 intro controller; see [SplashTimeline].
  final Animation<double> intro;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: SplashGeometry.extent,
        child: Stack(
          children: <Widget>[
            const RepaintBoundary(
              child: CustomPaint(
                size: Size.square(SplashGeometry.extent),
                painter: SplashNotebookPainter(),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: const Size.square(SplashGeometry.extent),
                painter: SplashMotionPainter(intro, Directionality.of(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
