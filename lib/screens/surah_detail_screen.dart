import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/services/download_service.dart';
import 'package:uuid/uuid.dart';

const _kGreen = Color(0xFF10B981);
const _kGold = Color(0xFFEAB308);
const _kCard = Color(0xFF121B2B);
const _kBg = Color(0xFF05080F);

class SurahDetailScreen extends ConsumerStatefulWidget {
  final Surah surah;
  const SurahDetailScreen({required this.surah, super.key});

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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
      body: Column(
        children: [
          _buildSurahHeader(context, currentSurahData),
          Expanded(
            child: ayahsAsync.when(
              data: (ayahs) => _buildAyahList(ayahs, bookmarks, currentSurahData),
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kGreen)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style:
                          GoogleFonts.outfit(color: Colors.white54))),
            ),
          ),
          _buildPlayer(context, surahNumber),
        ],
      ),
    );
  }

  Widget _buildSurahHeader(BuildContext context, Surah surah) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF092A1A), _kBg],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(surah.name,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                        Text(surah.nameTranslation,
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(surah.nameArabic,
                      style: TextStyle(
                          fontSize: 22,
                          color: _kGold,
                          fontFamily: GoogleFonts.amiri().fontFamily)),
                ],
              ),
            ),
            if (surah.number != 1 && surah.number != 9)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                child: Text(
                  'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
                  style: TextStyle(
                      fontSize: 18,
                      color: _kGold,
                      height: 2,
                      fontFamily: GoogleFonts.amiri().fontFamily),
                  textDirection: TextDirection.rtl,
                ),
              )
            else
              const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  _StatBadge(
                      icon: Icons.format_list_numbered_rounded,
                      label: '${surah.ayahCount} Verses'),
                  const SizedBox(width: 10),
                  _StatBadge(
                      icon: Icons.location_on_outlined,
                      label: surah.revelationType),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahList(List<Ayah> ayahs, List<Bookmark> bookmarks, Surah surah) {
    final tarjumahMode = ref.watch(tarjumahModeProvider);
    final playingAyah = tarjumahMode
        ? ref.watch(currentAyahNumberProvider).asData?.value
        : null;
    final isUrdu = tarjumahMode
        ? (ref.watch(isUrduSegmentProvider).asData?.value ?? false)
        : false;

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: ayahs.length,
      itemBuilder: (ctx, i) {
        final ayah = ayahs[i];
        final isBookmarked = bookmarks.any((b) =>
            b.surahNumber == surah.number &&
            b.ayahNumber == ayah.numberInSurah);
        final isCurrentAyah = tarjumahMode && playingAyah == ayah.numberInSurah;
        return KeyedSubtree(
          key: _keyFor(ayah.numberInSurah),
          child: _AyahCard(
            ayah: ayah,
            isBookmarked: isBookmarked,
            isActive: isCurrentAyah,
            isUrduSegment: isCurrentAyah && isUrdu,
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

  Widget _buildPlayer(BuildContext context, int surahNumber) {
    final tarjumahMode = ref.watch(tarjumahModeProvider);
    final audioPlayer = ref.watch(audioPlayerServiceProvider);
    final interleavedSvc = ref.watch(interleavedAudioServiceProvider);
    final selectedImam = ref.watch(selectedImamProvider);
    final audioUrl = ref.watch(audioUrlProvider((
      surahNumber,
      selectedImam?.id ?? 1,
    )));
    final posAsync = ref.watch(positionProvider);
    final durAsync = ref.watch(durationProvider);
    final isPlaying = tarjumahMode
        ? interleavedSvc.player.playing
        : audioPlayer.player.playing;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Info row — clean, no overflow ──────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (tarjumahMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kGold.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ref.watch(isUrduSegmentProvider).asData?.value == true
                                ? Icons.translate_rounded
                                : Icons.record_voice_over_rounded,
                            color: _kGold, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            ref.watch(isUrduSegmentProvider).asData?.value == true
                                ? 'اردو' : 'Arabic',
                            style: GoogleFonts.outfit(
                                color: _kGold, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        () {
                          final ayah = ref.watch(currentAyahNumberProvider).asData?.value;
                          return ayah != null ? 'Ayah $ayah of ${widget.surah.ayahCount}' : 'Tarjumah Mode';
                        }(),
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.person_outline_rounded, color: _kGreen, size: 13),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        selectedImam != null ? _shortImamName(selectedImam.name) : 'Sheikh',
                        style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Text('$surahNumber / 114',
                        style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11)),
                  ],
                ],
              ),
            ),
            // ── Progress bar ───────────────────────────────────────────────
            Row(
              children: [
                _timeText(posAsync, isStart: true),
                const SizedBox(width: 6),
                Expanded(
                  child: posAsync.when(
                    data: (pos) => durAsync.when(
                      data: (dur) => Slider(
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
                      loading: () => const _SliderPlaceholder(),
                      error: (_, __) => const _SliderPlaceholder(),
                    ),
                    loading: () => const _SliderPlaceholder(),
                    error: (_, __) => const _SliderPlaceholder(),
                  ),
                ),
                const SizedBox(width: 6),
                _timeText(durAsync, isStart: false),
              ],
            ),
            const SizedBox(height: 4),
            _buildDownloadRow(surahNumber, selectedImam),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CtrlBtn(
                    icon: Icons.skip_previous_rounded,
                    enabled: surahNumber > 1,
                    onTap: () async {
                      if (tarjumahMode) {
                        await interleavedSvc.pause();
                      } else {
                        await audioPlayer.pause();
                      }
                      ref.read(currentSurahProvider.notifier).state = surahNumber - 1;
                    },
                  ),
                  _CtrlBtn(
                    icon: Icons.replay_5_rounded,
                    onTap: () => tarjumahMode
                        ? interleavedSvc.seek(
                            (interleavedSvc.player.position - const Duration(seconds: 5))
                                .isNegative ? Duration.zero
                                : interleavedSvc.player.position - const Duration(seconds: 5))
                        : audioPlayer.skipBackward5Seconds(),
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: isPlaying ? _pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: GestureDetector(
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
                            final imam = ref.read(selectedImamProvider);
                            await interleavedSvc.buildAndPlay(
                              surahNumber: surahNumber,
                              ayahCount: widget.surah.ayahCount,
                              imamId: imam?.id ?? 1,
                            );
                          } else {
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
                        }
                      },
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3CA86A), Color(0xFF1F6B3A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _kGreen.withValues(alpha:
                                  isPlaying ? 0.5 : 0.25),
                              blurRadius: isPlaying ? 20 : 10,
                              spreadRadius: isPlaying ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  _CtrlBtn(
                    icon: Icons.forward_5_rounded,
                    onTap: () => tarjumahMode
                        ? interleavedSvc.seek(
                            interleavedSvc.player.position + const Duration(seconds: 5))
                        : audioPlayer.skipForward5Seconds(),
                  ),
                  _CtrlBtn(
                    icon: Icons.skip_next_rounded,
                    enabled: surahNumber < 114,
                    onTap: () async {
                      if (tarjumahMode) {
                        await interleavedSvc.pause();
                      } else {
                        await audioPlayer.pause();
                      }
                      ref.read(currentSurahProvider.notifier).state = surahNumber + 1;
                    },
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

  Widget _buildDownloadRow(int surahNumber, Imam? imam) {
    if (imam == null) return const SizedBox.shrink();

    if (_isDownloading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kGreen)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_dlStatus,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11)),
                ),
                TextButton(
                  onPressed: () {
                    _dlService.cancelDownload(surahNumber, imam.id);
                    if (mounted) setState(() { _isDownloading = false; _dlProgress = 0; });
                  },
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Cancel',
                      style: GoogleFonts.outfit(
                          color: Colors.red, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _dlProgress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(_kGreen),
                minHeight: 3,
              ),
            ),
          ],
        ),
      );
    }

    final downloaded = _isRecDownloaded || _isUrduDownloaded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (downloaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.offline_pin_rounded,
                      color: _kGreen, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    _isUrduDownloaded ? 'Offline + Tarjumah' : 'Available Offline',
                    style: GoogleFonts.outfit(
                        color: _kGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showDownloadSheet(context, surahNumber, imam),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    downloaded
                        ? Icons.download_done_rounded
                        : Icons.download_rounded,
                    color: downloaded ? _kGreen : Colors.white54,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    downloaded ? 'Manage' : 'Download',
                    style: GoogleFonts.outfit(
                        color: downloaded ? _kGreen : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadSheet(
      BuildContext context, int surahNumber, Imam imam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // SENIOR FIX: Solves the overflow!
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
    setState(() { _isDownloading = true; _dlProgress = 0; _dlStatus = 'Preparing...'; });
    _dlService.downloadRecitation(
      surahNumber: surahNumber,
      imamId: imam.id,
      imamIdentifier: imam.identifier,
      onProgress: (p) {
        if (mounted) setState(() { _dlProgress = p; _dlStatus = '${(p * 100).toInt()}%'; });
      },
      onError: (e) {
        if (mounted) {
          setState(() { _isDownloading = false; });
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
    setState(() { _isDownloading = true; _dlProgress = 0; _dlStatus = 'Preparing...'; });
    _dlService.downloadWithTarjumah(
      surahNumber: surahNumber,
      imamId: imam.id,
      ayahCount: widget.surah.ayahCount,
      onProgress: (p, status) {
        if (mounted) setState(() { _dlProgress = p; _dlStatus = status; });
      },
      onError: (e) {
        if (mounted) {
          setState(() { _isDownloading = false; });
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
                  content: Text('✓ Recitation + Urdu Tarjumah saved offline'),
                  backgroundColor: Color(0xFF065F46)));
        }
      },
    );
  }

  String _shortImamName(String name) => name.split(' ').last;

  Widget _timeText(AsyncValue av, {required bool isStart}) {
    String text = '0:00';
    if (isStart) {
      text = av.asData?.value != null
          ? _fmt(av.asData!.value as Duration)
          : '0:00';
    } else {
      final dur = av.asData?.value as Duration?;
      text = dur != null ? _fmt(dur) : '0:00';
    }
    return Text(text,
        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool isBookmarked;
  final bool isActive;
  final bool isUrduSegment;
  final VoidCallback onBookmarkToggle;

  const _AyahCard({
    required this.ayah,
    required this.isBookmarked,
    this.isActive = false,
    this.isUrduSegment = false,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? _kGold.withValues(alpha: 0.07)
            : _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _kGold.withValues(alpha: 0.45)
              : isBookmarked
                  ? _kGreen.withValues(alpha: 0.35)
                  : Colors.transparent,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: _kGold.withValues(alpha: 0.12), blurRadius: 12, spreadRadius: 1)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _kGold.withValues(alpha: 0.18)
                          : _kGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: GoogleFonts.outfit(
                          color: isActive ? _kGold : _kGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUrduSegment ? Icons.translate_rounded : Icons.record_voice_over_rounded,
                            color: _kGold, size: 9,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isUrduSegment ? 'اردو' : 'عربی',
                            style: GoogleFonts.outfit(color: _kGold, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: onBookmarkToggle,
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked ? _kGreen : Colors.white24,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ayah.text,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 22,
              height: 1.9,
              color: Colors.white.withValues(alpha: 0.92),
              fontFamily: GoogleFonts.amiri().fontFamily,
            ),
          ),
          if (ayah.translation.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 24),
            Builder(builder: (context) {
              final isRtl = RegExp(r'[\u0600-\u06FF]').hasMatch(ayah.translation);
              return Text(
                ayah.translation,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: GoogleFonts.outfit(
                    color: Colors.white54, fontSize: 13, height: 1.7),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _CtrlBtn(
      {required this.icon, this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon,
          color: enabled ? Colors.white70 : Colors.white24, size: 28),
      onPressed: enabled ? onTap : null,
    );
  }
}

class _SliderPlaceholder extends StatelessWidget {
  const _SliderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator(
        minHeight: 3,
        backgroundColor: Color(0xFF2A3245),
        valueColor: AlwaysStoppedAnimation<Color>(_kGreen));
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
    // SENIOR FIX: SafeArea and SingleChildScrollView prevent BottomSheet overflow
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
                title: 'With Urdu Tarjumah',
                subtitle: 'Download per-ayah audio + Shamshad Ali Khan\n'
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