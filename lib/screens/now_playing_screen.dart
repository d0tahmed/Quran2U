import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';

const _kGreen = Color(0xFF10B981);
const _kGold = Color(0xFFEAB308);
const _kBg = Color(0xFF05080F);
const _kSlate = Color(0xFF0F172A); // Native solid dark color (No GPU blur)

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = ref.watch(audioPlayerServiceProvider);
    final interleavedSvc = ref.watch(interleavedAudioServiceProvider);
    final tarjumahMode = ref.watch(tarjumahModeProvider);
    final selectedImam = ref.watch(selectedImamProvider);
    final surahNumber = ref.watch(currentSurahProvider);
    final surahsAsync = ref.watch(surahsProvider);
    final posAsync = ref.watch(positionProvider);
    final durAsync = ref.watch(durationProvider);
    
    final isPlaying = tarjumahMode
        ? interleavedSvc.player.playing
        : audioPlayer.player.playing;
        
    final currentAyah = tarjumahMode
        ? ref.watch(currentAyahNumberProvider).asData?.value
        : null;
        
    final isUrdu = tarjumahMode
        ? (ref.watch(isUrduSegmentProvider).asData?.value ?? false)
        : false;

    final surah = surahsAsync.asData?.value
        .cast<Surah?>()
        .firstWhere((s) => s?.number == surahNumber, orElse: () => null);

    final audioUrl = (!tarjumahMode && surahNumber != null)
        ? ref.watch(audioUrlProvider((surahNumber, selectedImam?.id ?? 1)))
        : '';

    final shouldPulse = isPlaying;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPlaying
                ? [const Color(0xFF092A1A), _kBg]
                : [_kBg, _kBg],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text('NOW PLAYING',
                      style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600)),
                ),

                const Spacer(flex: 2),

                if (surahNumber != null)
                  Expanded(
                    flex: 8,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                          scale: isPlaying ? _pulseAnim.value : 1.0,
                          child: child),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              _kGreen.withValues(alpha: 0.12),
                              Colors.transparent,
                            ]),
                            border: Border.all(
                                color: _kGreen.withValues(alpha: 0.15), width: 1.5),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  surahNumber.toString().padLeft(3, '0'),
                                  style: GoogleFonts.outfit(
                                      color: _kGreen,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2),
                                ),
                                Text('سورة',
                                    style: TextStyle(
                                        color: _kGold.withValues(alpha: 0.8),
                                        fontSize: 22,
                                        fontFamily: GoogleFonts.amiri().fontFamily)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 8,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(Icons.headphones_rounded,
                            color: Colors.white12, size: 80),
                      ),
                    ),
                  ),

                const Spacer(flex: 1),

                AnimatedOpacity(
                  opacity: isPlaying ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    height: 24,
                    child: _EqualizerBars(isPlaying: isPlaying),
                  ),
                ),

                const Spacer(flex: 1),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _kSlate,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      if (surah != null) ...[
                        _MarqueeWidget(
                          child: Text(
                            surah.nameArabic,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontSize: 32,
                                color: _kGold,
                                fontFamily: GoogleFonts.amiri().fontFamily,
                                height: 1.2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _MarqueeWidget(
                          child: Text(surah.name,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        _MarqueeWidget(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (tarjumahMode) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _kGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isUrdu ? Icons.translate_rounded : Icons.record_voice_over_rounded,
                                          color: _kGold, size: 11,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isUrdu ? 'Urdu' : 'Arabic',
                                          style: GoogleFonts.outfit(
                                              color: _kGold, fontSize: 10, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentAyah != null
                                        ? 'Ayah $currentAyah of ${surah.ayahCount}'
                                        : 'Tarjumah Mode',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54, fontSize: 12),
                                  ),
                                ] else ...[
                                  const Icon(Icons.person_outline_rounded,
                                      color: Colors.white54, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedImam != null
                                        ? selectedImam.name
                                        : 'Select reciter',
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ]),
                        ),
                      ] else ...[
                        Text('No Surah Selected',
                            style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 18,
                                fontWeight: FontWeight.w500)),
                      ],

                      const SizedBox(height: 16),

                      posAsync.when(
                        data: (pos) => durAsync.when(
                          data: (dur) => Theme(
                            data: Theme.of(context).copyWith(
                                sliderTheme: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                )),
                            child: Slider(
                              value: (dur != null && dur.inMilliseconds > 0)
                                  ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                                  : 0.0,
                              onChanged: (v) {
                                if (dur != null) {
                                  audioPlayer.seek(Duration(
                                      milliseconds: (v * dur.inMilliseconds).toInt()));
                                }
                              },
                            ),
                          ),
                          loading: () => const SizedBox(height: 20),
                          error: (_, __) => const SizedBox(height: 20),
                        ),
                        loading: () => const SizedBox(height: 20),
                        error: (_, __) => const SizedBox(height: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              posAsync.asData?.value != null ? _fmt(posAsync.asData!.value) : '00:00',
                              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                            ),
                            Text(
                              durAsync.asData?.value != null ? _fmt(durAsync.asData!.value!) : '00:00',
                              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Centered controls: prev, play/pause, next
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CtrlBtn(
                                icon: Icons.skip_previous_rounded,
                                size: 32,
                                enabled: (surahNumber ?? 0) > 1,
                                onTap: () async {
                                  if (tarjumahMode) {
                                    await audioPlayer.player.stop(); // SENIOR FIX
                                    await interleavedSvc.pause();
                                  } else {
                                    await interleavedSvc.player.stop(); // SENIOR FIX
                                    await audioPlayer.pause();
                                  }
                                  if (surahNumber != null) {
                                    ref.read(currentSurahProvider.notifier).state = surahNumber - 1;
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () async {
                                  if (isPlaying) {
                                    if (tarjumahMode) {
                                      await interleavedSvc.pause();
                                    } else {
                                      await audioPlayer.pause();
                                    }
                                    if (mounted) setState(() {});
                                  } else {
                                    if (tarjumahMode) {
                                      // SENIOR FIX: Force opposite player to release the lock!
                                      await audioPlayer.player.stop(); 
                                      final imam = ref.read(selectedImamProvider);
                                      final sNum = ref.read(currentSurahProvider);
                                      final surahs = ref.read(surahsProvider).asData?.value ?? [];
                                      final s = surahs.cast<Surah?>().firstWhere((s) => s?.number == sNum, orElse: () => null);
                                      if (sNum != null && s != null) {
                                        await interleavedSvc.buildAndPlay(surahNumber: sNum, ayahCount: s.ayahCount, imamId: imam?.id ?? 1);
                                      }
                                    } else {
                                      // SENIOR FIX: Force opposite player to release the lock!
                                      await interleavedSvc.player.stop(); 
                                      if (audioUrl.isNotEmpty) {
                                        if (audioPlayer.currentUrl == audioUrl) {
                                          await audioPlayer.play();
                                        } else {
                                          await audioPlayer.loadAndPlay(audioUrl);
                                        }
                                      }
                                    }
                                    if (mounted) setState(() {}); 
                                  }
                                },
                                child: Container(
                                  width: 64, 
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kGreen,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _CtrlBtn(
                                icon: Icons.skip_next_rounded,
                                size: 32,
                                enabled: (surahNumber ?? 115) < 114,
                                onTap: () async {
                                  if (tarjumahMode) {
                                    await audioPlayer.player.stop(); // SENIOR FIX
                                    await interleavedSvc.pause();
                                  } else {
                                    await interleavedSvc.player.stop(); // SENIOR FIX
                                    await audioPlayer.pause();
                                  }
                                  if (surahNumber != null) {
                                    ref.read(currentSurahProvider.notifier).state = surahNumber + 1;
                                  }
                                },
                              ),
                            ],
                          ),
                          // Loop button pinned to the right corner
                          Positioned(
                            right: 0,
                            child: Builder(builder: (ctx) {
                              final isLoop = ref.watch(loopProvider);
                              return IconButton(
                                icon: Icon(
                                  Icons.repeat_rounded,
                                  color: tarjumahMode
                                      ? Colors.white24
                                      : isLoop
                                          ? _kGreen
                                          : Colors.white38,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: tarjumahMode
                                    ? null
                                    : () {
                                        final newVal = !isLoop;
                                        ref.read(loopProvider.notifier).state = newVal;
                                        audioPlayer.setLoopMode(newVal);
                                      },
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback? onTap;

  const _CtrlBtn({required this.icon, required this.size, this.enabled = true, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: enabled ? Colors.white70 : Colors.white24, size: size),
        onPressed: enabled ? onTap : null,
      );
}

class _EqualizerBars extends StatefulWidget {
  final bool isPlaying;
  const _EqualizerBars({required this.isPlaying});
  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars> with TickerProviderStateMixin {
  static const _barCount = 5;
  static const _durations = [320, 450, 380, 500, 360];
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      _barCount,
      (i) => AnimationController(vsync: this, duration: Duration(milliseconds: _durations[i]))..repeat(reverse: true),
    );
    _anims = _ctrls.map((c) => Tween<double>(begin: 0.15, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    
    if (!widget.isPlaying) {
      for (var c in _ctrls) {
        c.stop();
      }
    }
  }
@override
  void didUpdateWidget(_EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        for (var c in _ctrls) {
          c.repeat(reverse: true);
        }
      } else {
        for (var c in _ctrls) {
          c.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_barCount, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 4.0,
              height: 24.0 * _anims[i].value,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}

class _MarqueeWidget extends StatelessWidget {
  final Widget child;
  const _MarqueeWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: child,
    );
  }
}