import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double blurSigma;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.tint,
    this.border,
    this.boxShadow,
    this.blurSigma = 14,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (tint ?? AppColorsV2.surface).withValues(alpha: 0.60),
              borderRadius: borderRadius,
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
              boxShadow: boxShadow ??
                  [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    )
                  ],
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

