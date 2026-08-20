// lib/ui_v2/glass.dart
//
// Sakina glass system.
//
// WHY THIS FILE EXISTS
// --------------------
// BackdropFilter is the single most expensive widget in Flutter: each one
// forces a saveLayer plus a blur on the raster thread, and cost scales with
// the blurred area. Putting one in every card of a 114-row list will drop a
// mid-range phone to ~20fps. So this file separates two things that *look*
// almost identical but cost wildly different amounts:
//
//   GlassSurface  — real backdrop blur. For surfaces that genuinely float
//                   ABOVE content: the nav dock, sheets, dialogs, app bars,
//                   the mini player. Budget: a handful on screen at once.
//
//   FrostedCard   — no blur at all. A gradient tint plus a specular edge,
//                   which reads as glass on a dark canvas for roughly zero
//                   cost. For anything that repeats: list rows, tiles, result
//                   cards.
//
// RULE: never put a GlassSurface inside a scrolling list. If you want glass
// in a list, use FrostedCard.
//
// WHAT MAKES IT LOOK PREMIUM
// --------------------------
// Cheap glass is a flat white overlay with a uniform 1px border. Real glass
// has (a) a tint gradient, because light falls across it, (b) a specular
// edge that is bright on the top-left and nearly gone by the bottom-right,
// (c) a soft drop shadow so it sits above rather than in, and (d) slightly
// boosted saturation of whatever is behind it. All four are implemented here.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

/// How far a surface floats above the content behind it.
enum GlassTier {
  /// Top-level chrome: navigation dock, app bars. Strongest blur.
  overlay,

  /// Modal sheets and dialogs.
  sheet,

  /// Hero panels inside a page — the player card, a featured card.
  panel,

  /// Subtle lift. Use sparingly; prefer [FrostedCard] for repeated content.
  subtle,
}

extension GlassTierX on GlassTier {
  double get sigma {
    switch (this) {
      case GlassTier.overlay:
        return 24;
      case GlassTier.sheet:
        return 20;
      case GlassTier.panel:
        return 14;
      case GlassTier.subtle:
        return 8;
    }
  }

  /// Opacity of the tint sitting on top of the blur.
  double get tintOpacity {
    switch (this) {
      case GlassTier.overlay:
        return 0.55;
      case GlassTier.sheet:
        return 0.72;
      case GlassTier.panel:
        return 0.58;
      case GlassTier.subtle:
        return 0.45;
    }
  }

  double get elevation {
    switch (this) {
      case GlassTier.overlay:
        return 26;
      case GlassTier.sheet:
        return 40;
      case GlassTier.panel:
        return 28;
      case GlassTier.subtle:
        return 16;
    }
  }
}

/// Global switches — flip these to trade fidelity for frames.
class GlassConfig {
  GlassConfig._();

  /// Master switch. When false every GlassSurface renders as a FrostedCard,
  /// which is a useful escape hatch for low-end devices.
  static bool blurEnabled = true;

  /// Boost the saturation of content behind the glass, the way iOS does.
  /// Requires ImageFilter.compose (Flutter 3.13+). Set false if you ever
  /// need to target an older engine.
  static bool saturate = true;

  /// Multiplier applied to every tier's sigma. Lower it (0.6) on weak GPUs.
  static double sigmaScale = 1.0;

  /// Saturation matrix at s = 1.18, precomputed.
  static const List<double> _saturation = <double>[
    1.14166, -0.12870, -0.01296, 0, 0, //
    -0.03834, 1.05130, -0.01296, 0, 0, //
    -0.03834, -0.12870, 1.16704, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  static ui.ImageFilter filterFor(double sigma) {
    final s = (sigma * sigmaScale).clamp(0.1, 60.0);
    final blur = ui.ImageFilter.blur(sigmaX: s, sigmaY: s);
    if (!saturate) return blur;
    return ui.ImageFilter.compose(
      outer: const ColorFilter.matrix(_saturation),
      inner: blur,
    );
  }

  /// One call for "this phone is struggling".
  static void reduceEffects() {
    blurEnabled = false;
    saturate = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Specular edge + sheen
// ─────────────────────────────────────────────────────────────────────────────

/// Draws the rim light along a rounded rectangle: bright at the top-left,
/// fading to almost nothing at the bottom-right. This one detail is the
/// difference between "glass" and "grey box with a border".
class SpecularBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double width;

  /// Peak opacity of the rim at the top-left.
  final double intensity;

  /// Colour of the rim light — ivory by default, gold for accented surfaces.
  final Color color;

  const SpecularBorderPainter({
    required this.borderRadius,
    this.width = 1.0,
    this.intensity = 0.30,
    this.color = const Color(0xFFECEFE9),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect.deflate(width / 2));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        <Color>[
          color.withValues(alpha: intensity),
          color.withValues(alpha: intensity * 0.28),
          color.withValues(alpha: intensity * 0.10),
          color.withValues(alpha: intensity * 0.22),
        ],
        <double>[0.0, 0.35, 0.62, 1.0],
      );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant SpecularBorderPainter old) =>
      old.borderRadius != borderRadius ||
      old.width != width ||
      old.intensity != intensity ||
      old.color != color;
}

/// A soft diagonal sheen across the upper-left of a surface. Reads as a
/// reflection; costs one gradient fill.
class SheenPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final double opacity;

