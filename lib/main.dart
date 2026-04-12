import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX 1: JustAudioBackground MUST be initialized before runApp.
  // Without this call the background audio isolate crashes silently —
  // the MediaItem tag in AudioPlayerService has no service to register with.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.quran2u.channel.audio',
    androidNotificationChannelName: 'Quran Recitation',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

  // Initialize daily notification engine
  await NotificationService.init();
  await NotificationService.scheduleDaily6AM();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0C0F1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: QuranRecitationApp()));
}

class QuranRecitationApp extends StatelessWidget {
  const QuranRecitationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran2U',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MainShell(),
    );
  }

  ThemeData _buildTheme() {
    const primaryGreen = Color(0xFF10B981);
    const darkBg      = Color(0xFF05080F);
    const darkSurface  = Color(0xFF0E1421);
    const darkCard     = Color(0xFF121B2B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: Color(0xFFEAB308),
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.outfit(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 12,
        splashColor: Color(0xFF34D399),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryGreen,
        thumbColor: Colors.white,
        inactiveTrackColor: Color(0xFF1E293B),
        trackHeight: 3,
        overlayColor: Color(0x3310B981),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: primaryGreen,
        side: BorderSide.none,
        labelPadding: EdgeInsets.symmetric(horizontal: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF131B2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIconColor: Colors.white38,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: primaryGreen.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
                color: primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600);
          }
          return GoogleFonts.outfit(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w400);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 26);
          }
          return const IconThemeData(color: Colors.white38, size: 24);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
} //test comment//