import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;

// ── Tajweed color map ──────────────────────────────────────────────────────────
const Map<String, Color> _tajweedColors = {
  // Gray — structural / silent
  'ham_wasl':             Color(0xFFAAAAAA),
  'slnt':                 Color(0xFFAAAAAA),
  'laam_shamsiyah':       Color(0xFFAAAAAA),
  // Blue — Madd (elongation)
  'madda_normal':         Color(0xFF537FFF),
  'madda_permissible':    Color(0xFF4050FF),
  'madda_obligatory':     Color(0xFF2144C1),
  'madda_necessary':      Color(0xFF000EBC),
  // Red — Qalqalah
  'qalaqah':              Color(0xFFDD0000),
  'qalaqala':             Color(0xFFDD0000),
  'qlq':                  Color(0xFFDD0000),
  // Magenta — Ikhfa
  'ikhafa':               Color(0xFFD500B2),
  'ikhf':                 Color(0xFFD500B2),
  'ikhafa_shafawi':       Color(0xFFD500B2),
  'ikhf_shafawi':         Color(0xFFD500B2),
  // Green — Idgham
  'idgham_ghunnah':       Color(0xFF169200),
  'idgham_wo_ghunnah':    Color(0xFF169200),
  'idgham_shafawi':       Color(0xFF169200),
  'idgh_ghn':             Color(0xFF169200),
  'idgh_w_ghn':           Color(0xFF169200),
  'idgh_shafawi':         Color(0xFF169200),
  // Orange — Ghunnah
  'ghunnah':              Color(0xFFFF7E1E),
  'ghn':                  Color(0xFFFF7E1E),
  // Cyan — Iqlab
  'iqlab':                Color(0xFF26BFFD),
  'iqlb':                 Color(0xFF26BFFD),
};

class ReadQuranScreen extends ConsumerStatefulWidget {
  const ReadQuranScreen({super.key});

  @override
  ConsumerState<ReadQuranScreen> createState() => _ReadQuranScreenState();
}

