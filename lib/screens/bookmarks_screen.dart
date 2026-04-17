import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/surah_detail_screen.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

const _kGreen = AppColorsV2.primary;
const _kBg = AppColorsV2.bg;

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final surahsAsync = ref.watch(surahsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100, right: -50,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kGreen.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      // Only show back button if pushed from Home Dashboard (not if accessed from Bottom Nav)
                      if (Navigator.canPop(context))
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      Text(
                        'Saved',
                        style: GoogleFonts.manrope(
                          color: AppColorsV2.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${bookmarks.length} ITEMS',
                          style: GoogleFonts.manrope(
                            color: _kGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
                
                Expanded(
                  child: bookmarks.isEmpty
                      ? _buildEmptyState()
                      : surahsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: _kGreen)),
                          error: (e, _) => Center(child: Text('Error loading data', style: GoogleFonts.manrope(color: Colors.white54))),
                          data: (surahs) {
                            // Sort bookmarks by newest first
                            final sortedBookmarks = bookmarks.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                            return ListView.builder(
                              padding: const EdgeInsets.only(top: 16, bottom: 120),
                              physics: const BouncingScrollPhysics(),
                              itemCount: sortedBookmarks.length,
                              itemBuilder: (context, index) {
                                final bookmark = sortedBookmarks[index];
                                // Find the full Surah object so we can pass it to the Detail Screen
                                final surah = surahs.firstWhere(
                                  (s) => s.number == bookmark.surahNumber,
                                  orElse: () => surahs.first,
                                );

                                return _buildBookmarkTile(context, ref, bookmark, surah);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkTile(BuildContext context, WidgetRef ref, dynamic bookmark, dynamic surah) {
    return Dismissible(
      key: Key(bookmark.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        // Remove from Riverpod state
        final currentBks = ref.read(bookmarksProvider);
        ref.read(bookmarksProvider.notifier).updateBookmarks(currentBks.where((b) => b.id != bookmark.id).toList());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark removed', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
            backgroundColor: AppColorsV2.surfaceLow,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: GlassPanel(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          tint: AppColorsV2.surfaceLow,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () {
            // Navigate to the Surah Detail Screen to listen to audio!
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => SurahDetailScreen(surah: surah),
              transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child)
            ));
          },
          leading: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.menu_book_rounded, color: _kGreen, size: 20),
          ),
          title: Text(
            surah.name,
            style: GoogleFonts.manrope(
              color: AppColorsV2.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: Text('Saved on ${DateFormat('MMM d, yyyy').format(bookmark.createdAt)}', 
            style: GoogleFonts.manrope(color: AppColorsV2.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded, color: Colors.white12, size: 64),
          ),
          const SizedBox(height: 24),
          Text('No Saved Items', style: GoogleFonts.manrope(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Your bookmarked Surahs\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(color: AppColorsV2.onSurfaceVariant, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}