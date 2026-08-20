import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Sakina component kit — the small set of shared pieces the redesigned
/// screens are built from. Keep this file lean; screens own their layouts.
/// ─────────────────────────────────────────────────────────────────────────────

// ── Eight-point star (Rub el Hizb) ───────────────────────────────────────────

/// Outline of the classic two-rotated-squares star. Used for medallions,
/// ornaments and the background lattice.
class EightPointStarPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool fill;

  const EightPointStarPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.fill = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    final c = Offset(size.width / 2, size.height / 2);
    final half = math.min(size.width, size.height) / 2 - strokeWidth;

    // PERF: both squares go into ONE Path and one draw call. This painter runs
    // for every surah medallion in a 114-row list, so two Path allocations and
    // two draws per row was worth collapsing.
    final path = Path();
    for (final rotation in const [0.0, math.pi / 4]) {
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

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EightPointStarPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.fill != fill;
}

/// A number (or any child) framed inside a gold eight-point star outline.
class QStarMedallion extends StatelessWidget {
  final double size;
  final Widget child;
  final Color color;

  const QStarMedallion({
    super.key,
    required this.child,
    this.size = 44,
    this.color = AppColorsV2.goldHairline,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: EightPointStarPainter(color: color, strokeWidth: 1.1),
          ),
          child,
        ],
      ),
    );
  }
}

// ── Ornamental divider ───────────────────────────────────────────────────────

/// Thin hairline with a small gold diamond at its centre — the Sakina rule.
class QOrnamentDivider extends StatelessWidget {
  final double width;
  const QOrnamentDivider({super.key, this.width = 120});

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              AppColorsV2.tertiary.withValues(alpha: 0.35),
            ]),
          ),
        );
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(child: line()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 5,
                height: 5,
                color: AppColorsV2.tertiary.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Transform.flip(flipX: true, child: line()),
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class QSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const QSectionHeader({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 1.5,
          color: AppColorsV2.tertiary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 10),
        Text(label.toUpperCase(), style: AppTypeV2.overline()),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

/// The workhorse card. Frosted, not blurred — safe to use inside lists.
///
/// API is unchanged; it now renders with the tint gradient, sheen and
/// specular rim of the glass system instead of a flat fill plus a 1px border.
class QCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color color;
  final double radius;

  /// Lights the top-left corner with a colour — for cards that lead a screen.
  final Color? accent;

  /// Drop shadow. Leave off for repeated rows.
  final bool elevated;

  /// Coloured bloom beneath the card. At most one per screen.
  final Color? glow;

  const QCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.onLongPress,
    this.color = AppColorsV2.surfaceLow,
    this.radius = 26,
    this.accent,
    this.elevated = false,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: radius,
      padding: padding,
      tint: color,
      accent: accent,
      elevated: elevated,
      glow: glow,
      edgeColor: accent,
      edgeIntensity: accent == null ? 0.20 : 0.34,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

// ── Chip ─────────────────────────────────────────────────────────────────────

class QChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const QChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    // A selected chip is a lit pane of jade glass rather than a flat fill:
    // gradient body, bright rim, soft bloom underneath.
    return GlassPill(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Text(
            label,
            style: AppTypeV2.caption(
              size: 12,
              color:
                  selected ? AppColorsV2.onSurface : AppColorsV2.onSurfaceVariant,
              weight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
