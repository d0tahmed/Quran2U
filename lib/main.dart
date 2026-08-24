import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/login_screen.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/services/adhan_service.dart';
import 'package:quran_recitation/services/notification_service.dart';
import 'package:quran_recitation/services/perf_governor.dart';
import 'package:quran_recitation/services/widget_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_theme.dart';

// ── WorkManager background callback ────────────────────────────────────────
// This runs in its own isolate when the app is closed.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await WidgetService.refreshWidget();
    return Future.value(true);
  });
}

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

  // ── Home-screen widget ────────────────────────────────────────────────
  // Initialize HomeWidget with the app group for SharedPreferences.
  HomeWidget.setAppGroupId('com.quran2u.app');

  // Initialize WorkManager for periodic background refresh.
  await Workmanager().initialize(callbackDispatcher);
  // Register a periodic task that runs every ~15 min (Android minimum).
  await Workmanager().registerPeriodicTask(
    'prayer-widget-refresh',
    'refreshPrayerWidget',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
    ),
  );

  // Refresh the widget immediately on app start.
  WidgetService.refreshWidget();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0B100E), // Sakina obsidian
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
        debugPrint('[AuthGate] Storage timeout! Keystore is likely corrupted. Forcing login.');
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

class QuranRecitationApp extends StatefulWidget {
  const QuranRecitationApp({super.key});

  @override
  State<QuranRecitationApp> createState() => _QuranRecitationAppState();
}

class _QuranRecitationAppState extends State<QuranRecitationApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start measuring after the first frame is on screen. Started any earlier
    // it would sample the frames spent inflating the very first route, which
    // are slow on every device and say nothing about this one.
    WidgetsBinding.instance.addPostFrameCallback((_) => PerfGovernor.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Rotation and multi-window resize change every surface size, and the
    // glass shader cache is keyed by size — the old entries can never be hit
    // again, so drop them rather than let them sit until they age out.
    PerfGovernor.onMetricsChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Opening the app is the one moment we are guaranteed to be allowed to
    // run. Push fresh prayer data to the home-screen widget then, so it can
    // never sit on stale times even if the OS throttles our WorkManager job.
    if (state == AppLifecycleState.resumed) {
      // AdhanService.sync() republishes the seven-day prayer schedule — the
      // same rows the widget draws — and then tells the native scheduler to
      // re-arm from it. One call keeps the widget and the adhan in step,
      // which is the whole reason they read the same data.
      AdhanService.sync();

      // Re-arm the daily reminder window on every resume, not only on a cold
      // start. Android drops every pending alarm an app owns when that app is
      // force-stopped — and "clear all" in recents, or an OEM battery cleaner,
      // counts as a force-stop. This is why the reminder fired only
      // occasionally. Re-arming here means a single app open refills the
      // fourteen-day window, so the schedule heals itself. Cheap, and it
      // swallows its own errors.
      NotificationService.scheduleDailyReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran2U',
      debugShowCheckedModeBanner: false,
      theme: AppThemeV2.dark(),
      // Devices shipped with a large system font scale (very common on
      // Infinix/Tecno/Xiaomi) blow every tight row past its bounds and produce
      // the yellow "RenderFlex overflowed" stripes. Honour the user's setting
      // up to 1.2x, then stop — beyond that the layout, not the text, breaks.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.2),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // 👇 The app now boots to the Gatekeeper instead of the MainShell! 👇
      home: const AuthGate(),
    );
  }
}