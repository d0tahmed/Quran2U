import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/models/hadith_model.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/providers/hadith_providers.dart';
import 'package:quran_recitation/screens/read_quran_screen.dart';
import 'package:quran_recitation/screens/hadith_reader_screen.dart';
import 'package:quran_recitation/screens/tafseer_screen.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

const _kGreen = AppColorsV2.primary;
const _kAmber = Color(0xFFD4A843);


class ReadTabScreen extends ConsumerWidget {
  const ReadTabScreen({super.key});

  void _showTafseerSurahPicker(BuildContext context, List<Surah> surahs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TafseerSurahPickerSheet(surahs: surahs),
    );
  }

  void _showHadithSectionPicker(
      BuildContext context, WidgetRef ref, HadithCollection collection) {
    final lang = ref.read(hadithLanguageProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _HadithSectionPickerSheet(
          collection: collection,
          language:   lang,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(surahsProvider);
    final surahList   = surahsAsync.asData?.value ?? <Surah>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text(
                'Read & Explore',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                child: _BentoActionsRow(
                  onRead: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReadQuranScreen()),
                  ),
                  onTafseer: () {
                    if (surahList.isEmpty) return;
                    _showTafseerSurahPicker(context, surahList);
                  },
                  onBukhari:  () => _showHadithSectionPicker(context, ref, HadithCollection.bukhari),
                  onMuslim:   () => _showHadithSectionPicker(context, ref, HadithCollection.muslim),
                  onAbuDawud: () => _showHadithSectionPicker(context, ref, HadithCollection.abuDawud),
                  onTirmidhi: () => _showHadithSectionPicker(context, ref, HadithCollection.tirmidhi),
                  onNasai:    () => _showHadithSectionPicker(context, ref, HadithCollection.nasai),
                  onIbnMajah: () => _showHadithSectionPicker(context, ref, HadithCollection.ibnMajah),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TafseerSurahPickerSheet extends StatefulWidget {
  final List<Surah> surahs;
  const _TafseerSurahPickerSheet({required this.surahs});

  @override
  State<_TafseerSurahPickerSheet> createState() => _TafseerSurahPickerSheetState();
}

class _TafseerSurahPickerSheetState extends State<_TafseerSurahPickerSheet> {
  final _ctrl  = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.surahs.where((s) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.nameArabic.contains(_query) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.number.toString() == _query;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize:     0.5,
      maxChildSize:     0.96,
      expand:           false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color:         Color(0xFF0E1421),
          borderRadius:  BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:         Colors.white12,
                  borderRadius:  BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  padding:    const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:         _kAmber.withValues(alpha: 0.12),
                    borderRadius:  BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: _kAmber, size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tafseer',
                      style: GoogleFonts.manrope(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('Choose a Surah to explore',
                      style: GoogleFonts.manrope(color: Colors.white38, fontSize: 12)),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller:  _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged:   (v) => setState(() => _query = v),
                decoration:  InputDecoration(
                  hintText:   'Search surah…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon:      const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                          onPressed: () { _ctrl.clear(); setState(() => _query = ''); },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView.builder(
                controller:  scrollCtrl,
                padding:     const EdgeInsets.fromLTRB(16, 8, 16, 40),
                itemCount:   filtered.length,
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TafseerScreen(surah: s)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      margin:  const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color:         AppColorsV2.surfaceLow,
                        borderRadius:  BorderRadius.circular(12),
                        border:        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:         _kAmber.withValues(alpha: 0.10),
                            borderRadius:  BorderRadius.circular(10),
                          ),
                          child: Text(
                            s.number.toString().padLeft(3, '0'),
                            style: GoogleFonts.manrope(
                              color:       _kAmber,
                              fontSize:    10,
                              fontWeight:  FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: GoogleFonts.manrope(
                                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                            Text('${s.nameTranslation} • ${s.ayahCount} verses',
                                style: GoogleFonts.manrope(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        )),
                        Text(s.nameArabic,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize:   18,
                              color:      _kAmber.withValues(alpha: 0.85),
                              fontFamily: GoogleFonts.amiri().fontFamily,
                              fontWeight: FontWeight.w700,
                            )),
                      ]),
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
}

class _IslamicPatternPainter extends CustomPainter {
  const _IslamicPatternPainter();

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r, int points) {
    final path = Path();
    final inner = r * 0.42;
    for (int i = 0; i < points * 2; i++) {
      final angle  = (i * math.pi / points) - math.pi / 2;
      final radius = i.isEven ? r : inner;
      final x      = center.dx + radius * math.cos(angle);
      final y      = center.dy + radius * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin:  Alignment.centerLeft,
        end:    Alignment.centerRight,
        colors: [
          Color(0xFF1A2A1A),
          Color(0xFF2C1F0A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      bgPaint,
    );

    final patternPaint = Paint()
      ..color  = const Color(0xFFD4A843).withValues(alpha: 0.09)
      ..style  = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color       = const Color(0xFFD4A843).withValues(alpha: 0.06)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const gridX = 72.0;
    const gridY = 60.0;
    for (double x = gridX / 2; x < size.width + gridX; x += gridX) {
      for (double y = gridY / 2; y < size.height + gridY; y += gridY) {
        final offset = Offset(x, y);
        _drawStar(canvas, patternPaint, offset, 22, 8);
        _drawStar(canvas, strokePaint,  offset, 22, 8);
        _drawStar(canvas, strokePaint..color = const Color(0xFFD4A843).withValues(alpha: 0.04),
            offset, 10, 4);
      }
    }

    final linePaint = Paint()
      ..color       = const Color(0xFFD4A843).withValues(alpha: 0.05)
      ..strokeWidth = 0.6
      ..style       = PaintingStyle.stroke;

    for (double x = gridX / 2; x < size.width + gridX; x += gridX) {
      for (double y = gridY / 2; y < size.height + gridY; y += gridY) {
        canvas.drawLine(Offset(x - 36, y), Offset(x + 36, y), linePaint);
        canvas.drawLine(Offset(x, y - 30), Offset(x, y + 30), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BentoActionsRow extends StatelessWidget {
  final VoidCallback onRead;
  final VoidCallback onTafseer;
  final VoidCallback onBukhari;
  final VoidCallback onMuslim;
  final VoidCallback onAbuDawud;
  final VoidCallback onTirmidhi;
  final VoidCallback onNasai;
  final VoidCallback onIbnMajah;

  const _BentoActionsRow({
    required this.onRead,
    required this.onTafseer,
    required this.onBukhari,
    required this.onMuslim,
    required this.onAbuDawud,
    required this.onTirmidhi,
    required this.onNasai,
    required this.onIbnMajah,
  });


  static const String _readQuranBgAsset = 'assets/images/read_quran_bg.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            'The Noble Quran',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),

        AspectRatio(
          aspectRatio: 16 / 6.5,
          child: InkWell(
            onTap:         onRead,
            borderRadius:  BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color:        AppColorsV2.surfaceHigh,
                border:       Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _readQuranBgAsset,
                      fit:            BoxFit.cover,
                      alignment:      Alignment.centerRight,
                      filterQuality:  FilterQuality.low,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin:  Alignment.bottomLeft,
                          end:    Alignment.topRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.72),
                            Colors.black.withValues(alpha: 0.38),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment:  MainAxisAlignment.end,
                            children: [
                              Text('Read Quran',
                                  style: GoogleFonts.manrope(
                                    color:       Colors.white,
                                    fontSize:    20,
                                    fontWeight:  FontWeight.w900,
                                    letterSpacing: -0.2,
                                  )),
                              const SizedBox(height: 4),
                              Text('Continue reading',
                                  style: GoogleFonts.manrope(
                                    color:      _kGreen,
                                    fontSize:   12,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          width:  46,
                          height: 46,
                          decoration: BoxDecoration(
                            color:         _kGreen.withValues(alpha: 0.12),
                            borderRadius:  BorderRadius.circular(14),
                            border:        Border.all(color: _kGreen.withValues(alpha: 0.18)),
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: _kGreen),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),


        const SizedBox(height: 12),

        AspectRatio(
          aspectRatio: 16 / 6.5,
          child: InkWell(
            onTap:        onTafseer,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CustomPaint(painter: _IslamicPatternPainter()),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.centerLeft,
                        end:    Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment:  MainAxisAlignment.end,
                          children: [
                            Text('Tafseer',
                                style: GoogleFonts.manrope(
                                  color:        Colors.white,
                                  fontSize:     20,
                                  fontWeight:   FontWeight.w900,
                                  letterSpacing: -0.2,
                                )),
                            const SizedBox(height: 4),
                            Text('Meanings & context',
                                style: GoogleFonts.manrope(
                                  color:      _kAmber,
                                  fontSize:   12,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ),
                      Container(
                        width:  46,
                        height: 46,
                        decoration: BoxDecoration(
                          color:         _kAmber.withValues(alpha: 0.14),
                          borderRadius:  BorderRadius.circular(14),
                          border:        Border.all(color: _kAmber.withValues(alpha: 0.22)),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: _kAmber),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Hadith Collections',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),

        // ── Sahih Bukhari bento card ────────────────────────────────────────
        _HadithBentoCard(
          onTap:    onBukhari,
          label:    HadithCollection.bukhari.displayName,
          subtitle: HadithCollection.bukhari.subtitle,
          accent:   const Color(0xFFD4A843),
          bgColors: const [Color(0xFF1A0E06), Color(0xFF2C1A08), Color(0xFF1A2010)],
          icon:     Icons.format_quote_rounded,
        ),

        const SizedBox(height: 12),

        // ── Sahih Muslim bento card ─────────────────────────────────────────
        _HadithBentoCard(
          onTap:    onMuslim,
          label:    HadithCollection.muslim.displayName,
          subtitle: HadithCollection.muslim.subtitle,
          accent:   const Color(0xFF9B8EDF),
          bgColors: const [Color(0xFF0D0A1E), Color(0xFF1A1535), Color(0xFF0E1520)],
          icon:     Icons.menu_book_rounded,
        ),

        const SizedBox(height: 12),

        // ── Sunan Abu Dawood bento card ─────────────────────────────────────
        _HadithBentoCard(
          onTap:    onAbuDawud,
          label:    HadithCollection.abuDawud.displayName,
          subtitle: HadithCollection.abuDawud.subtitle,
          accent:   const Color(0xFF4EC9A8),
          bgColors: const [Color(0xFF061510), Color(0xFF0F2520), Color(0xFF0A1520)],
          icon:     Icons.collections_bookmark_rounded,
        ),

        const SizedBox(height: 12),

        // ── Jami' at-Tirmidhi bento card ────────────────────────────────────
        _HadithBentoCard(
          onTap:    onTirmidhi,
          label:    HadithCollection.tirmidhi.displayName,
          subtitle: HadithCollection.tirmidhi.subtitle,
          accent:   const Color(0xFFE57373),
          bgColors: const [Color(0xFF1F0D0D), Color(0xFF331414), Color(0xFF140707)],
          icon:     Icons.local_library_rounded,
        ),

        const SizedBox(height: 12),

        // ── Sunan an-Nasa'i bento card ──────────────────────────────────────
        _HadithBentoCard(
          onTap:    onNasai,
          label:    HadithCollection.nasai.displayName,
          subtitle: HadithCollection.nasai.subtitle,
          accent:   const Color(0xFF64B5F6),
          bgColors: const [Color(0xFF0A151F), Color(0xFF102030), Color(0xFF070E14)],
          icon:     Icons.library_books_rounded,
        ),

        const SizedBox(height: 12),

        // ── Sunan Ibn Majah bento card ──────────────────────────────────────
        _HadithBentoCard(
          onTap:    onIbnMajah,
          label:    HadithCollection.ibnMajah.displayName,
          subtitle: HadithCollection.ibnMajah.subtitle,
          accent:   const Color(0xFFFFB74D),
          bgColors: const [Color(0xFF1F150D), Color(0xFF332214), Color(0xFF140D07)],
          icon:     Icons.import_contacts_rounded,
        ),
      ],
    );
  }
}

// ─── Reusable Hadith bento card widget ───────────────────────────────────────

class _HadithBentoCard extends StatelessWidget {
  final VoidCallback onTap;
  final String       label;
  final String       subtitle;
  final Color        accent;
  final List<Color>  bgColors;
  final IconData     icon;

  const _HadithBentoCard({
    required this.onTap,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.bgColors,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 6.5,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                    colors: bgColors,
                  ),
                ),
              ),
              CustomPaint(painter: _HadithCardPatternPainter(accent)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.centerLeft,
                    end:    Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.75],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:  MainAxisAlignment.end,
                      children: [
                        Text(label,
                            style: GoogleFonts.manrope(
                              color:        Colors.white,
                              fontSize:     20,
                              fontWeight:   FontWeight.w900,
                              letterSpacing: -0.2,
                            )),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: GoogleFonts.manrope(
                              color:      accent,
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    width:  46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:        accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.30)),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── Hadith card background painter ──────────────────────────────────────────
class _HadithCardPatternPainter extends CustomPainter {
  final Color color;
  _HadithCardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    const r = 3.0;
    const step = 18.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}


// ─── Hadith section picker sheet ─────────────────────────────────────────────

class _HadithSectionPickerSheet extends ConsumerStatefulWidget {
  final HadithCollection collection;
  final HadithLanguage   language;

  const _HadithSectionPickerSheet({
    required this.collection,
    required this.language,
  });

  @override
  ConsumerState<_HadithSectionPickerSheet> createState() =>
      _HadithSectionPickerSheetState();
}

class _HadithSectionPickerSheetState
    extends ConsumerState<_HadithSectionPickerSheet> {
  final _ctrl = TextEditingController();
  String _query = '';
  late HadithLanguage _lang;

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _switchLang(HadithLanguage lang) {
    ref.read(hadithLanguageProvider.notifier).state = lang;
    setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) {
    final request   = (collection: widget.collection, language: _lang);
    final asyncSections = ref.watch(hadithSectionsProvider(request));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1421),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.format_quote_rounded,
                      color: _kAmber, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ahadees',
                        style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    Text('${widget.collection.displayName} — Choose a book',
                        style:
                            GoogleFonts.manrope(color: Colors.white38, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                ...HadithLanguage.values.map((lang) {
                  final selected = _lang == lang;
                  return GestureDetector(
                    onTap: () => _switchLang(lang),
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? _kAmber.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? _kAmber.withValues(alpha: 0.4)
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          lang.label,
                          style: TextStyle(
                            color: selected ? _kAmber : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: lang.isRtl
                                ? null
                                : GoogleFonts.manrope().fontFamily,
                          ),
                        ),
                      ),
                    );
                }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search book…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white38),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: asyncSections.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _kAmber),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.white38, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load Hadiths.\nCheck your internet connection.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                              color: Colors.white38, fontSize: 13, height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(hadithSectionsProvider((collection: widget.collection, language: _lang))),
                          child: const Text('Retry',
                              style: TextStyle(color: _kAmber)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (sections) {
                  final q = _query.toLowerCase();
                  final filtered = sections
                      .where((s) =>
                          q.isEmpty ||
                          s.name.toLowerCase().contains(q) ||
                          s.number.toString() == _query)
                      .toList();

                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final section = filtered[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HadithReaderScreen(
                                section:     section,
                                collection:  widget.collection,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColorsV2.surfaceLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _kAmber.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                section.number.toString().padLeft(2, '0'),
                                style: GoogleFonts.manrope(
                                    color: _kAmber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(section.name,
                                      style: GoogleFonts.manrope(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800)),
                                  Text('${section.hadithCount} hadiths',
                                      style: GoogleFonts.manrope(
                                          color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white24, size: 20),
                          ]),
                        ),
                      );
                    },
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
