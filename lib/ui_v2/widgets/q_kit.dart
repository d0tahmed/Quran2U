import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';

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

    Path square(double rotation) {
      final path = Path();
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
      return path;
    }

    canvas.drawPath(square(0), paint);
    canvas.drawPath(square(math.pi / 4), paint);
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

class QCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;

  const QCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = AppColorsV2.surfaceLow,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColorsV2.hairline),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColorsV2.primary : AppColorsV2.surfaceLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColorsV2.primary : AppColorsV2.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              label,
              style: AppTypeV2.caption(
                size: 12,
                color: selected
                    ? AppColorsV2.onPrimary
                    : AppColorsV2.onSurfaceVariant,
                weight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
