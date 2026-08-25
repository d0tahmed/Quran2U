import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/calm_light_background.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_recitation/screens/read_tab_screen.dart';

final shellIndexProvider = StateProvider<int>((ref) => 0);

// `navBarVisibleProvider` used to live here and slide the dock away on scroll.
// It is gone, and deliberately so — see the note above the dock in build().

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
          await NotificationService.scheduleDailyReminders();
        }
      });
    } else {
      // No welcome dialog — request permission after first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _requestLocationPermission();
        await NotificationService.requestPermissions();
        await NotificationService.scheduleDailyReminders();
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
        child: GlassSurface(
          tier: GlassTier.sheet,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 26),
          edgeColor: AppColorsV2.tertiary,
          edgeIntensity: 0.45,
          accent: AppColorsV2.tertiary,
          shadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 56,
              offset: const Offset(0, 22),
            ),
          ],
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
            final active = i == index;

            // PERF — why this is Offstage and not a cross-fade.
            //
            // The previous version wrapped every tab in AnimatedOpacity +
            // AnimatedScale. An opacity strictly between 0 and 1 forces a
            // saveLayer, and here that layer is the size of the whole screen.
            // A tab switch always has two tabs mid-animation — one fading out,
            // one fading in — so every switch paid for TWO full-screen
            // offscreen buffers for 220 ms. Tap through the tabs quickly and
            // three or four are animating at once. That is the stutter.
            //
            // AnimatedScale cost the rest: RenderTransform pushes a transform
            // layer whether or not the matrix is the identity, so all four
            // tabs carried one permanently.
            //
            // Offstage has neither. The child is not painted, not hit-tested
            // and not in the semantics tree, while its Element and State stay
            // alive — so scroll offsets, controllers and player state survive
            // a switch exactly as before.
            //
            // And no fade either.
            //
            // The incoming tab used to fade in over 150 ms. The trouble is
            // what sits behind it: the outgoing tab is already offstage, so
            // for those 150 ms the new page is translucent over nothing but
            // the ambient background, and the whole screen reads as a dark
            // wash — which looks exactly like a shadow of the page you just
            // left. A cross-fade would fix the look and cost two full-screen
            // layers per switch, which is what this rewrite removed in the
            // first place.
            //
            // So the switch is instant. No layer, no wash, no ghost, and the
            // fastest a tab change can possibly be. Tabs are a place change,
            // not a transition — every native shell switches them instantly.
            return Offstage(
              offstage: !active,
              child: TickerMode(
                // A hidden tab has no business burning frames: this freezes
                // every ticker below it — shimmer loaders, the prayer
                // countdown, the now-playing animations.
                enabled: active,
                child: RepaintBoundary(child: _screens[i]),
              ),
            );
          }),
        ),
      ),
      // The dock is fixed. It does not hide on scroll, and there is no state
      // anywhere that can hide it.
      //
      // Auto-hiding a four-item dock buys a strip of screen roughly one line
      // of text tall, and charges for it in ways that are easy to miss: the
      // primary navigation is missing exactly when someone is deep in a long
      // list and most likely to want to leave it; the reveal is driven by
      // scroll DIRECTION, so an accidental upward flick makes it reappear over
      // whatever was being read; and every scroll notification on three
      // screens had to read and possibly write a provider to keep it in sync.
      //
      // It was also one dropped signal away from disappearing for good. The
      // flag was cleared before opening a modal sheet and restored afterwards
      // behind a `context.mounted` check — so a sheet dismissed as its screen
      // went away left the dock hidden with nothing left to bring it back.
      //
      // A fixed dock has none of that, and the content already reserves room
      // for it at the bottom of every scroll view.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: _SakinaNavBar(
            index: index,
            onSelect: (i) => ref.read(shellIndexProvider.notifier).state = i,
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

