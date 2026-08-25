import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/glass.dart';

/// Sakina backdrop.
///
/// Three quiet layers under the app:
///  1. the obsidian base colour,
///  2. two very slow drifting glows (jade top-right, gold bottom-left),
///  3. a static, near-invisible eight-point-star lattice across the top —
///     the geometric signature of the design language.
///
/// PERF — WHY THERE IS NO BackdropFilter HERE ANY MORE
/// ---------------------------------------------------
/// The previous version painted two hard-edged circles and then softened them
/// with a full-screen `BackdropFilter(blur: 70)`. That is the most expensive
/// thing this app could possibly do: a screen-sized saveLayer plus a sigma-70
/// gaussian, re-run on the raster thread EVERY FRAME, because the drift
/// animation above it invalidated the layer 60 times a second. On a mid-range
/// phone that single widget was worth several milliseconds per frame — under
/// this backdrop sits every screen in the app, so it taxed all of them.
///
/// A RadialGradient that fades to transparent produces the same soft bloom
/// analytically, for the cost of one gradient fill. The blur is gone and the
/// look is unchanged.
///
/// The drift is now a `Transform.translate` rather than an animated `Positioned`,
/// so it is a paint-only change: no relayout, isolated inside a RepaintBoundary.
class CalmLightBackground extends StatefulWidget {
  final Widget child;
  const CalmLightBackground({super.key, required this.child});

  @override
  State<CalmLightBackground> createState() => _CalmLightBackgroundState();
}

class _CalmLightBackgroundState extends State<CalmLightBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 24 s period — alive, never noticeable.
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 24));

    // The one animation in the app that never stops, so it is also the one
    // that has to yield first. On a phone the perf governor has already judged
    // to be struggling, the drift is parked at a fixed position rather than
    // run: it is decoration with a twenty-four second period, and it should
    // not be competing for frames with the content.
    if (!GlassConfig.reduced) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // 1 — static base. Never repaints.
        const ColoredBox(color: AppColorsV2.bg, child: SizedBox.expand()),

        // 2 — drifting glows. Pre-softened gradients, no blur pass.
        //
        // The Positioned wrappers are OUTSIDE the AnimatedBuilder so the
        // layout is fixed; only the Transform rebuilds, and a transform is a
        // paint-only change. Nothing here relayouts on any frame.
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Stack(
                children: [
                  Positioned(
                    top: size.height * 0.02,
                    right: -110,
                    child: _Drift(
                      controller: _controller,
                      amplitude: const Offset(24, 30),
                      child: const _Glow(
                        size: 420,
                        color: AppColorsV2.primary,
                        peak: 0.16,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.10,
                    left: -130,
                    child: _Drift(
                      controller: _controller,
                      amplitude: const Offset(-36, 30),
                      phase: math.pi / 2,
                      child: const _Glow(
                        size: 440,
                        color: AppColorsV2.tertiary,
                        peak: 0.10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3 — static geometric lattice, top third of the screen.
        //
        // PERF: the top-to-bottom fade used to be a ShaderMask, which forces a
        // saveLayer. The painter now bakes the fade into each star's alpha, so
        // the whole lattice is one cached picture with no layer at all.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: size.height * 0.34,
          child: const IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _StarLatticePainter(),
                isComplex: true,
                willChange: false,
                size: Size.infinite,
              ),
            ),
          ),
        ),

        widget.child,
      ],
    );
  }
}

/// Nudges its child along a slow lissajous path. The child is passed through
/// AnimatedBuilder's `child` slot, so it is built exactly once for the life of
/// the app — only the transform is recomputed per frame.
class _Drift extends StatelessWidget {
  final Animation<double> controller;
  final Offset amplitude;
  final double phase;
  final Widget child;

  const _Drift({
    required this.controller,
    required this.amplitude,
    required this.child,
    this.phase = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      // A RepaintBoundary AROUND THE GLOW, under the Transform.
      //
      // There is already one around the whole drifting layer, and on its own
      // it is not enough. A boundary stops a repaint escaping to its parent;
      // it does nothing about the content inside it changing, and here the
      // content changes on every single frame — so both 440-pixel radial
      // gradients were re-rasterised sixty times a second, for the whole life
      // of the app, for an effect with a twenty-four second period that nobody
      // is meant to notice.
      //
      // With a boundary here the gradient is rasterised ONCE and cached as a
      // texture. Each frame then only moves that texture, which the compositor
      // does without touching a pixel of it. Same drift, and the raster thread
      // stops doing the work entirely.
      child: RepaintBoundary(child: child),
      builder: (context, built) {
        final t = controller.value * math.pi + phase;
        return Transform.translate(
          offset: Offset(math.cos(t) * amplitude.dx, math.sin(t) * amplitude.dy),
          child: built,
        );
      },
    );
  }
}

/// A soft circular bloom: radial gradient from [peak] alpha at the centre to
/// fully transparent at the rim. Visually identical to a blurred disc.
class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double peak;

  const _Glow({required this.size, required this.color, required this.peak});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: peak),
              color.withValues(alpha: peak * 0.55),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Sparse grid of tiny eight-point stars, fading out towards the bottom.
/// Painted once and cached.
class _StarLatticePainter extends CustomPainter {
  const _StarLatticePainter();

  static const double _spacing = 64.0;
  static const double _starSize = 9.0;
  static const double _baseAlpha = 0.032;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final cols = (size.width / _spacing).ceil() + 1;
    final rows = (size.height / _spacing).ceil() + 1;

    // One Paint, one Path pair, reused for every star: building 120 Path
    // objects per paint was pure garbage.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final star = _star;

    for (var r = 0; r < rows; r++) {
      final dy = r * _spacing;
      // Bake the top-to-bottom fade in, instead of a ShaderMask saveLayer.
      final fade = (1.0 - (dy / size.height)).clamp(0.0, 1.0);
      if (fade <= 0.01) break;
      paint.color = AppColorsV2.onSurface.withValues(alpha: _baseAlpha * fade);

      for (var c = 0; c < cols; c++) {
        final dx = c * _spacing + (r.isOdd ? _spacing / 2 : 0) - _spacing / 2;
        canvas.save();
        canvas.translate(dx, dy);
        canvas.drawPath(star, paint);
        canvas.restore();
      }
    }
  }

  /// Built once for the whole app, not once per paint.
  static final Path _star = _starPath(_starSize);

  static Path _starPath(double extent) {
    final path = Path();
    final c = Offset(extent / 2, extent / 2);
    final half = extent / 2 - 0.9;

    void square(double rotation) {
      for (var i = 0; i < 4; i++) {
        final a = rotation + i * math.pi / 2;
        final p = Offset(c.dx + half * math.cos(a), c.dy + half * math.sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
    }

    square(0);
    square(math.pi / 4);
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
