import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:quran_recitation/providers/providers.dart';

const _kGreen = Color(0xFF10B981);
const _kBg = Color(0xFF05080F);
const _kCard = Color(0xFF121B2B);

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Prayer Times', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: prayerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _kGreen)),
          error: (e, _) => Center(child: Text('Error loading times', style: GoogleFonts.outfit(color: Colors.white54))),
          data: (prayerTimes) {
            final nextPrayer = prayerTimes.nextPrayer();
            final highlightPrayer = nextPrayer == Prayer.none ? Prayer.isha : nextPrayer;

            return Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                locationAsync.when(
                  data: (coords) => Text(
                    '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}',
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13, letterSpacing: 1),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isHighlighted ? _kGreen.withValues(alpha: 0.15) : _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? _kGreen.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: GoogleFonts.outfit(
                color: isHighlighted ? _kGreen : Colors.white,
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
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
              style: GoogleFonts.outfit(
                color: isHighlighted ? Colors.white : Colors.white70,
                fontSize: 18,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}