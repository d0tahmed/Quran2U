// lib/models/share_card_style.dart
//
// Presets for the shareable ayah card. Each one is a complete visual recipe;
// the renderer reads nothing else.

import 'package:flutter/material.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

enum ShareCardFormat {
  /// 1:1 — Instagram / WhatsApp post.
  square,

  /// 9:16 — Instagram / WhatsApp story.
  story,
}

extension ShareCardFormatX on ShareCardFormat {
  String get label => this == ShareCardFormat.square ? 'Post' : 'Story';
  IconData get icon => this == ShareCardFormat.square
      ? Icons.crop_square_rounded
      : Icons.crop_portrait_rounded;

  /// Logical width used when laying the card out. Captured at 3x, so a square
  /// card exports at 1080 x 1080.
  double get width => 360;

  double get height => this == ShareCardFormat.square ? 360 : 640;
}

@immutable
class ShareCardStyle {
  final String name;

  /// Background gradient, top-left to bottom-right.
  final List<Color> background;

  /// Arabic and translation ink.
  final Color arabicColor;
  final Color translationColor;

  /// Reference line, ornament and frame.
  final Color accent;

  /// Frame hairline.
  final Color frame;

  /// True when the card is light — the wordmark switches to a darker ink.
  final bool isLight;

  const ShareCardStyle({
    required this.name,
    required this.background,
    required this.arabicColor,
    required this.translationColor,
    required this.accent,
    required this.frame,
    this.isLight = false,
  });

  static const List<ShareCardStyle> presets = <ShareCardStyle>[
    // 1 — the app's own voice
    ShareCardStyle(
      name: 'Obsidian',
      background: [Color(0xFF0B100E), Color(0xFF141B17)],
      arabicColor: AppColorsV2.onSurface,
      translationColor: Color(0xFFA2AFA6),
      accent: AppColorsV2.tertiary,
      frame: Color(0x33D8B36E),
    ),
    // 2 — gold on deep green, the manuscript look
    ShareCardStyle(
      name: 'Manuscript',
      background: [Color(0xFF08211A), Color(0xFF0B100E)],
      arabicColor: Color(0xFFEBD9AE),
      translationColor: Color(0xFFB9C4B4),
      accent: Color(0xFFD8B36E),
      frame: Color(0x4DD8B36E),
    ),
    // 3 — jade, matches the app's interactive accent
    ShareCardStyle(
      name: 'Jade',
      background: [Color(0xFF10241D), Color(0xFF0B100E)],
      arabicColor: Color(0xFFEFF5F0),
      translationColor: Color(0xFF9FBEAF),
      accent: AppColorsV2.primary,
      frame: Color(0x4D74C6A4),
    ),
    // 4 — paper, for people who share on light backgrounds
    ShareCardStyle(
      name: 'Paper',
      background: [Color(0xFFF6F1E6), Color(0xFFEDE5D6)],
      arabicColor: Color(0xFF1A2420),
      translationColor: Color(0xFF54605A),
      accent: Color(0xFF9A7B3C),
      frame: Color(0x3D6B5526),
      isLight: true,
    ),
  ];
}
