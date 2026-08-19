import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

/// Sakina theme — one dark theme, tuned for calm.
class AppThemeV2 {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    const scheme = ColorScheme.dark(
      primary: AppColorsV2.primary,
      onPrimary: AppColorsV2.onPrimary,
      secondary: AppColorsV2.secondary,
      tertiary: AppColorsV2.tertiary,
      surface: AppColorsV2.surface,
      onSurface: AppColorsV2.onSurface,
      onSurfaceVariant: AppColorsV2.onSurfaceVariant,
      outline: AppColorsV2.outlineVariant,
      error: AppColorsV2.danger,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsV2.bg,
      colorScheme: scheme,
      splashColor: AppColorsV2.primary.withValues(alpha: 0.06),
      highlightColor: AppColorsV2.primary.withValues(alpha: 0.04),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColorsV2.onSurface,
        displayColor: AppColorsV2.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsV2.bg,
        foregroundColor: AppColorsV2.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: AppColorsV2.onSurface,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsV2.hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsV2.surfaceLow,
        hintStyle: GoogleFonts.manrope(
          color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.75),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColorsV2.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColorsV2.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColorsV2.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColorsV2.primary.withValues(alpha: 0.45),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
      sliderTheme: const SliderThemeData(trackHeight: 3).copyWith(
        activeTrackColor: AppColorsV2.primary,
        inactiveTrackColor: AppColorsV2.surfaceHighest,
        thumbColor: AppColorsV2.onSurface,
        overlayColor: AppColorsV2.primary.withValues(alpha: 0.14),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsV2.primary,
        linearTrackColor: AppColorsV2.surfaceHighest,
        circularTrackColor: AppColorsV2.surfaceHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsV2.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: GoogleFonts.manrope(
          color: AppColorsV2.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColorsV2.onSurfaceVariant,
        textColor: AppColorsV2.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      // Kept for any Material NavigationBar still in the tree.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColorsV2.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.6,
            color: selected
                ? AppColorsV2.primary
                : AppColorsV2.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppColorsV2.primary
                : AppColorsV2.onSurfaceVariant,
            size: selected ? 25 : 23,
          );
        }),
      ),
    );
  }
}
