import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/home_screen.dart';
import 'package:quran_recitation/screens/now_playing_screen.dart';
import 'package:quran_recitation/screens/settings_screen.dart';
import 'package:quran_recitation/screens/daily_inspiration_screen.dart';
import 'package:quran_recitation/services/notification_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/widgets/calm_light_background.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_recitation/screens/read_tab_screen.dart';

final shellIndexProvider = StateProvider<int>((ref) => 0);
final navBarVisibleProvider = StateProvider<bool>((ref) => true);

class MainShell extends ConsumerStatefulWidget {
  final bool showWelcome;
  final bool isGuestWelcome; // true = guest path; uses prefs to show only once
  const MainShell(
      {super.key, this.showWelcome = false, this.isGuestWelcome = false});

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
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const DailyInspirationScreen()));
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

  Future<void> _showWelcomeDialog(BuildContext context,
      {bool isGuest = false}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 26),
          decoration: BoxDecoration(
            color: AppColorsV2.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColorsV2.goldHairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 48,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QStarMedallion(
                size: 64,
                color: AppColorsV2.tertiary.withValues(alpha: 0.55),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColorsV2.tertiary, size: 24),
              ),
              const SizedBox(height: 20),
              Text('Welcome to', style: AppTypeV2.overline(size: 10)),
              const SizedBox(height: 6),
              Text('Quran2U',
                  textAlign: TextAlign.center,
                  style: AppTypeV2.display(size: 32)),
              const SizedBox(height: 16),
              const QOrnamentDivider(),
              const SizedBox(height: 16),
              Text(
                'May Allah bless your journey with this app and strengthen your Imaan through His guidance and the words of the Holy Quran.\nMay every recitation bring you closer to Him. آمين',
                style: AppTypeV2.body(size: 13, height: 1.75),
                textAlign: TextAlign.center,
              ),

              // ── Guest tip ──────────────────────────────────────────────
              if (isGuest) ...[
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColorsV2.tertiary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColorsV2.goldHairline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cloud_upload_rounded,
                          color: AppColorsV2.tertiary, size: 17),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tip: connect your Quran.com account from Settings to sync bookmarks across devices and unlock the full experience.',
                          style: AppTypeV2.body(size: 11.5, height: 1.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsV2.primary,
                    foregroundColor: AppColorsV2.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Begin Reading ✶',
                    style: AppTypeV2.title(
                        size: 14, color: AppColorsV2.onPrimary),
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

    // Auto-advance to the next Surah when playback finishes (unless looping)
    ref.listen<AsyncValue<PlayerState>>(currentPlayerStateProvider,
        (previous, next) {
      final state = next.value;
      if (state != null && state.processingState == ProcessingState.completed) {
        final loop = ref.read(loopProvider);
        if (!loop) {
          final currentSurah = ref.read(currentSurahProvider);
          if (currentSurah != null && currentSurah < 114) {
            final nextSurah = currentSurah + 1;
            final imam = ref.read(selectedImamProvider);
            if (imam != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(currentSurahProvider.notifier).state = nextSurah;

                final tarjumahMode = ref.read(tarjumahModeProvider);
                if (tarjumahMode) {
                  final allSurahs = ref.read(surahsProvider).asData?.value ?? [];
                  final s = allSurahs.cast<Surah?>().firstWhere(
                      (s) => s?.number == nextSurah,
                      orElse: () => null);
                  if (s != null) {
                    ref.read(interleavedAudioServiceProvider).buildAndPlay(
                          surahNumber: nextSurah,
                          ayahCount: s.ayahCount,
                          imamId: imam.id,
                        );
                  }
                } else {
                  final url = ref.read(audioUrlProvider((nextSurah, imam.id)));
                  ref.read(audioPlayerServiceProvider).loadAndPlay(url,
                      surahNumber: nextSurah, imamId: imam.id);
                }
              });
            }
          }
        }
      }
    });

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
                scale: i == index ? 1.0 : 0.98,
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
          offset: ref.watch(navBarVisibleProvider)
              ? Offset.zero
              : const Offset(0, 1.6),
          duration: Duration(
              milliseconds: ref.watch(navBarVisibleProvider) ? 380 : 280),
          curve: ref.watch(navBarVisibleProvider)
              ? Curves.easeOutCubic
              : Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: _SakinaNavBar(
              index: index,
              onSelect: (i) =>
                  ref.read(shellIndexProvider.notifier).state = i,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sakina navigation dock
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

class _SakinaNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _SakinaNavBar({required this.index, required this.onSelect});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.headphones_outlined, Icons.headphones_rounded, 'Listen'),
    _NavItem(Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Read'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColorsV2.surface.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColorsV2.hairline),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColorsV2.primary.withValues(alpha: 0.13)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? AppColorsV2.primary.withValues(alpha: 0.22)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color: selected
                              ? AppColorsV2.primary
                              : AppColorsV2.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: selected
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    item.label,
                                    style: AppTypeV2.caption(
                                      size: 10,
                                      color: AppColorsV2.primary,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 0, width: 0),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
