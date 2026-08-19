import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Quran2U design language — "Sakina" (settled, quiet, modern)
///
/// Direction: deep obsidian-green ink, warm ivory text, calm jade as the only
/// interactive colour, antique manuscript gold reserved for identity and
/// emphasis. No neon, no blue-navy, no glow-for-glow's-sake.
///
/// The class name and every member are kept identical to the previous palette
/// so all existing screens re-skin automatically.
/// ─────────────────────────────────────────────────────────────────────────────
class AppColorsV2 {
  // ── Canvas ────────────────────────────────────────────────────────────────
  static const bg = Color(0xFF0B100E); // obsidian with a green undertone
  static const surface = Color(0xFF141B17);
  static const surfaceLow = Color(0xFF101613);
  static const surfaceHigh = Color(0xFF1C2420);
  static const surfaceHighest = Color(0xFF28322C);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF74C6A4); // calm jade — interactive
  static const primaryContainer = Color(0xFF1A5743); // deep emerald
  static const tertiary = Color(0xFFD8B36E); // antique manuscript gold
  static const secondary = Color(0xFFA9C4CB); // sea-mist (cool counterpoint)

  // ── Ink ───────────────────────────────────────────────────────────────────
  static const onSurface = Color(0xFFECEFE9); // warm ivory
  static const onSurfaceVariant = Color(0xFFA2AFA6); // sage grey

  static const outlineVariant = Color(0xFF37423B);

  // ── Status ────────────────────────────────────────────────────────────────
  static const danger = Color(0xFFEDAA9F);
  static const dangerContainer = Color(0xFF7C2D22);

  // ── Sakina additions (safe extras — do not remove members above) ─────────
  /// Ink used on top of [primary] fills (buttons, play control).
  static const onPrimary = Color(0xFF07241B);

  /// Ink used on top of [tertiary] fills.
  static const onGold = Color(0xFF2B2008);

  /// 8% ivory — the single hairline used across every card and divider.
  static const hairline = Color(0x14ECEFE9);

  /// 5% gold — hairline for gold-framed moments (medallions, ornaments).
  static const goldHairline = Color(0x2ED8B36E);
}