/// The liquid glass dock.
///
/// WHAT MAKES THIS READ AS ONE PANE RATHER THAN FOUR BUTTONS
/// --------------------------------------------------------
/// The previous version gave every item its own AnimatedContainer, so the
/// highlight cross-faded: the old one dimmed in place while the new one lit up
/// somewhere else. Nothing moved. Four independent backgrounds fading against
/// each other is what a row of buttons does, and no amount of blur behind it
/// will make that read as a single pane of glass.
///
/// Here there is exactly ONE highlight, and it travels. A single lens slides
/// along the dock to the tapped item, which is the whole illusion: a heavy,
/// viscous thing moving under the surface. Everything else on the dock is
/// deliberately still so that the one moving element carries the eye.
///
/// The lens is built the way real glass layers up, back to front:
///   1. a jade bloom that leads the motion, thrown behind the lens
///   2. the lens body — a vertical jade gradient, lighter at the top
///   3. its own specular rim, brightest along its top edge
/// and it is drawn UNDER the icon row, so the icons sit on the glass rather
/// than inside a button.
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

  static const double _height = 68;
  static const double _inset = 7;

  /// Breathing room between the lens and the slot it sits in.
  static const double _gap = 5;

  /// Long enough to be seen as travel rather than a jump, short enough that a
  /// second tap never feels queued behind the first.
  static const Duration _slide = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    // The dock is the one place a real BackdropFilter always earns its cost:
    // it is pinned above scrolling content, so the blur is what sells it.
    //
    // It stopped selling it for a while, and the shadow was half the reason.
    // A 42%-black drop shadow thirty pixels deep puts a hard dark ring under
    // the dock, and a hard dark ring is what an opaque slab casts. Glass casts
    // something softer and wider, because light gets through it. The shadow
    // below is lighter, spread further and pulled in, so it grounds the island
    // without outlining it.
    return SizedBox(
      height: _height,
      child: GlassSurface(
        tier: GlassTier.overlay,
        radius: 30,
        padding: const EdgeInsets.all(_inset),
        // A bright rim is what carries glass once the fill is thin, so this is
        // roughly double what a card gets.
        edgeIntensity: 0.62,
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 34,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColorsV2.primary.withValues(alpha: 0.06),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 8),
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = _items.length;
            final slot = constraints.maxWidth / count;

            return Stack(
              children: [
                // ── The travelling lens ──────────────────────────────────
                //
                // AnimatedPositioned, not an animated Alignment. Alignment
                // places a child's centre proportionally through the FREE
                // space, not through the full width, so an evenly spaced set
                // of alignment values does not produce evenly spaced slots —
                // the outer two land tens of pixels inside where their icons
                // actually are. Positioning from the measured slot width is
                // exact by construction at any screen size.
                AnimatedPositioned(
                  left: index * slot + _gap / 2,
                  top: 0,
                  bottom: 0,
                  width: slot - _gap,
                  duration: _slide,
                  // easeOutCubic decelerates without overshooting. A springy
                  // curve would make the lens bounce past the icon it is
                  // meant to be selecting, which reads as a mistake rather
                  // than as a flourish.
                  curve: Curves.easeOutCubic,
                  // The lens is passed through untouched, so the frames of
                  // travel move parent data and rebuild nothing.
                  child: const _Lens(),
                ),

                // ── Icons and labels ─────────────────────────────────────
                //
                // Positioned.fill, not a bare Row. A Stack aligns its
                // non-positioned children to the top-start corner, so a Row
                // that shrink-wraps to its icons would sit high in the dock
                // and its tap targets would only cover the upper two thirds.
                // Filling makes each button the full height of the island.
                Positioned.fill(
                  child: Row(
                    // stretch, so each button gets a TIGHT height equal to the
                    // dock's inner height. Without it the buttons would
                    // shrink-wrap their icons and the label's `bottom: 1`
                    // would be measured against a 22-pixel box instead of the
                    // full slot — the label would land on top of the icon.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(count, (i) {
                      return Expanded(
                        child: _NavButton(
                          item: _items[i],
                          selected: i == index,
                          onTap: () {
                            if (i == index) return;
                            HapticFeedback.selectionClick();
                            onSelect(i);
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The moving highlight. Glass on glass.
///
/// Sized by the AnimatedPositioned above it, so it carries no dimensions of
/// its own and can stay const — which is what lets sixty frames of travel
/// rebuild nothing.
class _Lens extends StatelessWidget {
  const _Lens();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(21));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        // Lighter at the top, as a lens lit from above would be. A flat fill
        // here is the difference between a lens and a swatch.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColorsV2.primary.withValues(alpha: 0.30),
            AppColorsV2.primary.withValues(alpha: 0.15),
            AppColorsV2.primary.withValues(alpha: 0.07),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ),
        boxShadow: <BoxShadow>[
          // Negative spread keeps the bloom inside the dock instead of
          // haloing out past the glass edge.
          BoxShadow(
            color: AppColorsV2.primary.withValues(alpha: 0.26),
            blurRadius: 20,
            spreadRadius: -7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // The same rim painter every other glass surface uses. Because the lens
      // is far wider than it is tall, the painter switches its gradient to
      // vertical on its own, and the whole top edge lights up.
      child: const CustomPaint(
        foregroundPainter: SpecularBorderPainter(
          borderRadius: radius,
          intensity: 0.55,
          color: AppColorsV2.primary,
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

/// One destination.
///
/// WHY THE ICON IS CENTRED AND THE LABEL IS AN OVERLAY
/// --------------------------------------------------
/// The obvious layout — a centred Column of icon, gap, label — is what made
/// the icons sit high in the dock, and the arithmetic says exactly why.
///
/// The inner height is 54 (a 68 dock less 7 of padding a side). The Column is
/// icon 22 + gap 3 + label ~14 = 39, so centring it leaves 7.5 above and
/// below and puts the ICON's centre at 18.5 — against a dock centre of 27.
/// Nine pixels high, on a dock only 54 tall.
///
/// It would not matter if every item showed a label, because then every item
/// would be the same shape and the group would read as centred. But the label
/// is only visible on the selected item. Three of the four are a lone icon
/// floating in the upper half, which is precisely what it looked like.
///
/// So the icon is centred on its own, and the label is a positioned overlay
/// that sits below it without taking part in that centring. Two things fall
/// out of it for free: the icons are dead centre whatever is selected, and
/// the icon no longer jumps when the label appears and disappears.
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  static const Duration _dur = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColorsV2.primary
        : AppColorsV2.onSurfaceVariant.withValues(alpha: 0.82);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          // ── Icon, dead centre of the slot ────────────────────────────
          Center(
            // TweenAnimationBuilder with the icon in the `child:` slot: the
            // scale animates without the icon being rebuilt sixty times.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: selected ? 1.08 : 1.0),
              duration: _dur,
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: AnimatedSwitcher(
                duration: _dur,
                // No fade between the outline and filled icons — a cross-fade
                // of two glyphs at the same position looks like a rendering
                // fault. Scaling one out and the other in reads as a state
                // change.
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  key: ValueKey<bool>(selected),
                  size: 22,
                  color: color,
                ),
              ),
            ),
          ),

          // ── Label, pinned under it ───────────────────────────────────
          //
          // Only the colour animates, never the layout. Animating opacity
          // would cost a compositing layer per item; animating colour costs
          // nothing, and animating size would move the icon again — which is
          // the whole thing this layout exists to prevent.
          //
          // height: 1.0 strips the font's line-height slack so the text box is
          // its own 9.5 pixels and not fourteen, which is what keeps it clear
          // of the icon above it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 1,
            child: AnimatedDefaultTextStyle(
              duration: _dur,
              curve: Curves.easeOutCubic,
              textAlign: TextAlign.center,
              style: AppTypeV2.caption(
                size: 9.5,
                weight: FontWeight.w800,
                color: selected
                    ? AppColorsV2.primary
                    : AppColorsV2.primary.withValues(alpha: 0),
              ).copyWith(height: 1.0),
              child: Text(
                item.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
