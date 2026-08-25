// lib/screens/hifz_screen.dart
//
// The Hifz home: what is due, what is held, and where to start.
//
// The order of this screen is the argument it makes. Review comes FIRST and
// new memorisation second, because the failure mode of every hifz app is a
// long list of surahs "memorised" months ago and never heard again. Putting
// "learn something new" at the top rewards the part that feels like progress
// and quietly lets the rest decay.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/data/quran_surah_data.dart';
import 'package:quran_recitation/screens/hifz_session_screen.dart';
import 'package:quran_recitation/services/hifz_storage.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

/// How many ayat one session covers. Long enough to be worth opening, short
/// enough to finish — an unbounded review queue is a queue nobody starts.
const int _kSessionSize = 12;

class HifzScreen extends ConsumerStatefulWidget {
  const HifzScreen({super.key});

  @override
  ConsumerState<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends ConsumerState<HifzScreen> {
  HifzProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await HifzStorage.load();
    if (mounted) setState(() => _progress = p);
  }

  Future<void> _openSession(List<HifzTarget> targets, String title) async {
    if (targets.isEmpty) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => HifzSessionScreen(targets: targets, title: title),
      ),
    );
    if (mounted) _load();
  }

  void _startReview() {
    final p = _progress;
    if (p == null) return;
    final targets = p.due
        .take(_kSessionSize)
        .map((a) => HifzTarget(a.surah, a.ayah))
        .toList();
    _openSession(targets, 'Review');
  }

  Future<void> _pickSurah() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _SurahPickerSheet(),
    );
    if (chosen == null || !mounted) return;

    final p = _progress;
    if (p == null) return;

    final info = kSurahs[chosen - 1];
    final start = p.nextUnlearned(chosen, info.ayahCount);

    final targets = <HifzTarget>[];
    for (var a = start; a <= info.ayahCount && targets.length < _kSessionSize; a++) {
      targets.add(HifzTarget(chosen, a));
    }
    _openSession(targets, info.name);
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hifz', style: AppTypeV2.title(size: 16)),
      ),
      body: p == null
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColorsV2.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColorsV2.primary,
              backgroundColor: AppColorsV2.surfaceHigh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
                children: [
                  _Headline(progress: p),
                  const SizedBox(height: 18),
                  _DueCard(progress: p, onStart: _startReview),
                  const SizedBox(height: 12),
                  _NewCard(onPick: _pickSurah),
                  if (p.trackedCount > 0) ...[
                    const SizedBox(height: 26),
                    const QSectionHeader(label: 'Surahs in progress'),
                    const SizedBox(height: 12),
                    _SurahProgressList(
                      progress: p,
                      onOpen: (surah) {
                        final info = kSurahs[surah - 1];
                        final targets = <HifzTarget>[];
                        // Reviewing a surah means everything tracked in it,
                        // weakest first — not the whole surah, most of which
                        // has never been touched.
                        final mine = p.ayat.values
                            .where((a) => a.surah == surah)
                            .toList()
                          ..sort((x, y) => x.strength.compareTo(y.strength));
                        for (final a in mine.take(_kSessionSize)) {
                          targets.add(HifzTarget(a.surah, a.ayah));
                        }
                        _openSession(targets, info.name);
                      },
                    ),
                  ],
                  const SizedBox(height: 26),
                  const _HowItWorks(),
                ],
              ),
            ),
    );
  }
}

// ── Headline ────────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  final HifzProgress progress;
  const _Headline({required this.progress});

  /// 6236, the number of ayat in the Quran. Derived rather than typed so it
  /// can never drift from the dataset the rest of the app uses, and `final`
  /// rather than a getter so the fold runs once for the life of the process
  /// instead of twice per build.
  static final int _totalAyat =
      kSurahs.fold<int>(0, (sum, s) => sum + s.ayahCount);

  @override
  Widget build(BuildContext context) {
    final firm = progress.firmCount;
    final learning = progress.learningCount;
    final pct = _totalAyat == 0 ? 0.0 : firm / _totalAyat;

    return FrostedCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      accent: AppColorsV2.primary,
      edgeColor: AppColorsV2.primary,
      edgeIntensity: 0.32,
      glow: firm > 0 ? AppColorsV2.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(value: '$firm', label: 'held firmly'),
              _VDivider(),
              _Stat(value: '$learning', label: 'still learning'),
              _VDivider(),
              _Stat(value: '${progress.due.length}', label: 'due today'),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColorsV2.surfaceHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColorsV2.primary),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            firm == 0
                ? 'Nothing held yet. One ayah is a start.'
                : '$firm of $_totalAyat ayat — '
                    '${(pct * 100).toStringAsFixed(pct < 0.01 ? 2 : 1)}% of the Quran',
            style: AppTypeV2.caption(
                size: 11, color: AppColorsV2.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypeV2.display(size: 28)),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypeV2.caption(
                size: 10, color: AppColorsV2.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColorsV2.hairline,
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );
}

// ── The two entry points ────────────────────────────────────────────────────

class _DueCard extends StatelessWidget {
  final HifzProgress progress;
  final VoidCallback onStart;

