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

  /// The liquid-glass extras: the thickness overlay and the inner bevel.
  ///
  /// Each is one extra gradient fill on an rrect — no saveLayer, no blur — so
  /// the cost is small and flat. It is a switch rather than a constant only so
  /// that [reduceEffects] has something to turn off on a phone that is
  /// genuinely struggling.
  static bool depth = true;

  /// True once [reduceEffects] has run, so the UI can say so honestly rather
  /// than leaving the user wondering why it looks different.
  static bool get reduced => !blurEnabled;

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
    depth = false;
    sigmaScale = 0.6;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paint cache
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies a gradient paint by everything that can change it.
@immutable
class _PaintKey {
  final int kind;
  final double w;
  final double h;
  final int a;
  final int b;
  final int c;
  final double d;

  const _PaintKey(this.kind, this.w, this.h, this.a, this.b, this.c, this.d);

  @override
  bool operator ==(Object other) =>
      other is _PaintKey &&
      other.kind == kind &&
      other.w == w &&
      other.h == h &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d;

  @override
  int get hashCode => Object.hash(kind, w, h, a, b, c, d);
}

/// A small LRU of ready-built gradient [Paint]s.
///
/// Every glass surface needs a shader whose stops are relative to its own
/// size, so a naive implementation builds one Gradient and one Paint per card
/// per paint. On a screen of a hundred identical rows that is a hundred native
/// shader objects created during the first fling — which is exactly when the
/// frame budget is tightest. Cards of the same size and style share one entry
/// here instead.
///
/// Bounded, because a cache that only grows is a leak with better manners.
class _PaintCache {
  _PaintCache._();

  static const int _cap = 96;
  static final Map<_PaintKey, Paint> _entries = <_PaintKey, Paint>{};

  static Paint of(_PaintKey key, Paint Function() build) {
    // Dart maps keep insertion order, so remove-then-reinsert promotes an
    // entry to newest and `keys.first` is always the least recently used.
    final hit = _entries.remove(key);
    if (hit != null) {
      _entries[key] = hit;
      return hit;
    }
    final made = build();
    _entries[key] = made;
    if (_entries.length > _cap) _entries.remove(_entries.keys.first);
    return made;
  }

  /// Sizes change wholesale on rotation; the old entries can never hit again.
  static void clear() => _entries.clear();
}

/// Drops every cached shader.
///
/// Call this when something global changed the way glass should be drawn —
/// the device rotated (every size-keyed entry is now stale) or the perf
/// governor turned effects down (every entry was built for settings that no
/// longer apply). Cheap: the next paint rebuilds only what is on screen.
class GlassRepaint {
  GlassRepaint._();
  static void invalidate() => _PaintCache.clear();
}

/// Rounds a dimension so that sub-pixel jitter during an animation does not
/// miss the cache on every single frame.
double _q(double v) => (v * 2).roundToDouble() / 2;

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

  /// The bottom-right glint is warmed towards this, not left ivory.
  ///
  /// Real glass disperses: the lit edge is cool, the far edge picks up the
  /// warmth of whatever it is sitting on. Rendering both ends of the rim in
  /// the same colour is the single most common reason a "glass" card reads as
  /// a grey box with a white outline.
  static const Color _warm = AppColorsV2.tertiary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect.deflate(width / 2));

    final paint = _PaintCache.of(
      _PaintKey(1, _q(size.width), _q(size.height), color.toARGB32(),
          (intensity * 1000).round(), width.round(), borderRadius.topLeft.x),
      () => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          <Color>[
            color.withValues(alpha: intensity),
            color.withValues(alpha: intensity * 0.52),
            color.withValues(alpha: intensity * 0.13),
            color.withValues(alpha: intensity * 0.09),
            _warm.withValues(alpha: intensity * 0.34),
            _warm.withValues(alpha: intensity * 0.15),
          ],
          <double>[0.0, 0.16, 0.40, 0.63, 0.87, 1.0],
        ),
    );

    canvas.drawRRect(rrect, paint);

    // The inner wall. One more hairline, inset, dark at the top and gone by
    // the middle — this is what gives the edge thickness instead of the
    // paper-thin outline a single stroke produces.
    if (!GlassConfig.depth || size.shortestSide < 24) return;

    final inner = borderRadius
        .toRRect(rect.deflate(width + 1.1))
        .scaleRadii();

    final bevel = _PaintCache.of(
      _PaintKey(2, _q(size.width), _q(size.height), 0,
          (intensity * 1000).round(), 0, borderRadius.topLeft.x),
      () => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          <Color>[
            Colors.black.withValues(alpha: 0.16 * intensity / 0.30),
            Colors.black.withValues(alpha: 0.04 * intensity / 0.30),
            Colors.transparent,
          ],
          <double>[0.0, 0.28, 0.62],
        ),
    );

    canvas.drawRRect(inner, bevel);
  }

  @override
  bool shouldRepaint(covariant SpecularBorderPainter old) =>
      old.borderRadius != borderRadius ||
      old.width != width ||
      old.intensity != intensity ||
      old.color != color;
}

