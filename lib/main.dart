import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/login_screen.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/services/notification_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
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

// 1. The Provider that checks the hard drive for tokens or guest status
final authInitProvider = FutureProvider<bool>((ref) async {
  final authService = ref.read(quranAuthServiceProvider);
  
  try {
    // Wrap the storage checks in a 2-second timeout.
    // If Android Auto Backup restores the EncryptedSharedPreferences XML file
    // but the Keystore key is missing (because of an uninstall/reinstall),
    // FlutterSecureStorage can deadlock/hang infinitely.
    // This timeout ensures we always fall back to the LoginScreen.
    return await Future.any([
      () async {
        final isLoggedIn = await authService.isLoggedIn;
        if (isLoggedIn) return true;
        
        final isGuest = await authService.isGuest;
        if (isGuest) return true;
        
        return false;
      }(),
      Future.delayed(const Duration(milliseconds: 1500), () {
        print('[AuthGate] Storage timeout! Keystore is likely corrupted. Forcing login.');
        return false;
      }),
    ]);
  } catch (e) {
    return false;
  }
});

// 2. The Gatekeeper Widget that decides which screen to show
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authInitProvider);

    return authState.when(
      data: (isAuthorized) {
        // If they have tokens or are a guest, show the main app
        if (isAuthorized) {
          return const MainShell();
        }
        // Otherwise, force them to log in!
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColorsV2.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColorsV2.primary),
        ),
      ),
      error: (err, stack) => const LoginScreen(),
    );
  }
}

class QuranRecitationApp extends StatelessWidget {
  const QuranRecitationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran2U',
      debugShowCheckedModeBanner: false,
      theme: AppThemeV2.dark(),
      // 👇 The app now boots to the Gatekeeper instead of the MainShell! 👇
      home: const AuthGate(),
    );
  }
}