  const _DueCard({required this.progress, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final due = progress.due.length;
    final ready = due > 0;

    return FrostedCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      accent: ready ? AppColorsV2.tertiary : null,
      edgeColor: ready ? AppColorsV2.tertiary : null,
      edgeIntensity: ready ? 0.32 : 0.18,
      onTap: ready ? onStart : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (ready ? AppColorsV2.tertiary : AppColorsV2.onSurfaceVariant)
                  .withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              ready ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
              size: 21,
              color: ready ? AppColorsV2.tertiary : AppColorsV2.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Review what is slipping' : 'Nothing due today',
                  style: AppTypeV2.title(size: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  ready
                      ? '$due ayat ready — '
                          '${due > _kSessionSize ? '$_kSessionSize' : '$due'} '
                          'in this session'
                      : progress.trackedCount == 0
                          ? 'Memorise something first and it will appear here'
                          : 'Everything is on schedule. Come back tomorrow.',
                  maxLines: 2,
                  style: AppTypeV2.caption(
                      size: 11, color: AppColorsV2.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (ready)
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppColorsV2.tertiary),
        ],
      ),
    );
  }
}

class _NewCard extends StatelessWidget {
  final VoidCallback onPick;
  const _NewCard({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      onTap: onPick,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColorsV2.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add_rounded,
                size: 21, color: AppColorsV2.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Memorise something new',
                    style: AppTypeV2.title(size: 14.5)),
                const SizedBox(height: 3),
                Text(
                  'Pick a surah and start from where you left off',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.caption(
                      size: 11, color: AppColorsV2.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded,
              size: 18, color: AppColorsV2.primary),
        ],
      ),
    );
  }
}

// ── Surahs in progress ──────────────────────────────────────────────────────

class _SurahProgressList extends StatelessWidget {
  final HifzProgress progress;
  final ValueChanged<int> onOpen;

  const _SurahProgressList({required this.progress, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final counts = progress.bySurah;
    final firm = progress.firmBySurah;

    // Most complete first — someone scanning this wants to see how close they
    // are to finishing something, not surah 2 forever at the top.
    final surahs = counts.keys.toList()
      ..sort((a, b) {
        final pa = counts[a]! / kSurahs[a - 1].ayahCount;
        final pb = counts[b]! / kSurahs[b - 1].ayahCount;
        return pb.compareTo(pa);
      });

    return Column(
      children: [
        for (final s in surahs) ...[
          _SurahRow(
            info: kSurahs[s - 1],
            tracked: counts[s] ?? 0,
            firm: firm[s] ?? 0,
            onTap: () => onOpen(s),
          ),
          if (s != surahs.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SurahRow extends StatelessWidget {
  final SurahInfo info;
  final int tracked;
  final int firm;
  final VoidCallback onTap;

  const _SurahRow({
    required this.info,
    required this.tracked,
    required this.firm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = tracked / info.ayahCount;
    final complete = tracked >= info.ayahCount && firm >= info.ayahCount;

    return FrostedCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      onTap: onTap,
      edgeColor: complete ? AppColorsV2.primary : null,
      edgeIntensity: complete ? 0.30 : 0.16,
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${info.number}',
                  style: AppTypeV2.caption(
                      size: 12, color: AppColorsV2.onSurfaceVariant),
                ),
              ),
              Expanded(
                child: Text(
                  info.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.title(size: 13.5),
                ),
              ),
              const SizedBox(width: 8),
              if (complete)
                const Icon(Icons.verified_rounded,
                    size: 15, color: AppColorsV2.primary)
              else
                Text(
                  '$tracked / ${info.ayahCount}',
                  style: AppTypeV2.caption(
                      size: 11, color: AppColorsV2.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColorsV2.surfaceHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                firm >= tracked
                    ? AppColorsV2.primary
                    : AppColorsV2.primary.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Surah picker ────────────────────────────────────────────────────────────

class _SurahPickerSheet extends StatefulWidget {
  const _SurahPickerSheet();

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = kSurahs.where((s) {
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.meaning.toLowerCase().contains(q) ||
          s.nameArabic.contains(_query.trim()) ||
          '${s.number}' == q;
    }).toList(growable: false);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => GlassSurface(
        tier: GlassTier.sheet,
        borderRadius: kGlassSheetRadius,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Center(child: GlassGrabber()),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTypeV2.title(size: 14, weight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search 114 surahs',
                  hintStyle: AppTypeV2.body(size: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 19, color: AppColorsV2.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColorsV2.surfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No surah matches "$_query"',
                          style: AppTypeV2.body(size: 13)),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      itemCount: list.length,
                      // Fixed row height, so the sheet can scroll 114 rows
                      // without measuring each one as it arrives.
                      itemExtent: 62,
                      addAutomaticKeepAlives: false,
                      itemBuilder: (context, i) {
                        final s = list[i];
                        return _PickerRow(
                          info: s,
                          onTap: () => Navigator.of(context).pop(s.number),
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

class _PickerRow extends StatelessWidget {
  final SurahInfo info;
  final VoidCallback onTap;

  const _PickerRow({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FrostedCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${info.number}',
                style: AppTypeV2.caption(
                    size: 12, color: AppColorsV2.tertiary),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeV2.title(size: 13.5),
                  ),
                  Text(
                    '${info.meaning} · ${info.ayahCount} ayat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeV2.caption(
                        size: 10.5, color: AppColorsV2.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              info.nameArabic,
              style: AppTypeV2.arabic(size: 16, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Explainer ───────────────────────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: AppColorsV2.tertiary),
              const SizedBox(width: 9),
              Text('How the review schedule works',
                  style: AppTypeV2.title(size: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Every ayah you recall correctly comes back later than the last '
            'time — after a day, then two, four, eight, sixteen, thirty-two. '
            'One you stumble on returns sooner, but never all the way back to '
            'the start: holding an ayah for a month and slipping once is not '
            'the same as never having learnt it.',
            style: AppTypeV2.body(size: 12, height: 1.65),
          ),
        ],
      ),
    );
  }
}
