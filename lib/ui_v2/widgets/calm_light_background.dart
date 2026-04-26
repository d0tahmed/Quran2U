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

class _CalmLightBackgroundState extends State<CalmLightBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColorsV2.bg),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.05 + (math.sin(_controller.value * math.pi) * 40),
                  right: -50 + (math.cos(_controller.value * math.pi) * 30),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColorsV2.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.15 - (math.cos(_controller.value * math.pi) * 40),
                  left: -80 + (math.sin(_controller.value * math.pi) * 50),
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
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
        widget.child,
      ],
    );
  }
}