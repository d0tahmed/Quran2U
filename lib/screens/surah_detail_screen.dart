import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/services/download_service.dart';
import 'package:quran_recitation/services/interleaved_audio_service.dart'; // Added to access TranslationMode
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';
import 'package:uuid/uuid.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;

class SurahDetailScreen extends ConsumerStatefulWidget {
  final Surah surah;
  const SurahDetailScreen({required this.surah, super.key});

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  final _scrollCtrl = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};

  bool _isRecDownloaded = false;
  bool _isUrduDownloaded = false;
  bool _isDownloading = false;
  double _dlProgress = 0.0;
  String _dlStatus = '';
  final _dlService = DownloadService();

  GlobalKey _keyFor(int ayahNum) =>
      _ayahKeys.putIfAbsent(ayahNum, () => GlobalKey());

  void _scrollToAyah(int ayahNum) {
    final key = _ayahKeys[ayahNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentSurahProvider.notifier).state = widget.surah.number;
      _checkDownloadStatus();
    });
  }

  Future<void> _checkDownloadStatus() async {
    final imam = ref.read(selectedImamProvider);
    if (imam == null) return;
    final rec = await _dlService.isRecitationDownloaded(widget.surah.number, imam.id);
    final urdu = await _dlService.isTarjumahDownloaded(widget.surah.number, imam.id);
    if (mounted) setState(() { _isRecDownloaded = rec; _isUrduDownloaded = urdu; });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSurah = ref.watch(currentSurahProvider);
    final surahNumber = globalSurah ?? widget.surah.number;
    final translationId = ref.watch(selectedTranslationProvider);
    final ayahsAsync = ref.watch(surahAyahsProvider((surahNumber, translationId)));
    final bookmarks = ref.watch(bookmarksProvider);
    final audioPlayer = ref.watch(audioPlayerServiceProvider);
    final tarjumahMode = ref.watch(tarjumahModeProvider);
    final interleavedSvc = ref.watch(interleavedAudioServiceProvider);

    final isPlaying = tarjumahMode
        ? interleavedSvc.player.playing
        : audioPlayer.player.playing;

    if (tarjumahMode) {
      ref.listen(currentAyahNumberProvider, (_, next) {
        final ayah = next.asData?.value;
        if (ayah != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAyah(ayah));
        }
      });
    }

    final allSurahs = ref.watch(surahsProvider).asData?.value ?? [];
    final currentSurahData = allSurahs.cast<Surah?>().firstWhere(
        (s) => s?.number == surahNumber,
        orElse: () => widget.surah) ?? widget.surah;

    isPlaying ? _pulseCtrl.repeat(reverse: true) : _pulseCtrl.stop();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildSurahHeader(context, currentSurahData),
              Expanded(
                child: ayahsAsync.when(
                  data: (ayahs) =>
                      _buildAyahList(ayahs, bookmarks, currentSurahData),
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: _kGreen)),
                  error: (e, _) => Center(
                    child: Text(
                      'Error: $e',
                      style: GoogleFonts.manrope(color: Colors.white54),
                    ),
                  ),
                ),
              ),
              // Space for the mini playback bar.
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 92),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 10,
            child: _MiniPlaybackBar(
              surah: currentSurahData,
              tarjumahMode: tarjumahMode,
              onDownloadTap: () {
                final imam = ref.read(selectedImamProvider);
                if (imam == null) return;
                _showDownloadSheet(context, surahNumber, imam);
              },
              onPlayPauseTap: () async {
                final audioPlayer = ref.read(audioPlayerServiceProvider);
                final interleavedSvc = ref.read(interleavedAudioServiceProvider);
                final selectedImam = ref.read(selectedImamProvider);
                final audioUrl = ref.read(audioUrlProvider((
                  surahNumber,
                  selectedImam?.id ?? 1,
                )));

                final currentlyPlaying = tarjumahMode
                    ? interleavedSvc.player.playing
                    : audioPlayer.player.playing;

                if (currentlyPlaying) {
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
                  await interleavedSvc.buildAndPlay(
                    surahNumber: surahNumber,
                    ayahCount: widget.surah.ayahCount,
                    imamId: imam?.id ?? 1,
                  );
                } else {
                  await interleavedSvc.player.stop();
                  if (audioPlayer.currentUrl == audioUrl) {
                    await audioPlayer.play();
                  } else {
                    await audioPlayer.loadAndPlay(
                      audioUrl,
                      surahNumber: surahNumber,
                      imamId: selectedImam?.id,
                    );
                  }
                }
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(BuildContext context, Surah surah) {
    return Container(
      color: _kBg.withValues(alpha: 0.85),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${surah.name} (${surah.nameTranslation})',
                      style: GoogleFonts.manrope(
                        color: AppColorsV2.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _TagPill(text: '${surah.ayahCount} Verses', color: _kGold),
                        const SizedBox(width: 8),
                        _TagPill(text: surah.revelationType, color: AppColorsV2.secondary),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                surah.nameArabic,
                style: TextStyle(
                  fontSize: 24,
                  color: _kGreen,
                  fontFamily: GoogleFonts.amiri().fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyahList(List<Ayah> ayahs, List<Bookmark> bookmarks, Surah surah) {
    final tarjumahMode = ref.watch(tarjumahModeProvider);
    final playingAyah = tarjumahMode
        ? ref.watch(currentAyahNumberProvider).asData?.value
        : null;
        
    // Grab the active translation state (Urdu or English)
    final isTranslationSegmentActive = tarjumahMode
        ? (ref.watch(isUrduSegmentProvider).asData?.value ?? false)
        : false;

    // Check which language is active from the audio service
    final activeAudioMode = ref.read(interleavedAudioServiceProvider).activeMode;
    final isEnglishMode = activeAudioMode == TranslationMode.english;

    final showBismillah = surah.number != 1 && surah.number != 9;
    final headerCount = showBismillah ? 1 : 0;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      itemCount: ayahs.length + headerCount,
      itemBuilder: (ctx, i) {
        if (showBismillah && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            child: Column(
              children: [
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    height: 2.2,
                    color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.9),
                    fontFamily: GoogleFonts.amiri().fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 72,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColorsV2.outlineVariant.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final ayah = ayahs[i - headerCount];
        final isBookmarked = bookmarks.any((b) =>
            b.surahNumber == surah.number &&
            b.ayahNumber == ayah.numberInSurah);
            
        final isCurrentAyah = tarjumahMode && playingAyah == ayah.numberInSurah;
        
        return KeyedSubtree(
          key: _keyFor(ayah.numberInSurah),
          child: _VerseCard(
            ayah: ayah,
            isBookmarked: isBookmarked,
            isActive: isCurrentAyah,
            // Pass the dynamic states down to the verse card
            isTranslationSegment: isCurrentAyah && isTranslationSegmentActive,
            isEnglishAudio: isEnglishMode,
            onBookmarkToggle: () => _toggleAyahBookmark(ayah, isBookmarked, surah),
          ),
        );
      },
    );
  }

  void _toggleAyahBookmark(Ayah ayah, bool isBookmarked, Surah surah) {
    final bks = ref.read(bookmarksProvider);
    if (isBookmarked) {
      ref.read(bookmarksProvider.notifier).updateBookmarks(bks
          .where((b) => !(b.surahNumber == surah.number &&
              b.ayahNumber == ayah.numberInSurah))
          .toList());
    } else {
      ref.read(bookmarksProvider.notifier).updateBookmarks([
        ...bks,
        Bookmark(
          id: const Uuid().v4(),
          surahNumber: surah.number,
          ayahNumber: ayah.numberInSurah,
          title: '${surah.name} – Ayah ${ayah.numberInSurah}',
          createdAt: DateTime.now(),
        ),
      ]);
    }
  }

  void _showDownloadSheet(
      BuildContext context, int surahNumber, Imam imam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1421),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _DownloadSheet(
        surah: widget.surah,
        imam: imam,
        isRecDownloaded: _isRecDownloaded,
        isUrduDownloaded: _isUrduDownloaded,
        onDownloadRecitation: () {
          Navigator.pop(ctx);
          _startDownloadRecitation(surahNumber, imam);
        },
        onDownloadWithUrdu: () {
          Navigator.pop(ctx);
          _startDownloadWithUrdu(surahNumber, imam);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          await _dlService.deleteDownload(surahNumber, imam.id);
          ref.invalidate(downloadedSurahsProvider);
          if (mounted) setState(() { _isRecDownloaded = false; _isUrduDownloaded = false; });
        },
      ),
    );
  }

  void _startDownloadRecitation(int surahNumber, Imam imam) {
    setState(() { _isDownloading = true; _dlProgress = 0; _dlStatus = 'Preparing…'; });
    _dlService.downloadRecitation(
      surahNumber: surahNumber,
      imamId: imam.id,
      imamIdentifier: imam.identifier,
      onProgress: (p) {
        if (mounted) setState(() { _dlProgress = p; _dlStatus = '${(p * 100).toInt()}%'; });
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download failed: $e'),
                  backgroundColor: Colors.red.shade800));
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() { _isDownloading = false; _isRecDownloaded = true; });
          ref.invalidate(downloadedSurahsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Recitation saved offline'),
                  backgroundColor: Color(0xFF065F46)));
        }
      },
    );
  }

  void _startDownloadWithUrdu(int surahNumber, Imam imam) {
    setState(() { _isDownloading = true; _dlProgress = 0; _dlStatus = 'Preparing…'; });
    _dlService.downloadWithTarjumah(
      surahNumber: surahNumber,
      imamId: imam.id,
      ayahCount: widget.surah.ayahCount,
      onProgress: (p, status) {
        if (mounted) setState(() { _dlProgress = p; _dlStatus = status; });
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download failed: $e'),
                  backgroundColor: Colors.red.shade800));
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() { _isDownloading = false; _isUrduDownloaded = true; _isRecDownloaded = true; });
          ref.invalidate(downloadedSurahsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('✓ Recitation + Tarjumah saved offline'),
                  backgroundColor: Color(0xFF065F46)));
        }
      },
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  final Color color;
  const _TagPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColorsV2.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.manrope(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      );
}

