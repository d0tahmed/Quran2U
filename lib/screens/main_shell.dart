import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_recitation/screens/home_screen.dart';
import 'package:quran_recitation/screens/now_playing_screen.dart';
import 'package:quran_recitation/screens/settings_screen.dart';
import 'package:quran_recitation/screens/daily_inspiration_screen.dart'; 
import 'package:quran_recitation/services/notification_service.dart';   
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

const _kBg = AppColorsV2.bg;

/// Global provider so any screen can switch tabs
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Global provider to hide navigation bar on scroll
final navBarVisibleProvider = StateProvider<bool>((ref) => true);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // SENIOR FIX: The clean 3-item layout. Player is back!
  static const _screens = [
    HomeScreen(),
    NowPlayingScreen(),
    SettingsScreen(),
  ];

  StreamSubscription<String?>? _notifSub;

  @override
  void initState() {
    super.initState();
    // Listen for 6 AM notification taps and push the Daily screen directly!
    _notifSub = NotificationService.onNotifications.stream.listen((payload) {
      if (payload == 'daily_tab' && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DailyInspirationScreen())
        );
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawIndex = ref.watch(shellIndexProvider);
    final index = rawIndex.clamp(0, _screens.length - 1);
    if (rawIndex != index) {
      // Defensive: if tab count changes (hot restart / restored state),
      // ensure we always point at an existing screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellIndexProvider.notifier).state = index;
      });
    }

    return Scaffold(
      backgroundColor: _kBg,
      extendBody: true, 
      body: Stack(
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
      bottomNavigationBar: SafeArea(
        child: AnimatedSlide(
          offset: ref.watch(navBarVisibleProvider) ? Offset.zero : const Offset(0, 1.5),
          duration: Duration(milliseconds: ref.watch(navBarVisibleProvider) ? 400 : 300),
          curve: ref.watch(navBarVisibleProvider) ? Curves.easeOutBack : Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GlassPanel(
              // iOS-like floating bubble: more blur + subtle tint.
              tint: AppColorsV2.surface,
              borderRadius: BorderRadius.circular(28),
              padding: EdgeInsets.zero,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
              child: SizedBox(
                // NavigationBar has an intrinsic height (~80). Constraining it
                // smaller can cause RenderFlex overflow during layout.
                height: 80,
                child: NavigationBar(
                  selectedIndex: index,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  onDestinationSelected: (i) =>
                      ref.read(shellIndexProvider.notifier).state = i,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: 'Surahs',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.headphones_outlined),
                      selectedIcon: Icon(Icons.headphones_rounded),
                      label: 'Player',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}