  const SheenPainter({required this.borderRadius, this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;

    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        Offset(rect.width * 0.75, rect.height * 0.85),
        <Color>[
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity * 0.35),
          Colors.transparent,
        ],
        <double>[0.0, 0.30, 0.75],
      );
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(covariant SheenPainter old) =>
      old.borderRadius != borderRadius || old.opacity != opacity;
}

/// Sheen behind the content, specular rim in front of it.
///
/// PERF: this wraps the content rather than sitting beside it in a Stack.
/// CustomPaint forwards its constraints to the child untouched and takes the
/// child's size, so a glass card lays out exactly like the plain Container it
/// replaced — and it costs three fewer render objects per card than the
/// Stack + Positioned.fill + IgnorePointer arrangement. With ~100 cards on a
/// scrolling screen that difference is measurable.
///
/// It also fixes a real layout bug: a Stack gives its non-positioned children
/// LOOSE constraints, so a Column inside one shrink-wraps its widest child and
/// pins itself to the top-left instead of filling the card.
class _GlassOverlays extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double sheenOpacity;
  final double edgeIntensity;
  final Color edgeColor;

  const _GlassOverlays({
    required this.child,
    required this.borderRadius,
    required this.sheenOpacity,
    required this.edgeIntensity,
    required this.edgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: sheenOpacity > 0
          ? SheenPainter(borderRadius: borderRadius, opacity: sheenOpacity)
          : null,
      foregroundPainter: edgeIntensity > 0
          ? SpecularBorderPainter(
              borderRadius: borderRadius,
              intensity: edgeIntensity,
              color: edgeColor,
            )
          : null,
      // Deliberately NOT isComplex: a gradient stroke around an rrect is
      // cheap to re-raster, and hinting ~100 list cards into the raster cache
      // would trade a few microseconds of paint for megabytes of texture.
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Press feedback
// ─────────────────────────────────────────────────────────────────────────────

/// Material ink is invisible under an opaque glass fill, so tappable glass
/// gets a physical press instead: a small scale-down with a fast release.
class GlassPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.978,
  });

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable> {
  bool _down = false;

  void _set(bool value) {
    if (!mounted || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real glass — blurs what is behind it
// ─────────────────────────────────────────────────────────────────────────────

class GlassSurface extends StatelessWidget {
  final Widget child;
  final GlassTier tier;

  /// Uniform corner radius. Ignored when [borderRadius] is supplied.
  final double radius;

  /// Full control over corners — use for sheets (top-only rounding).
  final BorderRadius? borderRadius;

  final EdgeInsets padding;

  /// Base colour of the tint. The gradient is derived from it.
  final Color tint;

  /// Rim-light colour. Pass gold for accented surfaces.
  final Color? edgeColor;

  /// 0 disables the rim light.
  final double edgeIntensity;

  /// Overrides the tier's shadow. Pass an empty list for no shadow.
  final List<BoxShadow>? shadow;

  /// Extra tint pulled towards this colour at the top-left, for "lit" panels.
  final Color? accent;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassSurface({
    super.key,
    required this.child,
    this.tier = GlassTier.panel,
    this.radius = 26,
    this.borderRadius,
    this.padding = const EdgeInsets.all(18),
    this.tint = AppColorsV2.surface,
    this.edgeColor,
    this.edgeIntensity = 0.30,
    this.shadow,
    this.accent,
    this.onTap,
    this.onLongPress,
  });

  BorderRadius get _br => borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    // Escape hatch for low-end devices: fall back to the zero-cost look.
    if (!GlassConfig.blurEnabled) {
      return FrostedCard(
        radius: radius,
        borderRadius: borderRadius,
        padding: padding,
        tint: tint,
        edgeColor: edgeColor,
        edgeIntensity: edgeIntensity,
        accent: accent,
        elevated: true,
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      );
    }

    final br = _br;
    final opacity = tier.tintOpacity;

    final colors = accent == null
        ? <Color>[
            tint.withValues(alpha: opacity * 0.82),
            tint.withValues(alpha: opacity),
            tint.withValues(alpha: (opacity * 1.12).clamp(0.0, 1.0)),
          ]
        : <Color>[
            Color.alphaBlend(accent!.withValues(alpha: 0.20), tint)
                .withValues(alpha: opacity * 0.92),
            tint.withValues(alpha: opacity),
            tint.withValues(alpha: (opacity * 1.12).clamp(0.0, 1.0)),
          ];

    Widget surface = RepaintBoundary(
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: GlassConfig.filterFor(tier.sigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: br,
              // Light falls across the pane: brighter top-left, denser
              // bottom-right. A flat fill is what makes glass look plastic.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
                stops: const <double>[0.0, 0.55, 1.0],
              ),
            ),
            child: _GlassOverlays(
              borderRadius: br,
              sheenOpacity: 0.05,
              edgeIntensity: edgeIntensity,
              edgeColor: edgeColor ?? AppColorsV2.onSurface,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    final shadows = shadow ??
        <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: tier.elevation,
            offset: Offset(0, tier.elevation * 0.42),
          ),
        ];

    if (shadows.isNotEmpty) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: br, boxShadow: shadows),
        child: surface,
      );
    }

    if (onTap == null && onLongPress == null) return surface;
    return GlassPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: surface,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted — the same language, no blur, safe to repeat
