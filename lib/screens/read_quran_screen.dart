import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/providers/providers.dart';

const _kGreen = Color(0xFF10B981);
const _kGold = Color(0xFFEAB308);
const _kBg = Color(0xFF05080F);

class ReadQuranScreen extends ConsumerStatefulWidget {
  const ReadQuranScreen({super.key});

  @override
  ConsumerState<ReadQuranScreen> createState() => _ReadQuranScreenState();
}

class _ReadQuranScreenState extends ConsumerState<ReadQuranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _uthmaniController;
  late PageController _indoPakController;
  
  int _currentUthmaniPage = 1;
  int _currentIndoPakPage = 1;
  
  bool _isImmersive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _uthmaniController = PageController(initialPage: 0);
    _indoPakController = PageController(initialPage: 0);
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

  @override
  void dispose() {
    _tabController.dispose();
    _uthmaniController.dispose();
    _indoPakController.dispose();
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
              _buildTajweedPlaceholder(), // SENIOR FIX: Back to the placeholder!
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
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: () {
                                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                Navigator.pop(context);
                              },
                            ),
                            Text('Read Quran', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
                            const Spacer(),
                            // Dynamic Page Indicator
                            AnimatedBuilder(
                              animation: _tabController,
                              builder: (context, _) {
                                if (_tabController.index == 2) return const SizedBox.shrink(); // Hide on Tajweed tab
                                final page = _tabController.index == 0 ? _currentUthmaniPage : _currentIndoPakPage;
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _kGold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _kGold.withValues(alpha: 0.2)),
                                  ),
                                  child: Text('Page $page / 604', style: GoogleFonts.outfit(color: _kGold, fontWeight: FontWeight.bold, fontSize: 12)),
                                );
                              },
                            )
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
                        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
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
        onPageChanged: (index) {
          setState(() {
            if (scriptType == 'uthmani') _currentUthmaniPage = index + 1;
            if (scriptType == 'indopak') _currentIndoPakPage = index + 1;
          });
        },
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
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // SENIOR FIX: The updated placeholder text
  Widget _buildTajweedPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette_rounded, color: _kGreen, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Tajweed Engine', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Color-coded pronunciation rules will be\navailable later in the next big update!', 
              textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}