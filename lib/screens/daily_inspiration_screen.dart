import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/data/daily_inspiration_data.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/screens/share_ayah_screen.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;
const _kCard = AppColorsV2.surfaceLow;

class DailyInspirationScreen extends StatelessWidget {
  const DailyInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Shared with NotificationService, so the notification and the screen can
    // never disagree about what today's ayah is. See daily_inspiration_data.dart.
    final todayData = todayInspiration;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background ambient glow
          Positioned(
            top: -100, left: -50, right: -50,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kGold.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              // Was NeverScrollableScrollPhysics, which meant a long hadith on
              // a short screen simply overflowed with no way to reach it.
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text('Daily Inspiration',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6)),
                            ),
                          ],
                        ),
                        Text('A daily dose of Quran & Sunnah',
                            style: GoogleFonts.manrope(
                                color: AppColorsV2.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),

                        // ── Ayah of the Day ──────────────────────────────
                        Row(children: [
                          const Icon(Icons.menu_book_rounded, color: _kGold, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('Ayah of the Day',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                    color: _kGold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Share as image',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShareAyahScreen(
                                  arabic: todayData.arabicAyah,
                                  translation: todayData.translationAyah,
                                  referenceOverride: todayData.referenceAyah,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.ios_share_rounded,
                                color: _kGold, size: 17),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                                width: 32, height: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        GlassPanel(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          tint: _kCard,
                          border: Border.all(color: _kGold.withValues(alpha: 0.18), width: 1.5),
                          child: Column(children: [
                            Text(
                              todayData.arabicAyah,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              maxLines: 6,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  height: 1.9,
                                  fontFamily: AppTypeV2.amiriFamily),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            Text(
                              '"${todayData.translationAyah}"',
                              textAlign: TextAlign.center,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 12),
                            Text(todayData.referenceAyah,
                                style: GoogleFonts.manrope(
                                    color: _kGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ]),
                        ),

                        const SizedBox(height: 32),

                        // ── Hadith of the Day ─────────────────────────────
                        Row(children: [
                          const Icon(Icons.chat_bubble_rounded,
                              color: _kGreen, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('Hadith of the Day',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                    color: _kGreen,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5)),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        GlassPanel(
                          padding: const EdgeInsets.all(20),
                          borderRadius: BorderRadius.circular(24),
                          tint: _kCard,
                          border: Border.all(color: _kGreen.withValues(alpha: 0.18), width: 1.5),
                          child: Column(children: [
                            Text(
                              '"${todayData.hadithText}"',
                              textAlign: TextAlign.center,
                              maxLines: 7,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.6,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            Text(todayData.referenceHadith,
                                style: GoogleFonts.manrope(
                                    color: _kGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ]),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
