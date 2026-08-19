import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

/// Sakina backdrop.
///
/// Three quiet layers under the app:
///  1. the obsidian base colour,
///  2. two very slow drifting glows (jade top-right, gold bottom-left),
///  3. a static, near-invisible eight-point-star lattice across the top —
///     the geometric signature of the design language.
///
/// Perf notes preserved from the previous implementation: the base colour
/// never repaints, the animated blobs live in their own RepaintBoundary,
/// and the blur is a single static pass.
class CalmLightBackground extends StatefulWidget {
  final Widget child;
  const CalmLightBackground({super.key, required this.child});

  @override
  State<CalmLightBackground> createState() => _CalmLightBackgroundState();
}

class _CalmLightBackgroundState extends State<CalmLightBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 24 s period — alive, never noticeable.
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 24))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        // 1 — static base. Never repaints.
        const ColoredBox(color: AppColorsV2.bg, child: SizedBox.expand()),

        // 2 — drifting glows, isolated.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                children: [
                  Positioned(
                    top: screenHeight * 0.02 + math.sin(t * math.pi) * 30,
                    right: -70 + math.cos(t * math.pi) * 24,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x1474C6A4), // jade ~8%
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.12 - math.cos(t * math.pi) * 30,
                    left: -90 + math.sin(t * math.pi) * 36,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x0FD8B36E), // gold ~6%
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Blur pass over the glows only — static.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: const SizedBox.expand(),
        ),

        // 3 — static geometric lattice, top third of the screen.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.34,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: const CustomPaint(
                  painter: _StarLatticePainter(),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),

        widget.child,
      ],
    );
  }
}

/// Sparse grid of tiny eight-point stars at ~3% ivory. Painted once.
class _StarLatticePainter extends CustomPainter {
  const _StarLatticePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 64.0;
    const starSize = 9.0;
    const painter = EightPointStarPainter(
      color: Color(0x08ECEFE9),
      strokeWidth: 0.9,
    );

    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final dx = c * spacing + (r.isOdd ? spacing / 2 : 0) - spacing / 2;
        final dy = r * spacing;
        canvas.save();
        canvas.translate(dx, dy);
        painter.paint(canvas, const Size.square(starSize));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
