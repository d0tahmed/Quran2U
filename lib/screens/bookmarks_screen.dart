import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/login_screen.dart';
import 'package:quran_recitation/screens/surah_detail_screen.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';


const _kGreen = AppColorsV2.primary;
const _kGold  = AppColorsV2.tertiary;
const _kBg    = AppColorsV2.bg;

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks    = ref.watch(bookmarksProvider).where((b) => !b.isDeleted).toList();
    final surahsAsync  = ref.watch(surahsProvider);
    final syncState    = ref.watch(bookmarkSyncProvider);
    final loggedInAsync = ref.watch(isLoggedInProvider);

    final isLoggedIn = loggedInAsync.asData?.value ?? false;

    // Wrap in a local ScaffoldMessenger so snackbars (e.g. "Bookmark removed")
    // are scoped ONLY to this screen and are automatically dismissed when the
    // user navigates away — they will never leak to other pages.
    return ScaffoldMessenger(
      child: Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100, right: -50,
            child: Container(
              height: 300, width: 300,
              decoration: BoxDecoration(
                shape:    BoxShape.circle,
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
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context))
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon:        const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                            onPressed:   () => Navigator.pop(context),
                            padding:     EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),

                      // 👇 FIX: Wrapped Title and Badge in Expanded/Flexible to handle 1.3x text scaling
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Saved',
                                style: GoogleFonts.manrope(
                                  color:        AppColorsV2.onSurface,
                                  fontSize:     28,
                                  fontWeight:   FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Item count badge
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:         _kGreen.withValues(alpha: 0.1),
                                  borderRadius:  BorderRadius.circular(12),
                                  border:        Border.all(color: _kGreen.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  '${bookmarks.length} ITEMS',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.manrope(
                                    color:      _kGreen,
                                    fontWeight: FontWeight.w900,
                                    fontSize:   10,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 👆 END FIX

                      const SizedBox(width: 10),

                      // ── Cloud sync button ─────────────────────────────────
                      _SyncButton(isLoggedIn: isLoggedIn),
                    ],
                  ),
                ),

                // ── Sync status banner ──────────────────────────────────────
                if (syncState.status != SyncStatus.idle)
                  _SyncStatusBanner(syncState: syncState),

                const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),

                // ── Not logged in nudge ─────────────────────────────────────
                if (!isLoggedIn)
                  _LoginNudgeBanner(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),

                // ── Bookmark list ───────────────────────────────────────────
                Expanded(
                  child: bookmarks.isEmpty
                      ? _buildEmptyState()
                      : surahsAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator(color: _kGreen)),
                          error: (e, _) => Center(
                              child: Text('Error loading data',
                                  style: GoogleFonts.manrope(color: Colors.white54))),
                          data: (surahs) {
                            final sorted = bookmarks.toList()
                              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                            return ListView.builder(
                              padding: const EdgeInsets.only(top: 16, bottom: 32),
                              physics: const BouncingScrollPhysics(),
                              itemCount: sorted.length,
                              itemBuilder: (context, index) {
                                final bookmark = sorted[index];
                                final surah = surahs.firstWhere(
                                  (s) => s.number == bookmark.surahNumber,
                                  orElse: () => surahs.first,
                                );
                                return _BookmarkTile(
                                  bookmark: bookmark,
                                  surah:    surah,
                                  isCloud:  bookmark.isSynced,
                                );
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
    ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:    const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0x05FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white12, size: 64),
          ),
          const SizedBox(height: 24),
          Text('No Saved Items',
              style: GoogleFonts.manrope(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Your bookmarked Surahs\nwill appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color:      AppColorsV2.onSurfaceVariant,
              fontSize:   14,
              height:     1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Cloud sync button
// ══════════════════════════════════════════════════════════════════════════════
class _SyncButton extends ConsumerWidget {
  final bool isLoggedIn;
  const _SyncButton({required this.isLoggedIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(bookmarkSyncProvider);
    final isSyncing = syncState.status == SyncStatus.syncing;

    return GestureDetector(
      onTap: isSyncing
          ? null
          : () async {
              if (!isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                return;
              }
              await ref.read(bookmarkSyncProvider.notifier).syncToCloud();
              // Auto-reset success message after 3 s
              Future.delayed(const Duration(seconds: 3), () {
                if (context.mounted) {
                  ref.read(bookmarkSyncProvider.notifier).reset();
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSyncing
              ? _kGreen.withValues(alpha: 0.06)
              : _kGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _kGreen.withValues(alpha: isSyncing ? 0.15 : 0.3),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          isSyncing
              ? const SizedBox(
                  width:  13, height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kGreen),
                )
              : const Icon(Icons.cloud_sync_rounded, color: _kGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            isSyncing ? 'Syncing…' : 'Sync',
            style: GoogleFonts.manrope(
              color:      _kGreen,
              fontSize:   12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sync status banner (shown below header when sync is running / done / errored)
// ══════════════════════════════════════════════════════════════════════════════
class _SyncStatusBanner extends StatelessWidget {
  final SyncState syncState;
  const _SyncStatusBanner({required this.syncState});

  @override
  Widget build(BuildContext context) {
    final isError   = syncState.status == SyncStatus.error;
    final isSuccess = syncState.status == SyncStatus.success;
    final isSyncing = syncState.status == SyncStatus.syncing;

    final color = isError
        ? Colors.redAccent
        : (isSuccess ? _kGreen : AppColorsV2.onSurfaceVariant);

    final icon = isError
        ? Icons.error_outline_rounded
        : (isSuccess ? Icons.check_circle_outline_rounded : Icons.sync_rounded);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin:  const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:         color.withValues(alpha: 0.08),
        borderRadius:  BorderRadius.circular(12),
        border:        Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(children: [
        isSyncing
            ? SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            syncState.message ?? '',
            style: GoogleFonts.manrope(
              color:      color,
              fontSize:   12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Login nudge banner (shown when user is not signed in)
// ══════════════════════════════════════════════════════════════════════════════
class _LoginNudgeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginNudgeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.fromLTRB(20, 10, 20, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:         _kGold.withValues(alpha: 0.06),
          borderRadius:  BorderRadius.circular(14),
          border:        Border.all(color: _kGold.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            padding:    const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:         _kGold.withValues(alpha: 0.12),
              borderRadius:  BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_upload_rounded, color: _kGold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sync with Quran.com',
                  style: GoogleFonts.manrope(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w800,
                  )),
              Text('Sign in to back up your bookmarks to the cloud.',
                  style: GoogleFonts.manrope(
                    color:      AppColorsV2.onSurfaceVariant,
                    fontSize:   11,
                    height:     1.4,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bookmark tile (dismissible, with optional cloud badge)
// ══════════════════════════════════════════════════════════════════════════════
class _BookmarkTile extends ConsumerWidget {
  final dynamic bookmark;
  final dynamic surah;
  final bool    isCloud;

  const _BookmarkTile({
    required this.bookmark,
    required this.surah,
    this.isCloud = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(bookmark.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment:  Alignment.centerRight,
        padding:    const EdgeInsets.only(right: 24),
        margin:     const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color:         Colors.redAccent.withValues(alpha: 0.2),
          borderRadius:  BorderRadius.circular(16),
          border:        Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        ref.read(bookmarksProvider.notifier).removeBookmarkById(bookmark.id);
        // Clear any queued snackbars first so rapid deletions don't pile up
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:          Text('Bookmark removed',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
          backgroundColor:  AppColorsV2.surfaceLow,
          behavior:         SnackBarBehavior.floating,
          shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration:         const Duration(seconds: 2),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color:        AppColorsV2.surfaceLow.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () => Navigator.of(context).push(PageRouteBuilder(
              pageBuilder:        (_, __, ___) => SurahDetailScreen(surah: surah),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
            )),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 42, width: 42,
                  decoration: BoxDecoration(
                    color:         _kGreen.withValues(alpha: 0.1),
                    borderRadius:  BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.menu_book_rounded, color: _kGreen, size: 20),
                ),
                // Cloud badge — shown if this bookmark came from cloud sync
                if (isCloud)
                  Positioned(
                    right: -4, bottom: -4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                        color:        AppColorsV2.surfaceLow,
                        shape:        BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.cloud_done_rounded,
                          color: _kGold, size: 12),
                    ),
                  ),
              ],
            ),
            title: Text(
              surah.name,
              style: GoogleFonts.manrope(
                color:        AppColorsV2.onSurface,
                fontSize:     16,
                fontWeight:   FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            subtitle: Row(children: [
              Expanded(
                child: Text(
                  'Saved on ${DateFormat('MMM d, yyyy').format(bookmark.createdAt)}',
                  style: GoogleFonts.manrope(
                    color:      AppColorsV2.onSurfaceVariant,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (bookmark.ayahNumber != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:         _kGreen.withValues(alpha: 0.1),
                    borderRadius:  BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Ayah ${bookmark.ayahNumber}',
                    style: GoogleFonts.manrope(
                      color:      _kGreen,
                      fontSize:   10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ]),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ),
        ),
      ),
    );
  }
}