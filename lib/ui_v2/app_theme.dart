import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

class AppThemeV2 {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    const scheme = ColorScheme.dark(
      primary: AppColorsV2.primary,
      secondary: AppColorsV2.secondary,
      tertiary: AppColorsV2.tertiary,
      surface: AppColorsV2.surface,
      onSurface: AppColorsV2.onSurface,
      outline: AppColorsV2.outlineVariant,
      error: AppColorsV2.danger,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsV2.bg,
      colorScheme: scheme,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColorsV2.onSurface,
        displayColor: AppColorsV2.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsV2.bg.withValues(alpha: 0.80),
        foregroundColor: AppColorsV2.onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: AppColorsV2.primary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsV2.surfaceLow,
        hintStyle: TextStyle(color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.85)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColorsV2.primary.withValues(alpha: 0.5), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
      ).copyWith(
        activeTrackColor: AppColorsV2.primary,
        inactiveTrackColor: AppColorsV2.surfaceHighest,
        thumbColor: Colors.white,
        overlayColor: AppColorsV2.primary.withValues(alpha: 0.18),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColorsV2.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 1.1,
            color: selected ? AppColorsV2.primary : AppColorsV2.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColorsV2.primary : AppColorsV2.onSurfaceVariant,
            size: selected ? 26 : 24,
          );
        }),
      ),
    );
  }
}

