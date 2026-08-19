import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/providers/reading_progress_provider.dart';
import 'package:quran_recitation/screens/surah_detail_screen.dart';
import 'package:quran_recitation/screens/qibla_screen.dart';
import 'package:quran_recitation/screens/prayer_times_screen.dart';
import 'package:quran_recitation/screens/duas_screen.dart';
import 'package:quran_recitation/screens/daily_inspiration_screen.dart';
import 'package:quran_recitation/screens/bookmarks_screen.dart';
import 'package:quran_recitation/screens/downloads_screen.dart';
import 'package:quran_recitation/screens/read_quran_screen.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:quran_recitation/services/hijri_date.dart';
import 'package:quran_recitation/services/time_format.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _short(String name) => name.split(' ').last;

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahsProvider);
    final selectedImam = ref.watch(selectedImamProvider);
    final imams = ref.watch(imamsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notif) {
            if (notif.direction == ScrollDirection.reverse) {
              if (ref.read(navBarVisibleProvider)) {
                ref.read(navBarVisibleProvider.notifier).state = false;
              }
            } else if (notif.direction == ScrollDirection.forward) {
              if (!ref.read(navBarVisibleProvider)) {
                ref.read(navBarVisibleProvider.notifier).state = true;
              }
            }
            return true;
          },
          child: CustomScrollView(
            slivers: [
              // ── Bismillah masthead ──────────────────────────────────────
              const SliverToBoxAdapter(child: _Masthead()),

              // ── Continue reading ────────────────────────────────────────
              const SliverToBoxAdapter(child: _ContinueReadingCard()),

              // ── Prayer strip ────────────────────────────────────────────
              const SliverToBoxAdapter(child: _PrayerStrip()),

              // ── Quick actions ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                  child: Row(
                    children: [
                      _QuickTile(
                        icon: Icons.wb_twilight_rounded,
                        label: 'Daily',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DailyInspirationScreen()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickTile(
                        icon: Icons.bookmark_rounded,
                        label: 'Saved',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BookmarksScreen()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickTile(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'Duas',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DuasScreen()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickTile(
                        icon: Icons.download_rounded,
                        label: 'Offline',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DownloadsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Reciter ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
                  child: QSectionHeader(
                    label: 'Reciter',
                    trailing: selectedImam != null
                        ? Text(
                            _short(selectedImam.name),
                            style: AppTypeV2.caption(
                                size: 11, color: AppColorsV2.primary),
                          )
                        : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: imams.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final imam = imams[i];
                      final sel = selectedImam?.id == imam.id;
                      return _ReciterChip(
                        name: _short(imam.name),
                        selected: sel,
                        onTap: () {
                          ref.read(selectedImamProvider.notifier).state = imam;
                          if (imam.id == 6 || imam.id == 7) {
                            ref.read(tarjumahModeProvider.notifier).state =
                                false;
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              // ── Surah index ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
                  child: QSectionHeader(
                    label: 'The 114 Surahs',
                    trailing: surahsAsync.asData != null
                        ? Text(
                            '${surahsAsync.asData!.value.length}',
                            style: AppTypeV2.caption(
                                size: 11,
                                color: AppColorsV2.onSurfaceVariant
                                    .withValues(alpha: 0.7)),
                          )
                        : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                  child: TextField(
                    controller: _ctrl,
                    style: AppTypeV2.title(size: 13.5, weight: FontWeight.w600),
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or number…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18,
                                  color: AppColorsV2.onSurfaceVariant),
                              onPressed: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
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
            const Icon(Icons.search_off_rounded,
                size: 44, color: AppColorsV2.outlineVariant),
            const SizedBox(height: 12),
            Text('No surahs found', style: AppTypeV2.body(size: 13.5)),
          ]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _AnimatedRow(
            index: index,
            child: _SurahRow(
              surah: list[index],
              isLast: index == list.length - 1,
            ),
          ),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _buildError(Object err) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded,
              size: 44, color: AppColorsV2.outlineVariant),
          const SizedBox(height: 14),
          Text('No connection',
              style: AppTypeV2.title(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Check your internet and try again.',
              style: AppTypeV2.body(size: 12.5)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => ref.refresh(surahsProvider),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsV2.primary,
              side:
                  BorderSide(color: AppColorsV2.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry', style: AppTypeV2.caption(size: 12.5)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Masthead — full Bismillah + dual calendar
// ─────────────────────────────────────────────────────────────────────────────

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijri = HijriDate.fromDate(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        children: [
          // Brand line
          Row(
            children: [
              QStarMedallion(
                size: 26,
                color: AppColorsV2.tertiary.withValues(alpha: 0.5),
                child: Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: const BoxDecoration(
                    color: AppColorsV2.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('QURAN2U', style: AppTypeV2.overline(size: 10.5)),
              const Spacer(),
              if (hijri.isRamadan)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColorsV2.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColorsV2.goldHairline),
                  ),
                  child: Text('RAMADAN',
                      style: AppTypeV2.overline(size: 9, letterSpacing: 1.6)),
                ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Bismillah ────────────────────────────────────────────────
          const QOrnamentDivider(width: 150),
          const SizedBox(height: 16),
          Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTypeV2.arabic(
              size: 30,
              color: AppColorsV2.onSurface,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 14),
          const QOrnamentDivider(width: 150),

          const SizedBox(height: 20),

          // ── Dual calendar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColorsV2.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColorsV2.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TODAY', style: AppTypeV2.overline(size: 9)),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeV2.title(
                            size: 13.5, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: AppColorsV2.hairline,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          hijri.formattedAr,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          style: AppTypeV2.arabic(
                            size: 15,
                            color: AppColorsV2.tertiary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hijri.short,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypeV2.caption(
                          size: 10.5,
                          color: AppColorsV2.onSurfaceVariant
                              .withValues(alpha: 0.75),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Continue reading
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(readingProgressProvider);
    if (progress == null) return const SizedBox.shrink();

    final surahs = ref.watch(surahsProvider).asData?.value ?? const <Surah>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QSectionHeader(label: 'Continue reading'),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () {
              // Resume in the same reader the Read tab opens: Read & Explore →
              // Read Quran. Switching the shell index first means backing out
              // of the mushaf lands on the Read tab, not Home.
              if (progress.hasPage) {
                ref.read(shellIndexProvider.notifier).state = 2;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ReadQuranScreen(
                    initialPage: progress.page,
                    initialTab: progress.scriptTab,
                  ),
                ));
                return;
              }
              // No mushaf page yet — fall back to the surah the user was in.
              final match = surahs
                  .cast<Surah?>()
                  .firstWhere((s) => s?.number == progress.surahNumber,
                      orElse: () => null);
              if (match == null) {
                ref.read(shellIndexProvider.notifier).state = 2;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ReadQuranScreen(),
                ));
                return;
              }
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SurahDetailScreen(surah: match),
              ));
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: AppColorsV2.primary.withValues(alpha: 0.22)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColorsV2.primary.withValues(alpha: 0.13),
                    AppColorsV2.surfaceLow,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      QStarMedallion(
                        size: 46,
                        color: AppColorsV2.primary.withValues(alpha: 0.4),
                        child: Text(
                          progress.hasPage
                              ? '${progress.page}'
                              : '${progress.surahNumber}',
                          style: AppTypeV2.caption(
                              size: 12,
                              color: AppColorsV2.primary,
                              weight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                progress.surahName.isEmpty
                                    ? 'The Holy Quran'
                                    : progress.surahName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypeV2.display(size: 21)),
                            const SizedBox(height: 3),
                            Text(
                              progress.positionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypeV2.caption(
                                  size: 11.5,
                                  color: AppColorsV2.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (progress.surahNameArabic.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Text(
                            progress.surahNameArabic,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypeV2.arabic(
                              size: 22,
                              color:
                                  AppColorsV2.tertiary.withValues(alpha: 0.85),
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress.fraction,
                            minHeight: 4,
                            backgroundColor: AppColorsV2.surfaceHighest,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    AppColorsV2.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${progress.percent}%',
                          maxLines: 1,
                          style: AppTypeV2.caption(
                              size: 11, color: AppColorsV2.primary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.play_circle_fill_rounded,
                          color: AppColorsV2.primary, size: 26),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prayer strip — all six, active highlighted, live countdown
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerStrip extends ConsumerStatefulWidget {
  const _PrayerStrip();

  @override
  ConsumerState<_PrayerStrip> createState() => _PrayerStripState();
}

class _PrayerStripState extends ConsumerState<_PrayerStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _remaining(DateTime target, DateTime now) {
    final diff = target.difference(now);
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final prayerAsync = ref.watch(prayerTimesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QSectionHeader(
            label: 'Prayer times',
            trailing: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QiblaScreen()),
              ),
              borderRadius: BorderRadius.circular(999),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded,
                      size: 13, color: AppColorsV2.primary),
                  const SizedBox(width: 5),
                  Text('Qibla',
                      style: AppTypeV2.caption(
                          size: 11, color: AppColorsV2.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          prayerAsync.when(
            loading: () => Container(
              height: 92,
              decoration: BoxDecoration(
                color: AppColorsV2.surfaceLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColorsV2.hairline),
              ),
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColorsV2.primary),
                ),
              ),
            ),
            error: (_, __) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColorsV2.surfaceLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColorsV2.hairline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded,
                      size: 18, color: AppColorsV2.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Location permission required',
                        style: AppTypeV2.caption(
                            size: 12, color: AppColorsV2.danger)),
                  ),
                ],
              ),
            ),
            data: (times) {
              final now = DateTime.now();
              final entries = <_PrayerEntry>[
                _PrayerEntry('Fajr', times.fajr, Icons.nightlight_round),
                _PrayerEntry('Sunrise', times.sunrise, Icons.wb_twilight_rounded),
                _PrayerEntry('Dhuhr', times.dhuhr, Icons.light_mode_rounded),
                _PrayerEntry('Asr', times.asr, Icons.wb_sunny_rounded),
                _PrayerEntry(
                    'Maghrib', times.maghrib, Icons.wb_twilight_rounded),
                _PrayerEntry('Isha', times.isha, Icons.dark_mode_rounded),
              ];

              // Which cell is "next"? First entry still in the future.
              var activeIndex =
                  entries.indexWhere((e) => e.time.isAfter(now));
              if (activeIndex < 0) activeIndex = 0; // all passed → tomorrow Fajr

              final active = entries[activeIndex];
              final countdown = active.time.isAfter(now)
                  ? _remaining(active.time, now)
                  : _remaining(
                      active.time.add(const Duration(days: 1)), now);

              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                    color: AppColorsV2.surfaceLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColorsV2.hairline),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            Text('NEXT',
                                style: AppTypeV2.overline(size: 9)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                active.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypeV2.title(
                                    size: 14, weight: FontWeight.w800),
                              ),
                            ),
                            const Spacer(),
                            if (countdown.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColorsV2.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('in $countdown',
                                    style: AppTypeV2.caption(
                                        size: 10.5,
                                        color: AppColorsV2.primary)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(entries.length, (i) {
                          final e = entries[i];
                          final isActive = i == activeIndex;
                          return Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColorsV2.primary
                                        .withValues(alpha: 0.14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? AppColorsV2.primary
                                          .withValues(alpha: 0.28)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    e.icon,
                                    size: 13,
                                    color: isActive
                                        ? AppColorsV2.primary
                                        : AppColorsV2.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 5),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      e.name.substring(0,
                                          e.name.length > 4 ? 4 : e.name.length),
                                      maxLines: 1,
                                      style: AppTypeV2.caption(
                                        size: 9,
                                        color: isActive
                                            ? AppColorsV2.primary
                                            : AppColorsV2.onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // 12-hour clock. The meridiem sits on its own
                                  // line so "12:37 PM" can never wrap or shrink
                                  // to an unreadable size in a sixth of the row.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      TimeFormat.hourMinute(e.time),
                                      maxLines: 1,
                                      style: AppTypeV2.caption(
                                        size: 11.5,
                                        color: isActive
                                            ? AppColorsV2.onSurface
                                            : AppColorsV2.onSurfaceVariant,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      TimeFormat.meridiem(e.time),
                                      maxLines: 1,
                                      style: AppTypeV2.caption(
                                        size: 8,
                                        color: isActive
                                            ? AppColorsV2.primary
                                            : AppColorsV2.onSurfaceVariant
                                                .withValues(alpha: 0.6),
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrayerEntry {
  final String name;
  final DateTime time;
  final IconData icon;
  const _PrayerEntry(this.name, this.time, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick access tile
// ─────────────────────────────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColorsV2.surfaceLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColorsV2.hairline),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColorsV2.tertiary, size: 20),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTypeV2.caption(
                      size: 10.5, color: AppColorsV2.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reciter chip
// ─────────────────────────────────────────────────────────────────────────────

class _ReciterChip extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _ReciterChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return QChip(
      label: name,
      selected: selected,
      onTap: onTap,
      leading: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppColorsV2.onPrimary.withValues(alpha: 0.16)
              : AppColorsV2.tertiary.withValues(alpha: 0.12),
        ),
        child: Text(
          name.characters.first.toUpperCase(),
          style: AppTypeV2.caption(
            size: 9.5,
            color: selected ? AppColorsV2.onPrimary : AppColorsV2.tertiary,
            weight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Surah row
// ─────────────────────────────────────────────────────────────────────────────

class _SurahRow extends ConsumerWidget {
  final Surah surah;
  final bool isLast;
  const _SurahRow({required this.surah, this.isLast = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref
        .watch(bookmarksProvider)
        .any((b) => b.surahNumber == surah.number && b.ayahNumber == null);

    return InkWell(
      onTap: () => Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, __, ___) => SurahDetailScreen(surah: surah),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      )),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColorsV2.hairline),
                ),
        ),
        child: Row(children: [
          QStarMedallion(
            size: 42,
            color: AppColorsV2.goldHairline,
            child: Text(
              '${surah.number}',
              style: AppTypeV2.caption(
                size: 11,
                color: AppColorsV2.tertiary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(surah.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeV2.title(
                          size: 14.5, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    '${surah.nameTranslation} · ${surah.ayahCount} verses',
                    style: AppTypeV2.caption(
                        size: 11,
                        color: AppColorsV2.onSurfaceVariant
                            .withValues(alpha: 0.85)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(
              surah.nameArabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypeV2.arabic(
                size: 19,
                color: AppColorsV2.tertiary.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              if (isBookmarked) {
                ref
                    .read(bookmarksProvider.notifier)
                    .removeBookmark(surah.number, null);
              } else {
                ref.read(bookmarksProvider.notifier).addBookmark(
                      Bookmark(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        surahNumber: surah.number,
                        title: surah.name,
                        createdAt: DateTime.now(),
                      ),
                    );
              }
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked
                  ? AppColorsV2.primary
                  : AppColorsV2.onSurfaceVariant.withValues(alpha: 0.45),
              size: 19,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List entrance + shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedRow extends StatelessWidget {
  final Widget child;
  final int index;
  const _AnimatedRow({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    if (index > 16) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + index * 30),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Transform.translate(
        offset: Offset(0, 16 * (1 - v)),
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: c),
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

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(
            AppColorsV2.surfaceLow, AppColorsV2.surfaceHigh, _anim.value)!;
        return SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Opacity(
                opacity: (1.0 - i * 0.06).clamp(0.2, 1.0),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                  child: Row(children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(14))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: 140,
                                height: 11,
                                decoration: BoxDecoration(
                                    color: shimmer,
                                    borderRadius: BorderRadius.circular(6))),
                            const SizedBox(height: 8),
                            Container(
                                width: 190,
                                height: 9,
                                decoration: BoxDecoration(
                                    color: shimmer.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(6))),
                          ]),
                    ),
                    const SizedBox(width: 14),
                    Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(6))),
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