class _ReadQuranScreenState extends ConsumerState<ReadQuranScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _uthmaniController;
  late PageController _indoPakController;
  late PageController _tajweedController;
  late AnimationController _sheetAnimController;
  
  bool _isImmersive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _uthmaniController = PageController(initialPage: 0);
    _indoPakController = PageController(initialPage: 0);
    _tajweedController = PageController(initialPage: 0);
    _sheetAnimController = BottomSheet.createAnimationController(this)
      ..duration = const Duration(milliseconds: 420)
      ..reverseDuration = const Duration(milliseconds: 320);
  }

  void _toggleImmersiveMode() {
    setState(() {
      _isImmersive = !_isImmersive;
    });
    if (_isImmersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _openSurahIndexSheet() async {
    // Keep local state inside the sheet to avoid polluting screen state.
    final searchController = TextEditingController();
    final searchFocusNode = FocusNode();
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: _sheetAnimController,
      builder: (context) {
        final surahsAsync = ref.watch(surahsProvider);

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _kBg.withValues(alpha: 0.98),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: SafeArea(
                top: false,
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    List<Surah> filter(List<Surah> list) {
                      final q = query.trim().toLowerCase();
                      if (q.isEmpty) return list;
                      return list.where((s) {
                        return s.number.toString() == q ||
                            s.name.toLowerCase().contains(q) ||
                            s.nameArabic.toLowerCase().contains(q) ||
                            s.nameTranslation.toLowerCase().contains(q);
                      }).toList();
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Surahs',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Search',
                                onPressed: () {
                                  FocusScope.of(context).requestFocus(searchFocusNode);
                                },
                                icon: const Icon(Icons.search_rounded, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onChanged: (v) => setSheetState(() => query = v),
                            style: GoogleFonts.manrope(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search surah by name or number…',
                              hintStyle: GoogleFonts.manrope(color: Colors.white38, fontWeight: FontWeight.w600),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: _kGold.withValues(alpha: 0.35)),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: surahsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(color: _kGreen),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Failed to load surahs.\n$e',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            data: (surahs) {
                              final list = filter(surahs);
                              if (list.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No surahs found',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  height: 1,
                                ),
                                itemBuilder: (context, i) {
                                  final s = list[i];
                                  return ListTile(
                                    onTap: () {
                                      // Stay in Read Quran: jump to surah's start page.
                                      Navigator.of(context).pop();
                                      _jumpToSurah(s);
                                    },
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _kGold.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _kGold.withValues(alpha: 0.18)),
                                      ),
                                      child: Text(
                                        s.number.toString().padLeft(2, '0'),
                                        style: GoogleFonts.manrope(
                                          color: _kGold,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      s.name,
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${s.nameTranslation} • ${s.ayahCount} verses',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Text(
                                      s.nameArabic,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 18,
                                        fontFamily: GoogleFonts.amiri().fontFamily,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _jumpToSurah(Surah surah) async {
    try {
      final startPage =
          await ref.read(quranApiServiceProvider).fetchSurahStartPage(surah.number);
      final targetIndex = (startPage - 1).clamp(0, 603);

      final controller = _tabController.index == 0
          ? _uthmaniController
          : _tabController.index == 1
              ? _indoPakController
              : _tajweedController;

      if (!controller.hasClients) return;
      controller.jumpToPage(targetIndex);
    } catch (_) {
      // If anything fails, we do nothing (reading still works).
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uthmaniController.dispose();
    _indoPakController.dispose();
    _tajweedController.dispose();
    _sheetAnimController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(), 
            children: [
              _buildMushafEngine('uthmani', _uthmaniController),
              _buildMushafEngine('indopak', _indoPakController),
              _buildTajweedEngine(),
            ],
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isImmersive ? -150 : 0, 
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  decoration: BoxDecoration(
                    color: _kBg.withValues(alpha: 0.75),
                    border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                              onPressed: () {
                                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                Navigator.pop(context);
                              },
                            ),
                            Text(
                              'Read Quran',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Surah list',
                              onPressed: _openSurahIndexSheet,
                              icon: const Icon(Icons.menu_rounded, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        indicatorColor: _kGreen,
                        labelColor: _kGreen,
                        unselectedLabelColor: Colors.white38,
                        indicatorWeight: 3,
                        dividerColor: Colors.transparent,
                        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
                        onTap: (_) => setState(() {}),
                        tabs: const [
                          Tab(text: 'Uthmani'),
                          Tab(text: 'Indo-Pak'),
                          Tab(text: 'Tajweed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafEngine(String scriptType, PageController controller) {
    return GestureDetector(
      onTap: _toggleImmersiveMode, 
      child: PageView.builder(
        controller: controller,
        reverse: true, 
        itemCount: 604,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final asyncPage = ref.watch(mushafPageProvider((pageNum, scriptType)));

          return asyncPage.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _kGreen)),
            error: (e, _) => _buildErrorState(e.toString()),
            data: (pageText) {
              if (pageText.startsWith('Offline') || pageText.startsWith('Error')) {
                return _buildErrorState(pageText);
              }

              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                padding: EdgeInsets.fromLTRB(16, _isImmersive ? 40 : 140, 16, 40),
                child: _buildOrnamentalFrame(
                  scriptType: scriptType,
                  text: pageText,
                  pageNum: pageNum,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Tajweed Engine ──────────────────────────────────────────────────────────
  Widget _buildTajweedEngine() {
    return GestureDetector(
      onTap: _toggleImmersiveMode,
      child: PageView.builder(
        controller: _tajweedController,
        reverse: true,
        itemCount: 604,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final asyncPage = ref.watch(tajweedPageProvider(pageNum));

          return asyncPage.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _kGreen)),
            error: (e, _) => _buildErrorState(e.toString()),
            data: (verses) {
              if (verses.isEmpty) {
                return _buildErrorState('No data for this page.');
              }

              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                padding: EdgeInsets.fromLTRB(16, _isImmersive ? 40 : 140, 16, 40),
                child: _buildTajweedFrame(verses, pageNum),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTajweedFrame(List<Map<String, String>> verses, int pageNum) {
    // Build all verse spans into a single RichText block
    final List<InlineSpan> allSpans = [];

    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      final ayahNum = verse['verse_key']!.split(':')[1];
      final html = verse['text'] ?? '';

      // Parse tajweed HTML into colored spans
      allSpans.addAll(_parseTajweedHtml(html));

      // Add ayah number marker
      allSpans.add(TextSpan(
        text: ' ﴿${_convertToArabicNumber(ayahNum)}﴾ ',
        style: TextStyle(
          color: _kGold.withValues(alpha: 0.7),
          fontSize: 20,
          fontFamily: GoogleFonts.amiri().fontFamily,
        ),
      ));

      // Add space between verses
      if (i < verses.length - 1) {
        allSpans.add(const TextSpan(text: ' '));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: _kGold.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: _kGold.withValues(alpha: 0.15), width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(top: 10, left: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),
          Positioned(top: 10, right: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),
          Positioned(bottom: 10, left: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),
          Positioned(bottom: 10, right: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: RichText(
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 26,
                    height: 2.2,
                    fontFamily: GoogleFonts.amiri().fontFamily,
                  ),
                  children: allSpans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Parses tajweed HTML like:
  ///   بِسْمِ <tajweed class=ham_wasl>ٱ</tajweed>للَّهِ
  /// Into a list of TextSpans with appropriate colors.
  List<TextSpan> _parseTajweedHtml(String html) {
    final spans = <TextSpan>[];
    // Also handle <span class=end> for verse end markers (we skip those — we add our own)
    final regex = RegExp(r'<(tajweed|span)\s+class=([^>]+)>(.*?)</\1>', dotAll: true);

    int lastEnd = 0;
    for (final match in regex.allMatches(html)) {
      // Add plain text before this tag
      if (match.start > lastEnd) {
        final plain = html.substring(lastEnd, match.start);
        if (plain.isNotEmpty) {
          spans.add(TextSpan(text: plain));
        }
      }

      final tag = match.group(1)!;
      final cssClass = match.group(2)!.trim();
      final innerText = match.group(3)!;

      if (tag == 'span' && cssClass == 'end') {
        // Skip — we add our own ayah number markers
      } else {
        final color = _tajweedColors[cssClass];
        spans.add(TextSpan(
          text: innerText,
          style: color != null ? TextStyle(color: color) : null,
        ));
      }

      lastEnd = match.end;
    }

    // Add remaining plain text
    if (lastEnd < html.length) {
      final remaining = html.substring(lastEnd);
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(text: remaining));
      }
    }

    return spans;
  }

  Widget _buildOrnamentalFrame({required String scriptType, required String text, required int pageNum}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F18), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: _kGold.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5)
        ]
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: _kGold.withValues(alpha: 0.15), width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(top: 10, left: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),
          Positioned(top: 10, right: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),
          Positioned(bottom: 10, left: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),
          Positioned(bottom: 10, right: 10, child: Icon(Icons.star_border_rounded, color: _kGold.withValues(alpha: 0.4), size: 20)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                text,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: scriptType == 'indopak' ? 24 : 28, 
                  height: 2.2, 
                  fontFamily: GoogleFonts.amiri().fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.white54,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _convertToArabicNumber(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}