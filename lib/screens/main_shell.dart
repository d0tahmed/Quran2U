import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_recitation/screens/home_screen.dart';
import 'package:quran_recitation/screens/now_playing_screen.dart';
import 'package:quran_recitation/screens/settings_screen.dart';
import 'package:quran_recitation/screens/daily_inspiration_screen.dart'; 
import 'package:quran_recitation/services/notification_service.dart';   

const _kBg = Color(0xFF05080F);

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

  @override
  void initState() {
    super.initState();
    // Listen for 6 AM notification taps and push the Daily screen directly!
    NotificationService.onNotifications.stream.listen((payload) {
      if (payload == 'daily_tab' && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DailyInspirationScreen())
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellIndexProvider);

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))
                    ],
                  ),
                  child: NavigationBar(
                    selectedIndex: index,
                    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                    onDestinationSelected: (i) =>
                        ref.read(shellIndexProvider.notifier).state = i,
                    // Perfectly balanced 3-item navigation
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
      ),
    );
  }
}