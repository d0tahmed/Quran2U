import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/services/tafseer_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final _tafseerServiceProvider = Provider((ref) => TafseerService());

enum TafseerSource { ibnKathir, maarifulQuran }

final tafseerSourceProvider =
    StateProvider<TafseerSource>((ref) => TafseerSource.ibnKathir);

final tafseerProvider = FutureProvider.family<List<TafseerEntry>, (int, int)>(
  (ref, args) {
    final (surahNumber, tafsirId) = args;
    return ref
        .read(_tafseerServiceProvider)
        .fetchTafseerForSurah(surahNumber: surahNumber, tafsirId: tafsirId);
  },
);

// ── Screen ───────────────────────────────────────────────────────────────────

class TafseerScreen extends ConsumerWidget {
  final Surah surah;

  const TafseerScreen({required this.surah, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(tafseerSourceProvider);
    final tafsirId = source == TafseerSource.ibnKathir
        ? TafseerService.ibnKathirEnglishId
        : TafseerService.maarifulQuranUrduId;

    final tafseerAsync = ref.watch(tafseerProvider((surah.number, tafsirId)));

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, source),
            _buildSurahInfo(),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: tafseerAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColorsV2.primary),
                ),
                error: (e, _) => _buildError(e.toString()),
                data: (entries) => _buildList(entries, source),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, TafseerSource source) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Tafseer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // ── Source toggle ──────────────────────────────────────────────
          GlassPanel(
            padding: const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(14),
            tint: AppColorsV2.surfaceLow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleChip(
                  label: 'Ibn Kathir',
                  active: source == TafseerSource.ibnKathir,
                  onTap: () => ref.read(tafseerSourceProvider.notifier).state =
                      TafseerSource.ibnKathir,
                ),
                const SizedBox(width: 4),
                _ToggleChip(
                  label: 'Maariful',
                  active: source == TafseerSource.maarifulQuran,
                  onTap: () => ref.read(tafseerSourceProvider.notifier).state =
                      TafseerSource.maarifulQuran,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${surah.name} — ${surah.nameTranslation}',
                  style: GoogleFonts.manrope(
                    color: AppColorsV2.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Pill(
                        text: '${surah.ayahCount} Verses',
                        color: AppColorsV2.tertiary),
                    _Pill(
                        text: surah.revelationType,
                        color: AppColorsV2.secondary),
                  ],
                ),
              ],
            ),
          ),
          Text(
            surah.nameArabic,
            style: TextStyle(
              fontSize: 28,
              color: AppColorsV2.primary,
              fontFamily: GoogleFonts.amiri().fontFamily,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TafseerEntry> entries, TafseerSource source) {
    final isUrdu = source == TafseerSource.maarifulQuran;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        return _TafseerCard(entry: entry, isUrdu: isUrdu);
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load tafseer',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                  color: Colors.white38, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tafseer Card ─────────────────────────────────────────────────────────────

class _TafseerCard extends StatefulWidget {
  final TafseerEntry entry;
  final bool isUrdu;

  const _TafseerCard({required this.entry, required this.isUrdu});

  @override
  State<_TafseerCard> createState() => _TafseerCardState();
}

class _TafseerCardState extends State<_TafseerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.entry.text;
    final isLong = text.length > 400;
    final displayText =
        (!_expanded && isLong) ? '${text.substring(0, 400)}…' : text;
    final isRtl = widget.isUrdu;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      tint: AppColorsV2.surfaceLow,
      border: Border.all(
          color: AppColorsV2.outlineVariant.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ayah badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColorsV2.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppColorsV2.primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Ayah ${widget.entry.ayahNumber}',
                  style: GoogleFonts.manrope(
                    color: AppColorsV2.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.entry.verseKey,
                style: GoogleFonts.manrope(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tafseer text
          Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Text(
              displayText,
              style: GoogleFonts.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 13.5,
                height: 1.75,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Expand/collapse
          if (isLong) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less ↑' : 'Read more ↓',
                style: GoogleFonts.manrope(
                  color: AppColorsV2.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColorsV2.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColorsV2.primary.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: active ? AppColorsV2.primary : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorsV2.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: GoogleFonts.manrope(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}