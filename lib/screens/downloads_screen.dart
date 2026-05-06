import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/services/download_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;
const _kCard = AppColorsV2.surfaceLow;

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    final downloadedAsync = ref.watch(downloadedSurahsProvider);
    final imams = ref.watch(imamsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg.withValues(alpha: 0.80),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Downloads',
          style: GoogleFonts.manrope(
            color: AppColorsV2.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'OFFLINE SURAHs',
                style: GoogleFonts.manrope(
                  color: AppColorsV2.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: downloadedAsync.when(
                loading: () => const Center(
                    child: const CircularProgressIndicator(color: _kGreen)),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: GoogleFonts.manrope(color: Colors.white54))),
                data: (downloaded) {
                  if (downloaded.isEmpty) {
                    return _buildEmpty();
                  }
                  return surahsAsync.when(
                    loading: () => const Center(
                        child: const CircularProgressIndicator(color: _kGreen)),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (surahs) => ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: downloaded.length,
                      itemBuilder: (ctx, i) {
                        final entry = downloaded[i];
                        final surahNum = entry['surahNumber'] as int;
                        final imamId = entry['imamId'] as int;
                        final hasUrdu = entry['hasUrdu'] as bool;
                        final surah = surahs.cast<dynamic>().firstWhere(
                            (s) => s.number == surahNum,
                            orElse: () => null);
                        final imam = imams.cast<dynamic>().firstWhere(
                            (im) => im.id == imamId,
                            orElse: () => null);
                        return _DownloadedTile(
                          surahNumber: surahNum,
                          surahName: surah?.name ?? 'Surah $surahNum',
                          surahArabic: surah?.nameArabic ?? '',
                          imamName: imam?.name ?? 'Imam $imamId',
                          imamId: imamId,
                          hasUrdu: hasUrdu,
                          onDelete: () async {
                            final confirm = await _confirmDelete(context);
                            if (confirm == true) {
                              await ref
                                  .read(downloadServiceProvider)
                                  .deleteDownload(surahNum, imamId);
                              ref.invalidate(downloadedSurahsProvider);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_for_offline_outlined,
              color: Colors.white12, size: 64),
          const SizedBox(height: 16),
          Text('No downloads yet',
              style: GoogleFonts.manrope(
                  color: Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Open any Surah and tap the\ndownload button to save offline',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                  color: Colors.white24, fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _kCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Download',
              style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Text(
              'This will remove the downloaded audio files from your device.',
              style: GoogleFonts.manrope(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.manrope(color: Colors.white38, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: GoogleFonts.manrope(
                      color: Colors.red, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
}

class _DownloadedTile extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final String surahArabic;
  final String imamName;
  final int imamId;
  final bool hasUrdu;
  final VoidCallback onDelete;

  const _DownloadedTile({
    required this.surahNumber,
    required this.surahName,
    required this.surahArabic,
    required this.imamName,
    required this.imamId,
    required this.hasUrdu,
    required this.onDelete,
  });

  @override
  State<_DownloadedTile> createState() => _DownloadedTileState();
}

class _DownloadedTileState extends State<_DownloadedTile> {
  String _size = '...';

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    final bytes = await DownloadService()
        .getDownloadSizeBytes(widget.surahNumber, widget.imamId);
    if (mounted) {
      setState(() => _size = DownloadService.formatBytes(bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      tint: _kCard,
      child: Row(
        children: [
          // Surah number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${widget.surahNumber}',
                style: GoogleFonts.manrope(
                    color: _kGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(widget.surahName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(widget.surahArabic,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              color: _kGold,
                              fontFamily:
                                  GoogleFonts.amiri().fontFamily)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.imamName.split(' ').length > 1
                      ? widget.imamName.split(' ').skip(1).join(' ')
                      : widget.imamName,
                  style: GoogleFonts.manrope(
                      color: AppColorsV2.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Badge(
                      icon: Icons.headphones_rounded,
                      label: 'Recitation',
                      color: _kGreen,
                    ),
                    if (widget.hasUrdu)
                      _Badge(
                        icon: Icons.translate_rounded,
                        label: 'Urdu Tarjumah',
                        color: _kGold,
                      ),
                    const SizedBox(width: 4),
                    Text(_size,
                        style: GoogleFonts.manrope(
                            color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white24, size: 20),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.manrope(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}