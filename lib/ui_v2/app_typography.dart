import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

/// Sakina type system.
///
/// Three voices, used consistently across the app:
///  • Display — Playfair Display. Editorial serif for names, numerals and
///    hero moments. Never for body copy.
///  • UI — Manrope. Everything functional: labels, body, buttons.
///  • Arabic — Amiri. All Quranic and Arabic text.
class AppTypeV2 {
  AppTypeV2._();

  // ── Display (serif) ───────────────────────────────────────────────────────
  static TextStyle display({
    double size = 30,
    Color color = AppColorsV2.onSurface,
    FontWeight weight = FontWeight.w600,
    double height = 1.15,
    double letterSpacing = -0.4,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );

  // ── Overline (letterspaced small caps feel) ───────────────────────────────
  static TextStyle overline({
    double size = 10.5,
    Color color = AppColorsV2.tertiary,
    double letterSpacing = 2.6,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  // ── UI text ───────────────────────────────────────────────────────────────
  static TextStyle title({
    double size = 16,
    Color color = AppColorsV2.onSurface,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = -0.2,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double size = 13.5,
    Color color = AppColorsV2.onSurfaceVariant,
    FontWeight weight = FontWeight.w600,
    double height = 1.6,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  static TextStyle caption({
    double size = 11.5,
    Color color = AppColorsV2.onSurfaceVariant,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.manrope(fontSize: size, color: color, fontWeight: weight);

  // ── Arabic ────────────────────────────────────────────────────────────────
  static TextStyle arabic({
    double size = 26,
    Color color = AppColorsV2.onSurface,
    double height = 1.9,
    FontWeight weight = FontWeight.w700,
  }) =>
      TextStyle(
        fontSize: size,
        color: color,
        height: height,
        fontFamily: GoogleFonts.amiri().fontFamily,
        fontWeight: weight,
      );
}
