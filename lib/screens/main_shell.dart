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
import 'package:quran_recitation/ui_v2/widgets/calm_light_background.dart';

const _kBg = AppColorsV2.bg;

final shellIndexProvider = StateProvider<int>((ref) => 0);
final navBarVisibleProvider = StateProvider<bool>((ref) => true);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _screens = [
    HomeScreen(),
    NowPlayingScreen(),
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