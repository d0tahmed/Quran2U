import 'dart:ui';
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
import 'package:quran_recitation/screens/read_quran_screen.dart'; // NEW IMPORT
import 'package:quran_recitation/screens/main_shell.dart';

const _kGreen = Color(0xFF10B981);
const _kGold = Color(0xFFEAB308);
const _kBlue = Color(0xFF3B82F6); // Added a nice blue for the Read button

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  String _query = '';
  late AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  static String _short(String name) => name.split(' ').last;

  // Helper method to keep dashboard buttons clean
  Widget _buildActionBtn(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(title, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    final selectedImam = ref.watch(selectedImamProvider);
    final imams = ref.watch(imamsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          Positioned(
            top: -150, left: -50, right: -50,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kGreen.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notif) {
                if (notif.direction == ScrollDirection.reverse) {
                  if (ref.read(navBarVisibleProvider)) ref.read(navBarVisibleProvider.notifier).state = false;
                } else if (notif.direction == ScrollDirection.forward) {
                  if (!ref.read(navBarVisibleProvider)) ref.read(navBarVisibleProvider.notifier).state = true;
                }
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Center(
                            child: Text('Quran2U',
                                style: GoogleFonts.outfit(fontSize: 22, color: _kGold, letterSpacing: 3.0, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِيمِ',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(fontSize: 15, color: _kGold.withValues(alpha: 0.65), fontFamily: GoogleFonts.amiri().fontFamily, height: 2)),
                          ),
                        ),

                        const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                        const SizedBox(height: 14),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: _NamazAndQiblaCard(),
                        ),
                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search surah by name or number...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white38),
                                      onPressed: () { _ctrl.clear(); setState(() => _query = ''); })
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 8),
                          child: Text('RECITER',
                              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                        ),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: imams.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final imam = imams[i];
                              final sel = selectedImam?.id == imam.id;
                              return AnimatedScale(
                                scale: sel ? 1.06 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                child: GestureDetector(
                                  onTap: () => ref.read(selectedImamProvider.notifier).state = imam,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: sel ? _kGreen : Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: sel ? _kGreen : Colors.white.withValues(alpha: 0.08)),
                                          boxShadow: sel ? [BoxShadow(color: _kGreen.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)] : [],
                                        ),
                                        child: Text(_short(imam.name),
                                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : Colors.white54)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SENIOR FIX: The beautifully spaced 3-button layout
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildActionBtn(context, 'Read Quran', Icons.auto_stories_rounded, _kBlue, 
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadQuranScreen()))),
                              const SizedBox(width: 12),
                              _buildActionBtn(context, 'Daily', Icons.wb_sunny_rounded, _kGold, 
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyInspirationScreen()))),
                              const SizedBox(width: 12),
                              _buildActionBtn(context, 'Saved', Icons.bookmark_rounded, _kGreen, 
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookmarksScreen()))),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 16, indent: 20, endIndent: 20),
                      ],
                    ),
                  ),
                  surahsAsync.when(
                    data: _buildList,
                    loading: () => const _ShimmerList(),
                    error: (e, _) => SliverFillRemaining(child: _buildError(e)),
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
    final q = _query.toLowerCase();
    
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
      padding: const EdgeInsets.only(bottom: 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) return const Divider(height: 1, thickness: 1, color: Color(0x0CFFFFFF), indent: 72);
            final i = index ~/ 2;
            return _AnimatedRow(index: i, child: _SurahRow(surah: list[i]));
          },
          childCount: list.length * 2 - 1,
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
            style: OutlinedButton.styleFrom(foregroundColor: _kGreen, side: const BorderSide(color: _kGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry', style: GoogleFonts.outfit()),
          ),
        ]),
      );
}

class _NamazAndQiblaCard extends ConsumerWidget {
  const _NamazAndQiblaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(prayerTimesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: prayerAsync.when(
              data: (prayerTimes) {
                final nextPrayer = prayerTimes.nextPrayer();
                final time = prayerTimes.timeForPrayer(nextPrayer);
                final name = nextPrayer == Prayer.none ? 'Isha' : nextPrayer.name.toUpperCase();
                final timeStr = time != null ? DateFormat.jm().format(time) : '--:--';

                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('NEXT PRAYER', style: GoogleFonts.outfit(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new_rounded, color: Colors.white24, size: 10),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$name • $timeStr', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2)),
              ),
              error: (_, __) => Text('Prayer times offline', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold.withValues(alpha: 0.15),
              foregroundColor: _kGold,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.explore_rounded, size: 18),
            label: Text('Qibla', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
          )
        ],
      ),
    );
  }
}

class _SurahRow extends ConsumerWidget {
  final Surah surah;
  const _SurahRow({required this.surah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(bookmarksProvider).any((b) => b.surahNumber == surah.number && b.ayahNumber == null);

    return InkWell(
      onTap: () => Navigator.of(context).push(PageRouteBuilder(pageBuilder: (_, __, ___) => SurahDetailScreen(surah: surah), transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child))),
      splashColor: Colors.white.withValues(alpha: 0.03), highlightColor: Colors.white.withValues(alpha: 0.015),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            SizedBox(width: 40, child: Text(surah.number.toString().padLeft(3, '0'), style: GoogleFonts.outfit(fontSize: 13, color: _kGreen, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${surah.ayahCount} verses  ·  ${surah.revelationType}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            Text(surah.nameArabic, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 18, color: _kGold, fontFamily: GoogleFonts.amiri().fontFamily)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final bks = ref.read(bookmarksProvider);
                if (isBookmarked) { ref.read(bookmarksProvider.notifier).updateBookmarks(bks.where((b) => !(b.surahNumber == surah.number && b.ayahNumber == null)).toList());
                } else { ref.read(bookmarksProvider.notifier).updateBookmarks([...bks, Bookmark(id: DateTime.now().millisecondsSinceEpoch.toString(), surahNumber: surah.number, title: surah.name, createdAt: DateTime.now())]); }
              },
              child: Icon(isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: isBookmarked ? _kGreen : Colors.white24, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRow extends StatelessWidget {
  final Widget child;
  final int index;
  const _AnimatedRow({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    if (index > 16) return child; 
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + index * 35),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Transform.translate(offset: Offset(0, 18 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: c)),
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
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(const Color(0xFF161E2E), const Color(0xFF1E2D44), _anim.value)!;
        return SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 140),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Opacity(
                opacity: (1.0 - i * 0.06).clamp(0.2, 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  child: Row(children: [
                    Container(width: 40, height: 14, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 16),
                    Container(width: 120, height: 14, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Container(width: 50, height: 18, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(4))),
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