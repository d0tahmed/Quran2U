import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:adhan/adhan.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/surah_detail_screen.dart';
import 'package:quran_recitation/screens/qibla_screen.dart';
import 'package:quran_recitation/screens/prayer_times_screen.dart';
import 'package:quran_recitation/screens/daily_inspiration_screen.dart';
import 'package:quran_recitation/screens/bookmarks_screen.dart';
import 'package:quran_recitation/screens/read_quran_screen.dart';
import 'package:quran_recitation/screens/tafseer_screen.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

const _kGreen = AppColorsV2.primary;
const _kGold  = AppColorsV2.tertiary;
const _kBlue  = AppColorsV2.secondary;

const _kAmber = Color(0xFFD4A843);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _short(String name) => name.split(' ').last;

  void _showTafseerSurahPicker(BuildContext context, List<Surah> surahs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TafseerSurahPickerSheet(surahs: surahs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync  = ref.watch(surahsProvider);
    final selectedImam = ref.watch(selectedImamProvider);
    final imams        = ref.watch(imamsProvider);

    final surahList = surahsAsync.asData?.value ?? <Surah>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notif) {
                if (notif.direction == ScrollDirection.reverse) {
                  if (ref.read(navBarVisibleProvider))
                    ref.read(navBarVisibleProvider.notifier).state = false;
                } else if (notif.direction == ScrollDirection.forward) {
                  if (!ref.read(navBarVisibleProvider))
                    ref.read(navBarVisibleProvider.notifier).state = true;
                }
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 72,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Center(
                          child: Text(
                            'Quran2U',
                            style: GoogleFonts.outfit(
                              color: _kGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _NextPrayerCard(),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search surah by name or n…',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white38),
                                      onPressed: () {
                                        _ctrl.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _BentoActionsRow(
                            onRead: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ReadQuranScreen()),
                            ),
                            onDaily: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DailyInspirationScreen()),
                            ),
                            onSaved: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                            ),
                            onTafseer: () {
                              if (surahList.isEmpty) return;
                              _showTafseerSurahPicker(context, surahList);
                            },
                          ),
                        ),

                        const SizedBox(height: 22),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Text(
                            'Reciters',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: imams.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) {
                              final imam = imams[i];
                              final sel  = selectedImam?.id == imam.id;
                              return _ReciterPill(
                                text:     _short(imam.name),
                                selected: sel,
                                onTap: () {
                                  ref.read(selectedImamProvider.notifier).state = imam;
                                  if (imam.id == 6 || imam.id == 7) {
                                    ref.read(tarjumahModeProvider.notifier).state = false;
                                  }
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Surahs',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  surahsAsync.when(
                    data:    _buildList,
                    loading: () => const _ShimmerList(),
                    error:   (e, _) => SliverFillRemaining(child: _buildError(e)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Surah> surahs) {
    final q    = _query.toLowerCase();
    final list = surahs.where((s) {
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.nameArabic.contains(_query) ||
          s.nameTranslation.toLowerCase().contains(q) ||
          s.number.toString() == _query;
    }).toList();

    if (list.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.search_off_rounded, size: 52, color: Colors.white12),
            const SizedBox(height: 12),
            Text('No surahs found', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AnimatedRow(index: index, child: _SurahCardRow(surah: list[index])),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildError(Object err) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.white12),
          const SizedBox(height: 16),
          Text('No connection', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => ref.refresh(surahsProvider),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGreen,
              side: const BorderSide(color: _kGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon:  const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: GoogleFonts.outfit()),
          ),
        ]),
      );
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
      ..shader = LinearGradient(
        begin:  Alignment.centerLeft,
        end:    Alignment.centerRight,
        colors: [
          const Color(0xFF1A2A1A),
          const Color(0xFF2C1F0A),
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
  final VoidCallback onDaily;
  final VoidCallback onSaved;
  final VoidCallback onTafseer;

  const _BentoActionsRow({
    required this.onRead,
    required this.onDaily,
    required this.onSaved,
    required this.onTafseer,
  });

  static const String _readQuranBgAsset = 'assets/images/read_quran_bg.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _MiniBentoTile(
                  title:    'Daily',
                  subtitle: 'Ayah of the day',
                  icon:     Icons.star_rounded,
                  tint:     _kGold,
                  onTap:    onDaily,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _MiniBentoTile(
                  title:    'Saved',
                  subtitle: 'Bookmarks',
                  icon:     Icons.bookmark_rounded,
                  tint:     _kBlue,
                  onTap:    onSaved,
                ),
              ),
            ),
          ],
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
                  CustomPaint(painter: const _IslamicPatternPainter()),
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
      ],
    );
  }
}

