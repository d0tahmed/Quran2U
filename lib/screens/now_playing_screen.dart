import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

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
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.985, end: 1.0).animate(
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
    final isActive = ref.watch(shellIndexProvider) == 1;

    final audioPlayer = ref.watch(audioPlayerServiceProvider);
    final interleavedSvc = ref.watch(interleavedAudioServiceProvider);
    final tarjumahMode = ref.watch(tarjumahModeProvider);
    final selectedImam = ref.watch(selectedImamProvider);
    final surahNumber = ref.watch(currentSurahProvider);
    final surahsAsync = ref.watch(surahsProvider);

    // Only watch fast-updating streams when this tab is active.
    // When inactive, use ref.read to freeze the last state and stop 60fps rebuilds.
    final posAsync =
        isActive ? ref.watch(positionProvider) : ref.read(positionProvider);
    final durAsync =
        isActive ? ref.watch(durationProvider) : ref.read(durationProvider);

    final isPlaying = tarjumahMode
        ? interleavedSvc.player.playing
        : audioPlayer.player.playing;

    final currentAyah = tarjumahMode
        ? (isActive
            ? ref.watch(currentAyahNumberProvider).asData?.value
            : ref.read(currentAyahNumberProvider).asData?.value)
        : null;

    final isTranslationPlaying = tarjumahMode
        ? (isActive
            ? (ref.watch(isUrduSegmentProvider).asData?.value ?? false)
            : (ref.read(isUrduSegmentProvider).asData?.value ?? false))
        : false;
    final translationLangName =
        ref.watch(interleavedAudioServiceProvider).activeMode.name == 'english'
            ? 'English'
            : 'Urdu';

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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text('NOW LISTENING', style: AppTypeV2.overline(size: 10.5)),
            const SizedBox(height: 10),
            const QOrnamentDivider(width: 96),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isShort = constraints.maxHeight < 560;
                  final artSize = (constraints.maxWidth.clamp(180.0, 260.0))
                      .clamp(180.0, isShort ? 180.0 : 224.0)
                      .toDouble();

                  return Column(
                    children: [
                      const Spacer(flex: 1),

                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: isPlaying ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: _MedallionArt(
                          surah: surah,
                          surahNumber: surahNumber,
                          progress: progress,
                          size: artSize,
                        ),
                      ),

                      SizedBox(height: isShort ? 14 : 22),

                      AnimatedOpacity(
                        opacity: isPlaying ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: SizedBox(
                          height: isShort ? 16 : 20,
                          child: _EqualizerBars(isPlaying: isPlaying),
                        ),
                      ),

                      const Spacer(flex: 2),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: GlassPanel(
                          borderRadius: BorderRadius.circular(34),
                          padding: isShort
                              ? const EdgeInsets.fromLTRB(18, 14, 18, 12)
                              : const EdgeInsets.fromLTRB(22, 18, 22, 16),
                          tint: AppColorsV2.surface,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (surah != null) ...[
                                Text(
                                  surah.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypeV2.display(
                                      size: isShort ? 22 : 26),
                                ),
                                SizedBox(height: isShort ? 4 : 6),
                                if (tarjumahMode)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColorsV2.tertiary
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color:
                                                  AppColorsV2.goldHairline),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isTranslationPlaying
                                                  ? Icons.translate_rounded
                                                  : Icons
                                                      .record_voice_over_rounded,
                                              color: AppColorsV2.tertiary,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isTranslationPlaying
                                                  ? translationLangName
                                                  : 'Arabic',
                                              maxLines: 1,
                                              style: AppTypeV2.caption(
                                                size: 10.5,
                                                color: AppColorsV2.tertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          currentAyah != null
                                              ? 'Ayah $currentAyah of ${surah.ayahCount}'
                                              : 'Tarjumah Mode',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypeV2.caption(
                                            size: isShort ? 10.5 : 11.5,
                                            color:
                                                AppColorsV2.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    selectedImam?.name ?? 'Select reciter',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypeV2.caption(
                                      size: isShort ? 11 : 12,
                                      color: AppColorsV2.onSurfaceVariant,
                                    ),
                                  ),
                              ] else ...[
                                Text(
                                  'Nothing playing yet',
                                  style: AppTypeV2.title(
                                      size: isShort ? 15 : 16,
                                      color: AppColorsV2.onSurfaceVariant,
                                      weight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose a surah from Home to begin.',
                                  style: AppTypeV2.caption(
                                      size: 11,
                                      color: AppColorsV2.onSurfaceVariant
                                          .withValues(alpha: 0.7)),
                                ),
                              ],

                              SizedBox(height: isShort ? 12 : 16),

                              // time labels + progress
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_fmt(pos),
                                      style: AppTypeV2.caption(
                                          size: 10.5,
                                          color:
                                              AppColorsV2.onSurfaceVariant)),
                                  Text(dur != null ? _fmt(dur) : '00:00',
                                      style: AppTypeV2.caption(
                                          size: 10.5,
                                          color:
                                              AppColorsV2.onSurfaceVariant)),
                                ],
                              ),
                              SizedBox(height: isShort ? 6 : 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: AppColorsV2.surfaceHighest,
                                  valueColor: const AlwaysStoppedAnimation<
                                      Color>(AppColorsV2.primary),
                                ),
                              ),
                              SizedBox(height: isShort ? 10 : 14),

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
                                            ref
                                                .read(currentSurahProvider
                                                    .notifier)
                                                .state = surahNumber - 1;
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
                                            if (mounted) {
                                              setState(() {});
                                            }
                                            return;
                                          }

                                          if (tarjumahMode) {
                                            await audioPlayer.player.stop();
                                            final imam = ref
                                                .read(selectedImamProvider);
                                            final sNum = ref
                                                .read(currentSurahProvider);
                                            final surahs = ref
                                                    .read(surahsProvider)
                                                    .asData
                                                    ?.value ??
                                                [];
                                            final s = surahs
                                                .cast<Surah?>()
                                                .firstWhere(
                                                    (s) => s?.number == sNum,
                                                    orElse: () => null);
                                            if (sNum != null && s != null) {
                                              await interleavedSvc
                                                  .buildAndPlay(
                                                surahNumber: sNum,
                                                ayahCount: s.ayahCount,
                                                imamId: imam?.id ?? 1,
                                              );
                                            }
                                          } else {
                                            await interleavedSvc.player.stop();
                                            if (audioUrl.isNotEmpty) {
                                              if (audioPlayer.currentUrl ==
                                                  audioUrl) {
                                                await audioPlayer.play();
                                              } else {
                                                await audioPlayer
                                                    .loadAndPlay(audioUrl);
                                              }
                                            }
                                          }

                                          if (mounted) {
                                            setState(() {});
                                          }
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
                                            ref
                                                .read(currentSurahProvider
                                                    .notifier)
                                                .state = surahNumber + 1;
                                          }
                                        },
                                      ),
                                    ],
                                  );

                                  Widget loopButton({bool compact = false}) {
                                    final isLoop = ref.watch(loopProvider);
                                    return IconButton(
                                      visualDensity: compact
                                          ? VisualDensity.compact
                                          : VisualDensity.standard,
                                      constraints: compact
                                          ? const BoxConstraints.tightFor(
                                              width: 40, height: 40)
                                          : null,
                                      onPressed: tarjumahMode
                                          ? null
                                          : () {
                                              final newVal = !isLoop;
                                              ref
                                                  .read(loopProvider.notifier)
                                                  .state = newVal;
                                              audioPlayer.setLoopMode(newVal);
                                            },
                                      icon: Icon(
                                        Icons.repeat_rounded,
                                        size: 20,
                                        color: tarjumahMode
                                            ? AppColorsV2.onSurfaceVariant
                                                .withValues(alpha: 0.3)
                                            : (isLoop
                                                ? AppColorsV2.primary
                                                : AppColorsV2
                                                    .onSurfaceVariant),
                                      ),
                                    );
                                  }

                                  if (isTight) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(child: centerControls),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            loopButton(compact: true)
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 40),
                                      centerControls,
                                      loopButton(),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Medallion art — Arabic surah name inside a gold star frame with a thin
