import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;
const _kSlate = AppColorsV2.surface; // glass tint base

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

    final pos = posAsync.asData?.value ?? Duration.zero;
    final dur = durAsync.asData?.value;
    final progress = (dur != null && dur.inMilliseconds > 0)
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Soft background glow blobs like Stitch
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.20,
            left: -120,
            right: -120,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kGreen.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Text(
                        'NOW PLAYING',
                        style: GoogleFonts.manrope(
                          color: _kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isShort = constraints.maxHeight < 620;
                        final discSize = (constraints.maxWidth
                                .clamp(240.0, 320.0))
                            .clamp(240.0, isShort ? 260.0 : 320.0)
                            .toDouble();

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Big disc / circular progress (auto compact on short screens)
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, child) => Transform.scale(
                                scale: isPlaying ? _pulseAnim.value : 1.0,
                                child: child,
                              ),
                              child: _ProgressDisc(
                                surahNumber: surahNumber,
                                progress: progress,
                                isPlaying: isPlaying,
                                size: discSize,
                              ),
                            ),

                            SizedBox(height: isShort ? 10 : 18),
                            AnimatedOpacity(
                              opacity: isPlaying ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: SizedBox(
                                height: isShort ? 18 : 24,
                                child: _EqualizerBars(isPlaying: isPlaying),
                              ),
                            ),
                            SizedBox(height: isShort ? 10 : 18),

                            // Glass player card (Stitch) — compact padding/fonts on short screens
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: GlassPanel(
                                borderRadius: BorderRadius.circular(40),
                                padding: isShort
                                    ? const EdgeInsets.fromLTRB(18, 14, 18, 14)
                                    : const EdgeInsets.fromLTRB(22, 18, 22, 18),
                                tint: _kSlate,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                          if (surah != null) ...[
                            Text(
                              surah.nameArabic,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isShort ? 34 : 40,
                                color: AppColorsV2.onSurface,
                                height: 1.35,
                                fontFamily: GoogleFonts.amiri().fontFamily,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              surah.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                color: _kGreen,
                                fontSize: isShort ? 18 : 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: isShort ? 4 : 6),
                            if (tarjumahMode)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _kGold.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _kGold.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(isUrdu ? Icons.translate_rounded : Icons.record_voice_over_rounded, color: _kGold, size: 13),
                                        const SizedBox(width: 5),
                                        Text(
                                          isUrdu ? 'Urdu' : 'Arabic',
                                          style: GoogleFonts.manrope(color: _kGold, fontSize: 11, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    currentAyah != null ? 'Ayah $currentAyah of ${surah.ayahCount}' : 'Tarjumah Mode',
                                    style: GoogleFonts.manrope(color: Colors.white54, fontSize: isShort ? 11 : 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              )
                            else
                              Text(
                                selectedImam?.name ?? 'Select reciter',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  color: AppColorsV2.onSurfaceVariant,
                                  fontSize: isShort ? 12 : 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ] else ...[
                            Text(
                              'No Surah Selected',
                              style: GoogleFonts.manrope(
                                color: Colors.white54,
                                fontSize: isShort ? 16 : 18,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          ],

                          SizedBox(height: isShort ? 12 : 18),
                          // time labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos), style: GoogleFonts.manrope(color: AppColorsV2.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
                              Text(dur != null ? _fmt(dur) : '00:00', style: GoogleFonts.manrope(color: AppColorsV2.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
                            ],
                          ),
                          SizedBox(height: isShort ? 6 : 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: isShort ? 5 : 6,
                              backgroundColor: AppColorsV2.surfaceHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.lerp(AppColorsV2.primaryContainer, _kGreen, 0.6) ?? _kGreen,
                              ),
                            ),
                          ),
                          SizedBox(height: isShort ? 12 : 18),

                          LayoutBuilder(
                            builder: (context, c) {
                              final isTight = c.maxWidth < 360;
                              final centerControls = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _BigCtrlBtn(
                                    icon: Icons.skip_previous_rounded,
                                    enabled: (surahNumber ?? 0) > 1,
                                    onTap: () async {
                                      if (tarjumahMode) {
                                        await audioPlayer.player.stop();
                                        await interleavedSvc.pause();
                                      } else {
                                        await interleavedSvc.player.stop();
                                        await audioPlayer.pause();
                                      }
                                      if (surahNumber != null) {
                                        ref.read(currentSurahProvider.notifier).state =
                                            surahNumber - 1;
                                      }
                                    },
                                  ),
                                  SizedBox(width: isTight ? 8 : 14),
                                  _PlayPauseBtn(
                                    isPlaying: isPlaying,
                                    onTap: () async {
                                      if (isPlaying) {
                                        if (tarjumahMode) {
                                          await interleavedSvc.pause();
                                        } else {
                                          await audioPlayer.pause();
                                        }
                                        if (mounted) setState(() {});
                                        return;
                                      }

                                      if (tarjumahMode) {
                                        await audioPlayer.player.stop();
                                        final imam = ref.read(selectedImamProvider);
                                        final sNum = ref.read(currentSurahProvider);
                                        final surahs =
                                            ref.read(surahsProvider).asData?.value ?? [];
                                        final s = surahs
                                            .cast<Surah?>()
                                            .firstWhere((s) => s?.number == sNum, orElse: () => null);
                                        if (sNum != null && s != null) {
                                          await interleavedSvc.buildAndPlay(
                                            surahNumber: sNum,
                                            ayahCount: s.ayahCount,
                                            imamId: imam?.id ?? 1,
                                          );
                                        }
                                      } else {
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
                                    },
                                  ),
                                  SizedBox(width: isTight ? 8 : 14),
                                  _BigCtrlBtn(
                                    icon: Icons.skip_next_rounded,
                                    enabled: (surahNumber ?? 115) < 114,
                                    onTap: () async {
                                      if (tarjumahMode) {
                                        await audioPlayer.player.stop();
                                        await interleavedSvc.pause();
                                      } else {
                                        await interleavedSvc.player.stop();
                                        await audioPlayer.pause();
                                      }
                                      if (surahNumber != null) {
                                        ref.read(currentSurahProvider.notifier).state =
                                            surahNumber + 1;
                                      }
                                    },
                                  ),
                                ],
                              );

                              final sideActions = Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                                    onPressed: tarjumahMode
                                        ? null
                                        : () {
                                            // "shuffle" icon in Stitch; keeping as placeholder for future playlist.
                                          },
                                    icon: Icon(
                                      Icons.shuffle_rounded,
                                      size: 20,
                                      color: Colors.white.withValues(alpha: tarjumahMode ? 0.18 : 0.55),
                                    ),
                                  ),
                                  Builder(builder: (ctx) {
                                    final isLoop = ref.watch(loopProvider);
                                    return IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                                      onPressed: tarjumahMode
                                          ? null
                                          : () {
                                              final newVal = !isLoop;
                                              ref.read(loopProvider.notifier).state = newVal;
                                              audioPlayer.setLoopMode(newVal);
                                            },
                                      icon: Icon(
                                        Icons.repeat_rounded,
                                        size: 20,
                                        color: tarjumahMode ? Colors.white24 : (isLoop ? _kGreen : Colors.white54),
                                      ),
                                    );
                                  }),
                                ],
                              );

                              if (isTight) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(child: centerControls),
                                    const SizedBox(height: 8),
                                    sideActions,
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: tarjumahMode
                                        ? null
                                        : () {
                                            // "shuffle" icon in Stitch; keeping as placeholder for future playlist.
                                          },
                                    icon: Icon(Icons.shuffle_rounded, color: Colors.white.withValues(alpha: tarjumahMode ? 0.18 : 0.55)),
                                  ),
                                  centerControls,
                                  Builder(builder: (ctx) {
                                    final isLoop = ref.watch(loopProvider);
                                    return IconButton(
                                      onPressed: tarjumahMode
                                          ? null
                                          : () {
                                              final newVal = !isLoop;
                                              ref.read(loopProvider.notifier).state = newVal;
                                              audioPlayer.setLoopMode(newVal);
                                            },
                                      icon: Icon(Icons.repeat_rounded, color: tarjumahMode ? Colors.white24 : (isLoop ? _kGreen : Colors.white54)),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDisc extends StatelessWidget {
  final int? surahNumber;
  final double progress;
  final bool isPlaying;
  final double? size;
  const _ProgressDisc({
    required this.surahNumber,
    required this.progress,
    required this.isPlaying,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? MediaQuery.sizeOf(context).width.clamp(260, 320).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: surahNumber != null ? progress : 0,
              strokeWidth: 4,
              backgroundColor: AppColorsV2.surfaceHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(_kGreen),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: size - 24,
            height: size - 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kGreen.withValues(alpha: 0.12), width: 1.5),
              gradient: RadialGradient(
                colors: [
                  _kGreen.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (surahNumber != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'سورة',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: (size * 0.115).clamp(20, 30),
                    fontFamily: GoogleFonts.amiri().fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  surahNumber!.toString().padLeft(3, '0'),
                  style: GoogleFonts.manrope(
                    color: AppColorsV2.onSurface,
                    fontSize: (size * 0.245).clamp(44, 64),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
              ],
            )
          else
            const Icon(Icons.headphones_rounded, color: Colors.white12, size: 92),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kGreen.withValues(alpha: 0.10), width: 4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigCtrlBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _BigCtrlBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 38, color: enabled ? AppColorsV2.onSurface : Colors.white24),
      );
}

class _PlayPauseBtn extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _PlayPauseBtn({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColorsV2.primary, AppColorsV2.primaryContainer],
          ),
          boxShadow: [
            BoxShadow(color: _kGreen.withValues(alpha: 0.30), blurRadius: 40),
          ],
        ),
        child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 42, color: const Color(0xFF00311F)),
      ),
    );
  }
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
                color: _kGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