class _NextPrayerCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(prayerTimesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color:        AppColorsV2.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset:     const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: prayerAsync.when(
              data: (prayerTimes) {
                final nextPrayer = prayerTimes.nextPrayer();
                final time       = prayerTimes.timeForPrayer(nextPrayer);
                final name       = nextPrayer == Prayer.none ? 'ISHA' : nextPrayer.name.toUpperCase();
                final timeStr    = time != null ? DateFormat.jm().format(time) : '--:--';
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text('NEXT PRAYER',
                          style: GoogleFonts.manrope(
                            color:        AppColorsV2.onSurfaceVariant,
                            fontSize:     10,
                            fontWeight:   FontWeight.w900,
                            letterSpacing: 2.0,
                          )),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing:            12,
                        runSpacing:         4,
                        children: [
                          Text(name,
                              style: GoogleFonts.manrope(
                                color:        Colors.white,
                                fontSize:     24,
                                fontWeight:   FontWeight.w900,
                                letterSpacing: -0.5,
                              )),
                          Container(
                            width:  6, height: 6,
                            decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                          ),
                          Text(timeStr,
                              style: GoogleFonts.manrope(
                                color:      Colors.white70,
                                fontSize:   20,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
                ),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:       MainAxisSize.min,
                children: [
                  Text('NEXT PRAYER',
                      style: GoogleFonts.manrope(
                        color:        AppColorsV2.onSurfaceVariant,
                        fontSize:     10,
                        fontWeight:   FontWeight.w900,
                        letterSpacing: 2.0,
                      )),
                  const SizedBox(height: 4),
                  Text('Location required',
                      style: GoogleFonts.manrope(
                        color:      AppColorsV2.danger,
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QiblaScreen()),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:         _kGreen.withValues(alpha: 0.15),
                borderRadius:  BorderRadius.circular(12),
                border:        Border.all(color: _kGreen.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.explore_rounded, color: _kGreen, size: 18),
                const SizedBox(width: 6),
                Text('Qibla',
                    style: GoogleFonts.manrope(
                      color:      _kGreen,
                      fontSize:   13,
                      fontWeight: FontWeight.w800,
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBentoTile extends StatelessWidget {
  final String      title;
  final String      subtitle;
  final IconData    icon;
  final Color       tint;
  final VoidCallback onTap;
  const _MiniBentoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:         AppColorsV2.surfaceLow,
          borderRadius:  BorderRadius.circular(16),
          border:        Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width:  40, height: 40,
              decoration: BoxDecoration(
                color:         tint.withValues(alpha: 0.12),
                borderRadius:  BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.manrope(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w900,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.manrope(
                    color:      AppColorsV2.onSurfaceVariant,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ReciterPill extends StatelessWidget {
  final String       text;
  final bool         selected;
  final VoidCallback onTap;
  const _ReciterPill({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale:    selected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color:         selected ? _kGreen : AppColorsV2.surfaceHigh,
            borderRadius:  BorderRadius.circular(999),
            border:        Border.all(color: selected ? _kGreen : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(text,
              style: GoogleFonts.manrope(
                color:      selected ? const Color(0xFF002113) : AppColorsV2.onSurfaceVariant,
                fontSize:   12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              )),
        ),
      ),
    );
  }
}

class _SurahCardRow extends ConsumerWidget {
  final Surah surah;
  const _SurahCardRow({required this.surah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(bookmarksProvider)
        .any((b) => b.surahNumber == surah.number && b.ayahNumber == null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(PageRouteBuilder(
          pageBuilder:       (_, __, ___) => SurahDetailScreen(surah: surah),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        )),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:         AppColorsV2.surfaceLow,
            borderRadius:  BorderRadius.circular(16),
            border:        Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:         AppColorsV2.surfaceHighest,
                borderRadius:  BorderRadius.circular(12),
              ),
              child: Text(
                surah.number.toString().padLeft(3, '0'),
                style: GoogleFonts.manrope(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(surah.name,
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('${surah.nameTranslation} • ${surah.ayahCount} Verses',
                  style: GoogleFonts.manrope(
                    color:      AppColorsV2.onSurfaceVariant,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 10),
            Text(
              surah.nameArabic,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize:   22,
                color:      _kGreen.withValues(alpha: 0.90),
                fontFamily: GoogleFonts.amiri().fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                final bks = ref.read(bookmarksProvider);
                if (isBookmarked) {
                  ref.read(bookmarksProvider.notifier).updateBookmarks(
                    bks.where((b) => !(b.surahNumber == surah.number && b.ayahNumber == null)).toList(),
                  );
                } else {
                  ref.read(bookmarksProvider.notifier).updateBookmarks([
                    ...bks,
                    Bookmark(
                      id:          DateTime.now().millisecondsSinceEpoch.toString(),
                      surahNumber: surah.number,
                      title:       surah.name,
                      createdAt:   DateTime.now(),
                    ),
                  ]);
                }
              },
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isBookmarked ? _kGreen : Colors.white24,
                size:  20,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AnimatedRow extends StatelessWidget {
  final Widget child;
  final int    index;
  const _AnimatedRow({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    if (index > 16) return child;
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 35),
      curve:    Curves.easeOutCubic,
      builder:  (_, v, c) => Transform.translate(
        offset:  Offset(0, 18 * (1 - v)),
        child:   Opacity(opacity: v.clamp(0.0, 1.0), child: c),
      ),
      child: child,
    );
  }
}

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();
  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:   (_, __) {
        final shimmer = Color.lerp(AppColorsV2.surfaceLow, AppColorsV2.surfaceHigh, _anim.value)!;
        return SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 140),
          sliver:  SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Opacity(
                opacity: (1.0 - i * 0.06).clamp(0.2, 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(children: [
                    Container(width: 42, height: 42,
                        decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 140, height: 12,
                          decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 8),
                      Container(width: 190, height: 10,
                          decoration: BoxDecoration(
                              color: shimmer.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(6))),
                    ])),
                    const SizedBox(width: 14),
                    Container(width: 64, height: 18,
                        decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
                  ]),
                ),
              ),
              childCount: 12,
            ),
          ),
        );
      },
    );
  }
}