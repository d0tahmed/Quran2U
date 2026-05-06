import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/home_screen.dart';
import 'package:quran_recitation/screens/now_playing_screen.dart';
import 'package:quran_recitation/screens/settings_screen.dart';
import 'package:quran_recitation/screens/daily_inspiration_screen.dart'; 
import 'package:quran_recitation/services/notification_service.dart';   
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/calm_light_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_recitation/screens/read_tab_screen.dart';


final shellIndexProvider = StateProvider<int>((ref) => 0);
final navBarVisibleProvider = StateProvider<bool>((ref) => true);

class MainShell extends ConsumerStatefulWidget {
  final bool showWelcome;
  final bool isGuestWelcome; // true = guest path; uses prefs to show only once
  const MainShell({super.key, this.showWelcome = false, this.isGuestWelcome = false});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _screens = [
    HomeScreen(),
    NowPlayingScreen(),
    ReadTabScreen(),
    SettingsScreen(),
  ];

  StreamSubscription<String?>? _notifSub;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationService.onNotifications.stream.listen((payload) {
      if (payload == 'daily_tab' && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DailyInspirationScreen())
        );
      }
    });

    // Show the welcome dialog after the first frame has rendered.
    // Request location permission AFTER the dialog is dismissed so the
    // native permission dialog is never swallowed behind a Flutter modal.
    if (widget.showWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // For guest path: only show once using a SharedPreferences flag
        if (widget.isGuestWelcome) {
          final prefs = await SharedPreferences.getInstance();
          final seen = prefs.getBool('has_seen_welcome') ?? false;
          if (seen || !mounted) return;
          await prefs.setBool('has_seen_welcome', true);
        }
        if (mounted) {
          // Wait for user to dismiss welcome dialog, then ask for location.
          await _showWelcomeDialog(context, isGuest: widget.isGuestWelcome);
          await _requestLocationPermission();
          await NotificationService.requestPermissions();
          await NotificationService.scheduleDaily6AM();
        }
      });
    } else {
      // No welcome dialog — request permission after first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _requestLocationPermission();
        await NotificationService.requestPermissions();
        await NotificationService.scheduleDaily6AM();
      });
    }
  }

  /// Prompts for location permission if not yet granted, then refreshes providers.
  Future<void> _requestLocationPermission() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      // Once granted, force the location + prayer providers to re-run
      // so the home card shows real coordinates instead of the fallback.
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        ref.invalidate(locationProvider);
        ref.invalidate(prayerTimesProvider);
      }
    } catch (_) {
      // Silently ignore if location service is unavailable
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _showWelcomeDialog(BuildContext context, {bool isGuest = false}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: AppColorsV2.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColorsV2.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColorsV2.primary.withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@d0tahmed',
                style: TextStyle(
                  color: AppColorsV2.primary.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColorsV2.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColorsV2.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColorsV2.primary, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Quran2U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'May Allah bless your journey with this app and strengthen your Imaan through His guidance and the words of the Holy Quran.\nMay every recitation bring you closer to Him. \u0622\u0645\u064a\u0646',
                style: TextStyle(
                  color: AppColorsV2.onSurfaceVariant,
                  fontSize: 13.5,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              // ── Guest tip ──────────────────────────────────────────────
              if (isGuest) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColorsV2.tertiary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColorsV2.tertiary.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cloud_upload_rounded,
                          color: AppColorsV2.tertiary, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '💡 Tip: Connect your Quran.com account from Settings to sync bookmarks across devices and unlock the full experience!',
                          style: TextStyle(
                            color: AppColorsV2.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsV2.primary,
                    foregroundColor: const Color(0xFF00311F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Begin Reading \u2736',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: Color(0xFF00311F),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final rawIndex = ref.watch(shellIndexProvider);
    final index = rawIndex.clamp(0, _screens.length - 1);
    
    if (rawIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellIndexProvider.notifier).state = index;
      });
    }

   return Scaffold(
      backgroundColor: Colors.transparent, 
      extendBody: true, 
      body: CalmLightBackground(
        child: Stack(
          children: List.generate(_screens.length, (i) {
            return AnimatedOpacity(
              opacity: i == index ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: AnimatedScale(
                scale: i == index ? 1.0 : 0.97,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: i != index,
                  child: _screens[i],
                ),
              ),
            );
          }),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: AnimatedSlide(
          offset: ref.watch(navBarVisibleProvider) ? Offset.zero : const Offset(0, 1.5),
          duration: Duration(milliseconds: ref.watch(navBarVisibleProvider) ? 400 : 300),
          curve: ref.watch(navBarVisibleProvider) ? Curves.easeOutBack : Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColorsV2.surface.withValues(alpha: 0.5), 
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
                  ),
                  child: SizedBox(
                    height: 80,
                    child: NavigationBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      indicatorColor: AppColorsV2.primary.withValues(alpha: 0.25),
                      selectedIndex: index,
                      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                      onDestinationSelected: (i) => ref.read(shellIndexProvider.notifier).state = i,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.menu_book_outlined, color: Colors.white70),
                          selectedIcon: Icon(Icons.menu_book_rounded, color: AppColorsV2.primary),
                          label: 'Surahs',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.headphones_outlined, color: Colors.white70),
                          selectedIcon: Icon(Icons.headphones_rounded, color: AppColorsV2.primary),
                          label: 'Player',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.auto_stories_outlined, color: Colors.white70),
                          selectedIcon: Icon(Icons.auto_stories_rounded, color: AppColorsV2.primary),
                          label: 'Read',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined, color: Colors.white70),
                          selectedIcon: Icon(Icons.settings_rounded, color: AppColorsV2.primary),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}