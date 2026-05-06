import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

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
    // Very slow drift — 18 s period keeps the animation virtually imperceptible
    // while still being "alive". A longer duration = fewer frame-budget
    // misses because Tween interpolation is cheaper at low velocities.
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read screen height ONCE here, outside AnimatedBuilder, so the
    // builder closure never triggers a layout-read on every tick.
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        // Static background colour — never repaints.
        const ColoredBox(color: AppColorsV2.bg, child: SizedBox.expand()),

        // Animated blobs isolated in their own RepaintBoundary so only
        // this layer is rasterised each frame, not the whole app.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                children: [
                  Positioned(
                    top: screenHeight * 0.05 + math.sin(t * math.pi) * 40,
                    right: -50 + math.cos(t * math.pi) * 30,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        // Opacity baked into the color constant — avoids an
                        // extra Opacity widget in the raster thread.
                        color: Color(0x2600C853), // primary ~15% opacity
                      ),
                    ),
                  ),
                  Positioned(
                    bottom:
                        screenHeight * 0.15 - math.cos(t * math.pi) * 40,
                    left: -80 + math.sin(t * math.pi) * 50,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.tealAccent.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Backdrop blur is a separate static pass — it only re-renders
        // when its *own* content changes, not every animation frame.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: const SizedBox.expand(),
        ),

        widget.child,
      ],
    );
  }
}