// ─────────────────────────────────────────────────────────────────────────────

class FrostedCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsets padding;
  final Color tint;
  final Color? edgeColor;
  final double edgeIntensity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Adds the drop shadow. Off by default: dozens of shadows in a list are
  /// their own performance problem.
  final bool elevated;

  /// Optional accent wash, for hero cards that should feel "lit".
  final Color? accent;

  /// Adds a coloured bloom under the card. Use on at most one card per screen.
  final Color? glow;

  const FrostedCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.borderRadius,
    this.padding = const EdgeInsets.all(18),
    this.tint = AppColorsV2.surfaceLow,
    this.edgeColor,
    this.edgeIntensity = 0.20,
    this.onTap,
    this.onLongPress,
    this.elevated = false,
    this.accent,
    this.glow,
  });

  BorderRadius get _br => borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    final br = _br;

    final colors = accent == null
        ? <Color>[
            Color.alphaBlend(Colors.white.withValues(alpha: 0.035), tint),
            tint,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.16), tint),
          ]
        : <Color>[
            Color.alphaBlend(accent!.withValues(alpha: 0.16), tint),
            Color.alphaBlend(accent!.withValues(alpha: 0.05), tint),
            tint,
          ];

    final shadows = <BoxShadow>[
      if (glow != null)
        BoxShadow(
          color: glow!.withValues(alpha: 0.16),
          blurRadius: 26,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
      if (elevated)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
    ];

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const <double>[0.0, 0.5, 1.0],
        ),
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: _GlassOverlays(
        borderRadius: br,
        sheenOpacity: 0.035,
        edgeIntensity: edgeIntensity,
        edgeColor: edgeColor ?? AppColorsV2.onSurface,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null && onLongPress == null) return card;
    return GlassPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small parts built from the same language
// ─────────────────────────────────────────────────────────────────────────────

/// Pill-shaped frosted chip. Zero blur, so it is safe in a horizontal list.
class GlassPill extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color accentColor;

  const GlassPill({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.accentColor = AppColorsV2.primary,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(999);

    return GlassPressable(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: br,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? <Color>[
                    Color.alphaBlend(
                        accentColor.withValues(alpha: 0.30),
                        AppColorsV2.surfaceHigh),
                    Color.alphaBlend(
                        accentColor.withValues(alpha: 0.14),
                        AppColorsV2.surfaceLow),
                  ]
                : <Color>[
                    Color.alphaBlend(Colors.white.withValues(alpha: 0.04),
                        AppColorsV2.surfaceLow),
                    AppColorsV2.surfaceLow,
                  ],
          ),
          border: Border.all(
            color: selected
                ? accentColor.withValues(alpha: 0.55)
                : AppColorsV2.hairline,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.20),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Round frosted icon button — for app-bar actions floating over content.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.color = AppColorsV2.onSurface,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = GlassPressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.07), AppColorsV2.surface),
              AppColorsV2.surfaceLow,
            ],
          ),
          border: Border.all(color: AppColorsV2.hairline),
        ),
        child: Icon(icon, size: size * 0.44, color: color),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Hairline that fades in from both ends — a divider that belongs to glass.
class GlassDivider extends StatelessWidget {
  final double height;
  final EdgeInsets margin;
  final Color color;

  const GlassDivider({
    super.key,
    this.height = 1,
    this.margin = EdgeInsets.zero,
    this.color = AppColorsV2.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.transparent,
            color.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// The grab handle every glass sheet starts with.
class GlassGrabber extends StatelessWidget {
  const GlassGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: AppColorsV2.onSurface.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// Rounding used by every modal sheet in the app.
const BorderRadius kGlassSheetRadius =
    BorderRadius.vertical(top: Radius.circular(28));
