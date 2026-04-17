import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/services/notification_service.dart';
import 'package:quran_recitation/ui_v2/app_theme.dart';

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
      theme: AppThemeV2.dark(),
      home: const MainShell(),
    );
  }
}