class _MiniPlaybackBar extends ConsumerStatefulWidget {
  final Surah surah;
  final bool tarjumahMode;
  final VoidCallback onDownloadTap;
  final VoidCallback onPlayPauseTap;

  const _MiniPlaybackBar({
    required this.surah,
    required this.tarjumahMode,
    required this.onDownloadTap,
    required this.onPlayPauseTap,
  });

  @override
  ConsumerState<_MiniPlaybackBar> createState() => _MiniPlaybackBarState();
}

class _MiniPlaybackBarState extends ConsumerState<_MiniPlaybackBar> {
  bool _dragging = false;
  double _dragValue = 0.0;
  bool _tapLocked = false;

  Future<void> _handlePlayPauseTap() async {
    if (_tapLocked) return;
    setState(() => _tapLocked = true);
    try {
      await Future<void>.sync(widget.onPlayPauseTap);
    } finally {
      // Using Future.delayed instead of early return to avoid
      // 'return in finally' warning (dart:control_flow_in_finally)
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _tapLocked = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imam = ref.watch(selectedImamProvider);
    final playerStateAsync = ref.watch(currentPlayerStateProvider);
    final posAsync = ref.watch(positionProvider);
    final durAsync = ref.watch(durationProvider);
    final loop = ref.watch(loopProvider);

    final playerState = playerStateAsync.asData?.value;
    final isPlaying = playerState?.playing ?? false;
    final processing = playerState?.processingState;
    final isBuffering = processing == ProcessingState.loading || processing == ProcessingState.buffering;

    final pos = posAsync.asData?.value ?? Duration.zero;
    final dur = durAsync.asData?.value;
    final durMs = (dur?.inMilliseconds ?? 0);
    final posMs = pos.inMilliseconds.clamp(0, durMs == 0 ? pos.inMilliseconds : durMs);
    final progress = durMs <= 0 ? 0.0 : (posMs / durMs).clamp(0.0, 1.0);
    final sliderValue = _dragging ? _dragValue : progress;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(22),
      tint: AppColorsV2.bg,
      border: Border.all(color: AppColorsV2.outlineVariant.withValues(alpha: 0.18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.graphic_eq_rounded, color: _kGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (isBuffering && !isPlaying)
                          ? 'LOADING...'
                          : (widget.tarjumahMode ? 'TARJUMAH MODE' : 'RECITING'),
                      style: GoogleFonts.manrope(
                        color: AppColorsV2.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      imam?.name ?? widget.surah.name,
                      style: GoogleFonts.manrope(
                        color: AppColorsV2.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onDownloadTap,
                icon: const Icon(Icons.download_rounded, color: AppColorsV2.onSurfaceVariant),
              ),
              IconButton(
                onPressed: widget.tarjumahMode
                    ? null
                    : () {
                        final newVal = !loop;
                        ref.read(loopProvider.notifier).state = newVal;
                        if (widget.tarjumahMode) {
                          ref.read(interleavedAudioServiceProvider).setLoopMode(newVal);
                        } else {
                          ref.read(audioPlayerServiceProvider).setLoopMode(newVal);
                        }
                      },
                icon: Icon(
                  Icons.repeat_rounded,
                  color: widget.tarjumahMode
                      ? Colors.white24
                      : (loop ? _kGreen : AppColorsV2.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: isPlaying ? widget.onPlayPauseTap : (_tapLocked ? null : _handlePlayPauseTap),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kGreen,
                    boxShadow: [
                      BoxShadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 18),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: (_tapLocked && !isPlaying)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF00311F),
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFF00311F),
                          size: 30,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: _kGreen.withValues(alpha: 0.85),
              inactiveTrackColor: AppColorsV2.surfaceHighest,
              thumbColor: _kGreen,
              overlayColor: _kGreen.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: sliderValue,
              onChangeStart: durMs <= 0
                  ? null
                  : (_) => setState(() {
                        _dragging = true;
                        _dragValue = sliderValue;
                      }),
              onChanged: durMs <= 0
                  ? null
                  : (v) => setState(() {
                        _dragValue = v;
                      }),
              onChangeEnd: durMs <= 0
                  ? null
                  : (v) async {
                      setState(() => _dragging = false);
                      final target = Duration(milliseconds: (v * durMs).round());
                      if (widget.tarjumahMode) {
                        await ref.read(interleavedAudioServiceProvider).player.seek(target);
                      } else {
                        await ref.read(audioPlayerServiceProvider).seek(target);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final Ayah ayah;
  final bool isBookmarked;
  final bool isActive;
  final bool isTranslationSegment;
  final bool isEnglishAudio;
  final VoidCallback onBookmarkToggle;

  const _VerseCard({
    required this.ayah,
    required this.isBookmarked,
    this.isActive = false,
    this.isTranslationSegment = false,
    this.isEnglishAudio = false,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showTranslation = ayah.translation.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColorsV2.surfaceHigh.withValues(alpha: 0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: isActive
            ? Border.all(color: _kGreen.withValues(alpha: 0.18))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColorsV2.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${ayah.numberInSurah}',
                        style: GoogleFonts.manrope(
                          color: _kGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 26,
                      height: 1,
                      color: AppColorsV2.outlineVariant.withValues(alpha: 0.22),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _kGold.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTranslationSegment
                                  ? Icons.translate_rounded
                                  : Icons.record_voice_over_rounded,
                              color: _kGold,
                              size: 12,
                            ),
                            const SizedBox(width: 5),
                            // 👇 Dynamic label based on Audio selection! 👇
                            Text(
                              isTranslationSegment 
                                  ? (isEnglishAudio ? 'ENGLISH' : 'اردو') 
                                  : 'عربی',
                              style: GoogleFonts.manrope(
                                color: _kGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onBookmarkToggle,
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppColorsV2.onSurfaceVariant,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 34,
                height: 2.3,
                color: Colors.white,
                fontFamily: GoogleFonts.amiri().fontFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (showTranslation) ...[
            const SizedBox(height: 10),
            Builder(builder: (ctx2) {
              final isRtl = RegExp(r'[\u0600-\u06FF]').hasMatch(ayah.translation);
              return Padding(
                padding: EdgeInsets.only(
                  left: isRtl ? 6.0 : 12.0,
                  right: isRtl ? 12.0 : 6.0,
                ),
                child: Container(
                  padding: EdgeInsets.only(
                    left: isRtl ? 0.0 : 14.0,
                    right: isRtl ? 14.0 : 0.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: isRtl ? BorderSide.none : BorderSide(color: _kGreen.withValues(alpha: 0.22), width: 2),
                      right: isRtl ? BorderSide(color: _kGreen.withValues(alpha: 0.22), width: 2) : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    ayah.translation,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: GoogleFonts.manrope(
                      color: AppColorsV2.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.65,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _DownloadSheet extends StatelessWidget {
  final dynamic surah;
  final dynamic imam;
  final bool isRecDownloaded;
  final bool isUrduDownloaded;
  final VoidCallback onDownloadRecitation;
  final VoidCallback onDownloadWithUrdu;
  final VoidCallback onDelete;

  const _DownloadSheet({
    required this.surah,
    required this.imam,
    required this.isRecDownloaded,
    required this.isUrduDownloaded,
    required this.onDownloadRecitation,
    required this.onDownloadWithUrdu,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(surah.name,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text(surah.nameArabic,
                      style: TextStyle(
                          fontSize: 18,
                          color: _kGold,
                          fontFamily: GoogleFonts.amiri().fontFamily)),
                ],
              ),
              const SizedBox(height: 4),
              Text(imam.name,
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),

              _SheetOption(
                icon: Icons.headphones_rounded,
                title: 'Recitation Only',
                subtitle: 'Download full surah MP3 (~5 MB)',
                color: _kGreen,
                trailing: isRecDownloaded ? _DoneChip() : null,
                onTap: isRecDownloaded ? null : onDownloadRecitation,
              ),
              const SizedBox(height: 10),

              _SheetOption(
                icon: Icons.translate_rounded,
                title: 'With Tarjumah',
                subtitle: 'Download per-ayah audio + Translation\n'
                    '(~${(surah.ayahCount * 0.15).toStringAsFixed(0)} MB)',
                color: _kGold,
                trailing: isUrduDownloaded ? _DoneChip() : null,
                onTap: isUrduDownloaded ? null : onDownloadWithUrdu,
              ),

              if (isRecDownloaded || isUrduDownloaded) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 10),
                      Text('Delete all downloads for this Surah',
                          style: GoogleFonts.outfit(
                              color: Colors.red, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: disabled
              ? color.withValues(alpha: 0.04)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: disabled ? color.withValues(alpha: 0.4) : color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          color: disabled ? Colors.white38 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (!disabled) ...[
              const SizedBox(width: 8),
              Icon(Icons.download_rounded, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: _kGreen, size: 11),
          const SizedBox(width: 3),
          Text('Saved',
              style: GoogleFonts.outfit(
                  color: _kGreen, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}