/// The body of a liquid-glass surface: the tint, and the light falling
/// through its thickness.
///
/// Replaces the DecoratedBox-plus-SheenPainter pair the cards used to carry.
/// Folding the base fill into the same painter as the highlight removes a
/// whole RenderObject and a whole paint pass from every card on screen, which
/// on a list of a hundred rows is not a rounding error.
class LiquidSurfacePainter extends CustomPainter {
  final BorderRadius borderRadius;

  /// Base colour; the body gradient is derived from it. Null skips the body
  /// fill entirely — used by [GlassSurface], whose fill has to live inside
  /// the BackdropFilter rather than under it.
  final Color? tint;

  /// Pulls the lit corner towards this colour, for surfaces that should feel
  /// illuminated rather than merely tinted.
  final Color? accent;

  /// Strength of the thickness overlay, 0 disables it.
  final double depth;

  const LiquidSurfacePainter({
    required this.borderRadius,
    required this.tint,
    this.accent,
    this.depth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final a = accent;
    final t = tint;

    // ── 1. Body ──────────────────────────────────────────────────────────
    if (t != null) {
      final body = _PaintCache.of(
        _PaintKey(3, _q(size.width), _q(size.height), t.toARGB32(),
            a?.toARGB32() ?? 0, 0, borderRadius.topLeft.x),
        () => Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            a == null
                ? <Color>[
                    Color.alphaBlend(Colors.white.withValues(alpha: 0.045), t),
                    Color.alphaBlend(Colors.white.withValues(alpha: 0.012), t),
                    t,
                    Color.alphaBlend(Colors.black.withValues(alpha: 0.18), t),
                  ]
                : <Color>[
                    Color.alphaBlend(a.withValues(alpha: 0.18), t),
                    Color.alphaBlend(a.withValues(alpha: 0.07), t),
                    t,
                    Color.alphaBlend(Colors.black.withValues(alpha: 0.14), t),
                  ],
            const <double>[0.0, 0.28, 0.62, 1.0],
          ),
      );
      canvas.drawRRect(rrect, body);
    }

    if (depth <= 0 || !GlassConfig.depth) return;

    // ── 2. Thickness ─────────────────────────────────────────────────────
    // One near-vertical pass carries both cues at once: the lit lip along the
    // top and the shadow pooling at the bottom. Two separate fills would look
    // the same and cost twice as much.
    final gloss = _PaintCache.of(
      _PaintKey(4, _q(size.width), _q(size.height), 0, 0,
          (depth * 1000).round(), borderRadius.topLeft.x),
      () => Paint()
        ..isAntiAlias = true
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.18, 0),
          Offset(size.width * 0.72, size.height),
          <Color>[
            Colors.white.withValues(alpha: 0.075 * depth),
            Colors.white.withValues(alpha: 0.026 * depth),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.10 * depth),
          ],
          const <double>[0.0, 0.10, 0.34, 0.74, 1.0],
        ),
    );
    canvas.drawRRect(rrect, gloss);
  }

  @override
  bool shouldRepaint(covariant LiquidSurfacePainter old) =>
      old.borderRadius != borderRadius ||
      old.tint != tint ||
      old.accent != accent ||
      old.depth != depth;
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

  /// Base fill. Pass null when something behind already painted the body —
  /// [GlassSurface] does, because its fill has to sit inside the blur.
  final Color? tint;
  final Color? accent;
  final double depth;

  final double edgeIntensity;
  final Color edgeColor;

  const _GlassOverlays({
    required this.child,
    required this.borderRadius,
    required this.edgeIntensity,
    required this.edgeColor,
    this.tint,
    this.accent,
    this.depth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final t = tint;

    return CustomPaint(
      painter: (t == null && (depth <= 0 || !GlassConfig.depth))
          ? null
          : LiquidSurfacePainter(
              borderRadius: borderRadius,
              tint: t,
              accent: accent,
              depth: depth,
            ),
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

class _GlassPressableState extends State<GlassPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 190),
  );

  late Animation<double> _scale = _buildScale();

  Animation<double> _buildScale() => Tween<double>(
        begin: 1.0,
        end: widget.scale,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ));

  @override
  void didUpdateWidget(GlassPressable old) {
    super.didUpdateWidget(old);
    if (old.scale != widget.scale) _scale = _buildScale();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _set(bool down) {
    if (!mounted) return;
    if (down) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
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
      // ScaleTransition with the child in the `child:` slot, not AnimatedScale
      // driven by setState. The old version rebuilt the entire card subtree on
      // press-down and again on release; this one rebuilds nothing at all —
      // the child widget is captured once and only the transform animates.
      // On a card holding a dozen Text widgets that is the difference between
      // a press that feels instant and one that hitches.
      child: ScaleTransition(
        scale: _scale,
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

    // NO RepaintBoundary around the BackdropFilter.
    //
    // A repaint boundary exists to let a subtree keep its rasterised output
    // when nothing inside it changed. That is precisely the wrong contract for
    // a backdrop filter, whose output depends on the content BEHIND it, which
    // lives outside the boundary. When the page under the nav dock is
    // replaced, nothing inside the dock has changed — so the boundary happily
    // serves the cached blur of the page that is no longer there, and the old
    // screen goes on showing through the dock as a smear.
    //
    // Without the boundary the filter repaints with its parent and always
    // samples what is actually behind it. It costs nothing extra: a
    // BackdropFilter already forces its own layer, so there was never a raster
    // cache to protect here in the first place.
    Widget surface = ClipRRect(
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
          // tint stays null: the body gradient is already on the DecoratedBox
          // above, inside the blur where it belongs.
          child: _GlassOverlays(
            borderRadius: br,
            edgeIntensity: edgeIntensity,
            edgeColor: edgeColor ?? AppColorsV2.onSurface,
            child: Padding(padding: padding, child: child),
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

    // The body fill, the thickness overlay and the rim are now all painted by
    // the one CustomPaint below. The DecoratedBox that used to carry the
    // gradient is gone, so a card with no shadow costs exactly one render
    // object — which is the common case, and the one that repeats a hundred
    // times in a list.
    Widget card = _GlassOverlays(
      borderRadius: br,
      tint: tint,
      accent: accent,
      edgeIntensity: edgeIntensity,
      edgeColor: edgeColor ?? AppColorsV2.onSurface,
      child: Padding(padding: padding, child: child),
    );

    final shadows = <BoxShadow>[
      if (glow != null)
        BoxShadow(
          color: glow!.withValues(alpha: 0.18),
          blurRadius: 28,
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

    if (shadows.isNotEmpty) {
      card = DecoratedBox(
        decoration: BoxDecoration(borderRadius: br, boxShadow: shadows),
        child: card,
      );
    }

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
