import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/glass.dart';

/// Frosted surface.
///
/// The public API is unchanged — every existing call site keeps working — but
/// the implementation now delegates to [GlassSurface], so panels pick up the
/// specular rim, the tint gradient, the sheen and the backdrop saturation for
/// free, and honour [GlassConfig.blurEnabled] on weak devices.
///
/// New code should prefer [GlassSurface] (floating chrome) or [FrostedCard]
/// (anything that repeats in a list) directly.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double blurSigma;

  /// Optional accent wash — lights the top-left corner of the pane.
  final Color? accent;

  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.tint,
    this.border,
    this.boxShadow,
    this.blurSigma = 14,
    this.accent,
    this.onTap,
  });

  /// Maps the legacy `blurSigma` knob onto the tiered system so the two APIs
  /// cannot drift apart.
  GlassTier get _tier {
    if (blurSigma >= 20) return GlassTier.overlay;
    if (blurSigma >= 16) return GlassTier.sheet;
    if (blurSigma >= 11) return GlassTier.panel;
    return GlassTier.subtle;
  }

  @override
  Widget build(BuildContext context) {
    // A caller that passed a coloured border was asking for a coloured rim;
    // honour that as the specular colour instead of a flat 1px outline.
    final BorderSide? side = border?.top;
    final Color? edge = (side == null || side.style == BorderStyle.none)
        ? null
        : side.color.withValues(alpha: 1.0);

    return GlassSurface(
      tier: _tier,
      borderRadius: borderRadius,
      padding: padding,
      tint: tint ?? AppColorsV2.surface,
      edgeColor: edge,
      edgeIntensity: edge == null ? 0.28 : 0.55,
      shadow: boxShadow,
      accent: accent,
      onTap: onTap,
      child: child,
    );
  }
}
