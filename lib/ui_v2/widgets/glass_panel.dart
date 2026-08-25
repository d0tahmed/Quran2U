import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/glass.dart';

/// Frosted surface for content cards.
///
/// PERF — read this before setting [blur].
///
/// This used to delegate unconditionally to [GlassSurface], i.e. to a real
/// `BackdropFilter`. That was wrong for what GlassPanel is actually used for.
/// Every call site is a card sitting INSIDE a scroll view — the Daily
/// Inspiration cards, the Settings "About" panel, the surah detail panel — and
/// a backdrop blur inside a scrollable re-runs a saveLayer plus a gaussian
/// pass on the raster thread for every frame of every scroll. Two of them on
/// one screen is enough to visibly drop frames on a mid-range phone.
///
/// It now defaults to [FrostedCard]: the same tint gradient, sheen and
/// specular rim, with no blur and no layer. On a dark canvas the difference is
/// almost invisible; the difference in frame time is not.
///
/// Set [blur] only for a surface that genuinely floats above moving content
/// and is not itself inside a scroll view.
///
/// New code should prefer [GlassSurface] (floating chrome) or [FrostedCard]
/// (anything in a list) directly.
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

  /// Opt in to a real backdrop blur. Off by default — see the class docs.
  /// Never set this on a widget that lives inside a scroll view.
  final bool blur;

  /// Set true when this panel's height animates. See [FrostedCard.animatedSize].
  final bool animatedSize;

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
    this.blur = false,
    this.animatedSize = false,
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

    if (blur) {
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

    return FrostedCard(
      borderRadius: borderRadius,
      padding: padding,
      tint: tint ?? AppColorsV2.surfaceLow,
      edgeColor: edge,
      edgeIntensity: edge == null ? 0.22 : 0.48,
      accent: accent,
      elevated: boxShadow != null && boxShadow!.isNotEmpty,
      animatedSize: animatedSize,
      onTap: onTap,
      child: child,
    );
  }
}
