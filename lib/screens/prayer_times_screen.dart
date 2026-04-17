import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

const _kGreen = AppColorsV2.primary;
const _kBg = AppColorsV2.bg;
const _kCard = AppColorsV2.surfaceLow;

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerAsync = ref.watch(prayerTimesProvider);
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prayer Times',
          style: GoogleFonts.manrope(
            color: AppColorsV2.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: _kBg.withValues(alpha: 0.80),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: prayerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _kGreen)),
          error: (e, _) => Center(child: Text('Error loading times', style: GoogleFonts.manrope(color: Colors.white54))),
          data: (prayerTimes) {
            final nextPrayer = prayerTimes.nextPrayer();
            final highlightPrayer = nextPrayer == Prayer.none ? Prayer.isha : nextPrayer;

            return Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.8),
                ),
                const SizedBox(height: 4),
                locationAsync.when(
                  data: (coords) => Text(
                    '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}',
                    style: GoogleFonts.manrope(color: AppColorsV2.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                  ),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
                
                const SizedBox(height: 40),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _PrayerRow(name: 'Fajr', time: prayerTimes.fajr, isHighlighted: highlightPrayer == Prayer.fajr),
                      _PrayerRow(name: 'Sunrise', time: prayerTimes.sunrise, isHighlighted: highlightPrayer == Prayer.sunrise, isSun: true),
                      _PrayerRow(name: 'Dhuhr', time: prayerTimes.dhuhr, isHighlighted: highlightPrayer == Prayer.dhuhr),
                      _PrayerRow(name: 'Asr', time: prayerTimes.asr, isHighlighted: highlightPrayer == Prayer.asr),
                      _PrayerRow(name: 'Maghrib', time: prayerTimes.maghrib, isHighlighted: highlightPrayer == Prayer.maghrib),
                      _PrayerRow(name: 'Isha', time: prayerTimes.isha, isHighlighted: highlightPrayer == Prayer.isha),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool isHighlighted;
  final bool isSun;

  const _PrayerRow({required this.name, required this.time, required this.isHighlighted, this.isSun = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        borderRadius: BorderRadius.circular(20),
        tint: _kCard,
        border: Border.all(
          color: isHighlighted ? _kGreen.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: GoogleFonts.manrope(
                color: isHighlighted ? _kGreen : Colors.white,
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Icon(
            isSun ? Icons.wb_sunny_rounded : Icons.volume_up_rounded, 
            color: isHighlighted ? _kGreen : Colors.white24, 
            size: 20
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat.jm().format(time),
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                color: isHighlighted ? Colors.white : Colors.white70,
                fontSize: 18,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}