// jade progress ring around it.
// ─────────────────────────────────────────────────────────────────────────────

class _MedallionArt extends StatelessWidget {
  final Surah? surah;
  final int? surahNumber;
  final double progress;
  final double size;

  const _MedallionArt({
    required this.surah,
    required this.surahNumber,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: surahNumber != null ? progress : 0,
              strokeWidth: 3,
              backgroundColor: AppColorsV2.surfaceHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColorsV2.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Gold star frames
          CustomPaint(
            size: Size.square(size - 30),
            painter: const EightPointStarPainter(
              color: AppColorsV2.goldHairline,
              strokeWidth: 1.2,
            ),
          ),
          CustomPaint(
            size: Size.square(size - 58),
            painter: EightPointStarPainter(
              color: AppColorsV2.tertiary.withValues(alpha: 0.35),
              strokeWidth: 1.0,
            ),
          ),
          if (surah != null)
            Padding(
              padding: EdgeInsets.all(size * 0.24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  surah!.nameArabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTypeV2.arabic(
                    size: 40,
                    color: AppColorsV2.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else if (surahNumber != null)
            Text('$surahNumber', style: AppTypeV2.display(size: 44))
          else
            Icon(Icons.headphones_rounded,
                color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.25),
                size: size * 0.3),
        ],
      ),
    );
  }
}

class _BigCtrlBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _BigCtrlBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon,
            size: 36,
            color: enabled
                ? AppColorsV2.onSurface
                : AppColorsV2.onSurfaceVariant.withValues(alpha: 0.3)),
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
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColorsV2.primary, AppColorsV2.primaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorsV2.primary.withValues(alpha: 0.25),
              blurRadius: 34,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 40,
          color: AppColorsV2.onPrimary,
        ),
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

class _EqualizerBarsState extends State<_EqualizerBars>
    with TickerProviderStateMixin {
  static const _barCount = 5;
  static const _durations = [320, 450, 380, 500, 360];
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      _barCount,
      (i) => AnimationController(
          vsync: this, duration: Duration(milliseconds: _durations[i]))
        ..repeat(reverse: true),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0.15, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    if (!widget.isPlaying) {
      for (final c in _ctrls) {
        c.stop();
      }
    }
  }

  @override
  void didUpdateWidget(_EqualizerBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        for (final c in _ctrls) {
          c.repeat(reverse: true);
        }
      } else {
        for (final c in _ctrls) {
          c.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
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
              width: 3,
              height: 20.0 * _anims[i].value,
              decoration: BoxDecoration(
                color: AppColorsV2.tertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
