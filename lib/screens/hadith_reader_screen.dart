// lib/screens/hadith_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/hadith_model.dart';
import 'package:quran_recitation/providers/hadith_providers.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

const _kGold = Color(0xFFD4A843);

// ─────────────────────────────────────────────────────────────────────────────

class HadithReaderScreen extends ConsumerStatefulWidget {
  final HadithSection    section;
  final HadithCollection collection;

  const HadithReaderScreen({
    super.key,
    required this.section,
    required this.collection,
  });

  @override
  ConsumerState<HadithReaderScreen> createState() => _HadithReaderScreenState();
}

class _HadithReaderScreenState extends ConsumerState<HadithReaderScreen> {
  // ── Language switch ─────────────────────────────────────────────────────────
  void _switchLanguage(HadithLanguage lang) {
    ref.read(hadithLanguageProvider.notifier).state = lang;
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(hadithLanguageProvider);

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsing header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: AppColorsV2.bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A120B),
                      _kGold.withValues(alpha: 0.18),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _HadithPatternPainter())),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          mainAxisAlignment:  MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              _Chip('Book ${widget.section.number}'),
                              const SizedBox(width: 10),
                              Text(
                                '${widget.section.hadithCount} Hadiths',
                                style: GoogleFonts.manrope(
                                  color: Colors.white38, fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              widget.section.name,
                              style: GoogleFonts.outfit(
                                color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.collection.displayName,
                              style: GoogleFonts.manrope(
                                color: _kGold.withValues(alpha: 0.7),
                                fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Language switcher ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('Language',
                      style: GoogleFonts.manrope(
                          color: Colors.white54, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  ...HadithLanguage.values.map((lang) {
                    final selected = currentLang == lang;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: selected
                            ? null
                            : () => _switchLanguage(lang),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? _kGold.withValues(alpha: 0.18)
                                : AppColorsV2.surfaceLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? _kGold.withValues(alpha: 0.4)
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            lang.label,
                            style: TextStyle(
                              color: selected ? _kGold : Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: lang.isRtl
                                  ? null
                                  : GoogleFonts.manrope().fontFamily,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Divider(color: Colors.white10, height: 20),
          ),

          // ── Lazy hadith list ─────────────────────────────────────────────────
          ref.watch(hadithListProvider((collection: widget.collection, sectionNumber: widget.section.number, language: currentLang))).when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _kGold)),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading hadiths.', style: GoogleFonts.manrope(color: Colors.white38))),
            ),
            data: (hadiths) {
              if (hadiths.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No hadiths found for this section.',
                      style: GoogleFonts.manrope(color: Colors.white38, fontSize: 14),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _HadithCard(
                      hadith:   hadiths[index],
                      language: currentLang,
                      isFirst:  index == 0,
                      isLast:   index == hadiths.length - 1,
                    ),
                    childCount: hadiths.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Small badge chip ─────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        _kGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: _kGold.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          color: _kGold, fontSize: 11,
          fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

// ─── Hadith card ─────────────────────────────────────────────────────────────

class _HadithCard extends StatelessWidget {
  final HadithEntry    hadith;
  final HadithLanguage language;
  final bool           isFirst;
  final bool           isLast;

  const _HadithCard({
    required this.hadith,
    required this.language,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = language.isRtl;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColorsV2.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!isRtl) _NumberBadge(hadith.hadithNumber),
                if (!isRtl) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Book ${hadith.bookNumber}, Hadith ${hadith.hadithInBook}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: isRtl ? TextAlign.end : TextAlign.start,
                    style: GoogleFonts.manrope(
                      color: Colors.white30, fontSize: 10,
                      fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
                ),
                if (isRtl) const SizedBox(width: 8),
                if (isRtl) _NumberBadge(hadith.hadithNumber),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: _kGold.withValues(alpha: 0.14), height: 1),
            const SizedBox(height: 12),
            Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                hadith.text.trim().isEmpty 
                    ? 'Translation not available in ${language.label}.'
                    : hadith.text,
                style: TextStyle(
                  color:      hadith.text.trim().isEmpty 
                                  ? Colors.white24 
                                  : Colors.white.withValues(alpha: 0.88),
                  fontSize:   isRtl ? 15 : 13.5,
                  height:     isRtl ? 2.0 : 1.75,
                  fontStyle:  hadith.text.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                  fontWeight: FontWeight.w500,
                  fontFamily: isRtl
                      ? GoogleFonts.amiri().fontFamily
                      : GoogleFonts.manrope().fontFamily,
                  letterSpacing: isRtl ? 0.2 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  const _NumberBadge(this.number);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        _kGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withValues(alpha: 0.25)),
      ),
      child: Text(
        '#$number',
        style: GoogleFonts.manrope(
            color: _kGold, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

// ─── Background pattern painter ───────────────────────────────────────────────

class _HadithPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    const step = 60.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawStar(canvas, paint, Offset(x, y), 18.0, 8);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r, int pts) {
    final path  = Path();
    final inner = r * 0.42;
    for (int i = 0; i < pts * 2; i++) {
      final angle  = (i * 3.14159265 / pts) - 3.14159265 / 2;
      final radius = i.isEven ? r : inner;
      final x      = center.dx + radius * _cos(angle);
      final y      = center.dy + radius * _sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => _sin(a + 1.5707963);
  double _sin(double a) {
    double x = a % 6.28318530;
    if (x < 0) x += 6.28318530;
    if (x > 3.14159265) {
      x -= 3.14159265;
      return -(x * (3.14159265 - x) * 4) /
          (3.14159265 * 3.14159265 - x * (3.14159265 - x) * 2);
    }
    return (x * (3.14159265 - x) * 4) /
        (3.14159265 * 3.14159265 - x * (3.14159265 - x) * 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
