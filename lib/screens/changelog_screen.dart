// lib/screens/changelog_screen.dart
//
// What changed, and when.
//
// Design notes:
//  • The newest entry is expanded on open and everything below it is collapsed.
//    Someone opening this screen almost always wants "what's new", not the
//    full history — but the full history should be one tap away, not a
//    different screen.
//  • A left rail with a node per release makes the shape of the project
//    legible at a glance: where the bursts were, where the quiet months were.
//  • The version the phone is actually running is found by asking the build,
//    not by a flag in the data file — so it stays correct without maintenance.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quran_recitation/data/changelog_data.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';

const String _kReleasesUrl = 'https://github.com/d0tahmed/Quran2U/releases';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  /// Version strings that are currently expanded.
  final Set<String> _open = <String>{};

  /// The running build's version, once the platform has told us.
  String? _installed;

  @override
  void initState() {
    super.initState();
    if (kChangelog.isNotEmpty) _open.add(kChangelog.first.version);
    _readVersion();
  }

  Future<void> _readVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _installed = info.version);
    } catch (_) {
      // Not worth surfacing. The screen simply does not mark a current
      // release, which is a strictly smaller loss than an error banner.
    }
  }

  Future<void> _openReleases() async {
    final url = Uri.parse(_kReleasesUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _toggle(String version) {
    setState(() {
      if (!_open.remove(version)) _open.add(version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final installed = _installed;

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("What's new", style: AppTypeV2.title(size: 16)),
        actions: [
          IconButton(
            tooltip: 'Open on GitHub',
            onPressed: _openReleases,
            icon: const Icon(Icons.open_in_new_rounded,
                size: 18, color: AppColorsV2.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 44),
        // +1 for the header card at the top.
        itemCount: kChangelog.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _Header(installed: installed);

          final index = i - 1;
          final entry = kChangelog[index];
          return _ReleaseTile(
            entry: entry,
            expanded: _open.contains(entry.version),
            isInstalled: installed != null && installed == entry.version,
            isMajor: isMajorRelease(index),
            isOriginal: isFirstRelease(index),
            isFirst: i == 1,
            isLast: i == kChangelog.length,
            onTap: () => _toggle(entry.version),
          );
        },
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String? installed;
  const _Header({required this.installed});

  @override
  Widget build(BuildContext context) {
    final first = kChangelog.last;
    final span = DateTime.now().difference(first.date).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: FrostedCard(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        accent: AppColorsV2.tertiary,
        edgeColor: AppColorsV2.tertiary,
        edgeIntensity: 0.30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColorsV2.tertiary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.history_rounded,
                      size: 19, color: AppColorsV2.tertiary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Release history',
                          style: AppTypeV2.title(size: 15)),
                      const SizedBox(height: 2),
                      Text(
                        installed == null
                            ? '${kChangelog.length} releases'
                            : 'You are on $installed',
                        style: AppTypeV2.caption(
                            size: 11, color: AppColorsV2.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              span > 0
                  ? 'Every version since the first release, '
                      '${_months(span)} of work.'
                  : 'Every version since the first release.',
              style: AppTypeV2.body(size: 12.5, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }

  static String _months(int days) {
    final m = (days / 30.44).round();
    if (m <= 1) return 'a month';
    if (m < 12) return '$m months';
    final y = (m / 12).floor();
    final rem = m % 12;
    final years = y == 1 ? 'a year' : '$y years';
    return rem == 0 ? years : '$years and $rem months';
  }
}

// ── One release ─────────────────────────────────────────────────────────────

class _ReleaseTile extends StatelessWidget {
  final ChangelogEntry entry;
  final bool expanded;
  final bool isInstalled;

  /// Crossed a major version boundary (3.x → 4.0.0).
  final bool isMajor;

  /// The oldest entry in the list — the very first release.
  final bool isOriginal;

  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ReleaseTile({
    required this.entry,
    required this.expanded,
    required this.isInstalled,
    required this.isMajor,
    required this.isOriginal,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  static const double _railWidth = 26;
  static const double _nodeSize = 11;

  bool get _highlighted => entry.unreleased || isInstalled || isMajor;

  Color get _accent {
    if (entry.unreleased) return AppColorsV2.tertiary;
    if (isInstalled) return AppColorsV2.primary;
    if (isMajor || isOriginal) return AppColorsV2.tertiary;
    return AppColorsV2.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final major = isMajor || isOriginal || entry.unreleased;

    // A Stack rather than IntrinsicHeight + a stretched Row. IntrinsicHeight
    // would dry-lay-out the whole card — every bullet of text — a second time
    // on each layout, and an expanded release is thirty paragraphs. The rail
    // is a positioned child instead, so it stretches for free.
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _railWidth,
          child: CustomPaint(
            painter: _RailPainter(
              color: AppColorsV2.outlineVariant,
              nodeColor: accent,
              filled: entry.unreleased || isInstalled || major,
              drawTop: !isFirst,
              drawBottom: !isLast,
              nodeSize: _nodeSize,
              // Lines up with the vertical centre of the version row.
              nodeCenterY: 32,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
              left: _railWidth, bottom: isLast ? 0 : 14),
          child: FrostedCard(
            radius: 22,
            padding: EdgeInsets.zero,
            edgeColor: _highlighted || isOriginal ? accent : null,
            edgeIntensity: _highlighted || isOriginal ? 0.34 : 0.18,
            accent: entry.unreleased
                ? AppColorsV2.tertiary
                : isMajor || isOriginal
                    ? AppColorsV2.tertiary.withValues(alpha: 0.55)
                    : null,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _head(accent),
                // AnimatedSize keeps the rail and the card in step while the
                // body opens; a plain if/else would snap.
                AnimatedSize(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? _body()
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _head(Color accent) {
    // The date moved down to the meta line. Version + badges + date + chevron
    // on one row cannot fit on a 360dp phone once a release carries two
    // badges, and something has to give — better the date, which is the least
    // urgent of the four.
    final badges = <Widget>[
      if (entry.unreleased)
        const _Tag(text: 'NEXT', color: AppColorsV2.tertiary),
      if (isInstalled)
        const _Tag(text: 'INSTALLED', color: AppColorsV2.primary),
      if (isMajor)
        const _Tag(text: 'MAJOR UPDATE', color: AppColorsV2.tertiary),
      if (isOriginal)
        const _Tag(text: 'FIRST RELEASE', color: AppColorsV2.tertiary),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    Text(
                      'v${entry.version}',
                      style: AppTypeV2.title(
                        size: 16,
                        weight: FontWeight.w800,
                        color: _highlighted || isOriginal
                            ? accent
                            : AppColorsV2.onSurface,
                      ),
                    ),
                    ...badges,
                  ],
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 190),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: AppColorsV2.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            entry.headline,
            style: AppTypeV2.body(
                size: 12.5, height: 1.45, color: AppColorsV2.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.unreleased ? "Unreleased" : DateFormat('d MMM yyyy').format(entry.date)}'
            '  ·  ${entry.changeCount} '
            '${entry.changeCount == 1 ? "change" : "changes"}',
            style: AppTypeV2.caption(
                size: 10.5,
                color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: GlassDivider(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.note != null) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColorsV2.tertiary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(
                          color: AppColorsV2.tertiary, width: 2),
                    ),
                  ),
                  child: Text(
                    entry.note!,
                    style: AppTypeV2.body(
                      size: 11.5,
                      height: 1.5,
                      color: AppColorsV2.onSurfaceVariant,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              for (final group in entry.groups) _Group(group: group),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Group of bullets ────────────────────────────────────────────────────────

class _Group extends StatelessWidget {
  final ChangeGroup group;
  const _Group({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, size: 13, color: AppColorsV2.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title.toUpperCase(),
                  style: AppTypeV2.overline(size: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 7, left: 3, right: 12),
                    decoration: BoxDecoration(
                      color: AppColorsV2.onSurfaceVariant
                          .withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypeV2.body(
                        size: 12,
                        height: 1.55,
                        color: AppColorsV2.onSurfaceVariant,
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

// ── Small parts ─────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        text,
        style: AppTypeV2.caption(size: 8.5, color: color)
            .copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// The vertical line and the node dot next to each release.
class _RailPainter extends CustomPainter {
  final Color color;
  final Color nodeColor;
  final bool filled;
  final bool drawTop;
  final bool drawBottom;
  final double nodeSize;
  final double nodeCenterY;

  const _RailPainter({
    required this.color,
    required this.nodeColor,
    required this.filled,
    required this.drawTop,
    required this.drawBottom,
    required this.nodeSize,
    required this.nodeCenterY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final r = nodeSize / 2;

    final line = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    if (drawTop) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, nodeCenterY - r - 3), line);
    }
    if (drawBottom) {
      canvas.drawLine(
          Offset(x, nodeCenterY + r + 3), Offset(x, size.height), line);
    }

    final center = Offset(x, nodeCenterY);
    if (filled) {
      canvas.drawCircle(
          center, r + 3.5, Paint()..color = nodeColor.withValues(alpha: 0.16));
      canvas.drawCircle(center, r / 1.55, Paint()..color = nodeColor);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = nodeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    } else {
      canvas.drawCircle(center, r / 2.2, Paint()..color = color);
      canvas.drawCircle(
        center,
        r * 0.8,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.filled != filled ||
      old.nodeColor != nodeColor ||
      old.drawTop != drawTop ||
      old.drawBottom != drawBottom;
}
