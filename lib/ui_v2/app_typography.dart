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

  // ── Cached font families ──────────────────────────────────────────────────
  //
  // PERF: a `GoogleFonts.x()` call is not free. It builds a variant key, runs a
  // closest-match search over the family's variant map, checks the loaded-font
  // registry, and allocates a TextStyle — every single time. These helpers are
  // called for essentially every piece of text in the app, several hundred
  // times per frame on a dense screen, to compute a family name that never
  // changes.
  //
  // CAREFUL: google_fonts resolves a DIFFERENT family per weight — `Manrope_regular`,
  // `Manrope_bold` and so on — so a single cached string reused across weights
  // would silently render one real weight plus synthetic bolding for the rest.
  // The cache is therefore keyed by FontWeight, which keeps the output byte
  // for byte identical to calling GoogleFonts directly.

  static final Map<FontWeight, String?> _manrope = <FontWeight, String?>{};
  static final Map<FontWeight, String?> _playfair = <FontWeight, String?>{};

  static String? manropeFamily(FontWeight weight) => _manrope.putIfAbsent(
      weight, () => GoogleFonts.manrope(fontWeight: weight).fontFamily);

  static String? playfairFamily(FontWeight weight) => _playfair.putIfAbsent(
      weight, () => GoogleFonts.playfairDisplay(fontWeight: weight).fontFamily);

  static final Map<FontWeight, String?> _outfit = <FontWeight, String?>{};
  static final Map<FontWeight, String?> _nastaliq = <FontWeight, String?>{};

  static String? outfitFamily(FontWeight weight) => _outfit.putIfAbsent(
      weight, () => GoogleFonts.outfit(fontWeight: weight).fontFamily);

  static String? nastaliqFamily(FontWeight weight) => _nastaliq.putIfAbsent(
      weight, () => GoogleFonts.notoNastaliqUrdu(fontWeight: weight).fontFamily);

  /// Arabic is only ever requested at the default variant, exactly as the
  /// original `GoogleFonts.amiri().fontFamily` call sites did, so one entry is
  /// the whole cache.
  static final String? amiriFamily = GoogleFonts.amiri().fontFamily;

  // ── Drop-in replacements for direct GoogleFonts calls ─────────────────────
  //
  // WHY THESE EXIST — AND WHY SETTINGS WAS THE SLOWEST SCREEN IN THE APP.
  //
  // The helpers above only cache for code that goes through this class. Around
  // a hundred and ninety call sites still reached for `GoogleFonts.manrope(…)`
  // and `GoogleFonts.outfit(…)` inline — sixty-seven of them in Settings alone.
  // Every one of those builds a variant key, runs a closest-match search over
  // the family's variant map, and checks the loaded-font registry. Per call.
  // Per build.
  //
  // A list only inflates the rows it is about to show, so that cost lands
  // exactly during a scroll, on exactly the frames that have no budget for it.
  // That is the Settings scroll lag: not layout, not paint, but font
  // resolution running dozens of times for every newly visible row.
  //
  // These return a plain TextStyle with an already-resolved family, so the
  // rendered result is identical to what GoogleFonts produced and the lookup
  // happens once per weight for the life of the process.
  static TextStyle manrope({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: manropeFamily(fontWeight ?? FontWeight.w400),
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  static TextStyle outfit({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: outfitFamily(fontWeight ?? FontWeight.w400),
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  static TextStyle notoNastaliqUrdu({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: nastaliqFamily(fontWeight ?? FontWeight.w400),
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  static TextStyle amiri({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: amiriFamily,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  static TextStyle playfairDisplay({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: playfairFamily(fontWeight ?? FontWeight.w400),
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: fontStyle,
      );

  // ── Display (serif) ───────────────────────────────────────────────────────
  static TextStyle display({
    double size = 30,
    Color color = AppColorsV2.onSurface,
    FontWeight weight = FontWeight.w600,
    double height = 1.15,
    double letterSpacing = -0.4,
  }) =>
      TextStyle(
        fontFamily: playfairFamily(weight),
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
      TextStyle(
        fontFamily: manropeFamily(weight),
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
      TextStyle(
        fontFamily: manropeFamily(weight),
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
      TextStyle(
        fontFamily: manropeFamily(weight),
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
      TextStyle(
        fontFamily: manropeFamily(weight),
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

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
        fontFamily: amiriFamily,
        fontWeight: weight,
      );
}
