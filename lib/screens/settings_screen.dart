import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for permanent save
import 'package:url_launcher/url_launcher.dart'; 
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/changelog_screen.dart';
import 'package:quran_recitation/screens/downloads_screen.dart';
import 'package:quran_recitation/screens/login_screen.dart';
import 'package:quran_recitation/screens/quiz_screen.dart';
import 'package:quran_recitation/screens/quiz_stats_screen.dart';
// `hide TextDirection`: package:intl exports its own TextDirection class (with
// LTR/RTL constants), which shadows the one from dart:ui that every Flutter
// widget expects and turns `TextDirection.rtl` into a compile error further
// down this file. home_screen.dart hides it for exactly the same reason.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran_recitation/services/interleaved_audio_service.dart';
import 'package:quran_recitation/services/notification_service.dart';
import 'package:quran_recitation/services/quiz_storage.dart';
import 'package:quran_recitation/services/adhan_service.dart';
import 'package:quran_recitation/services/time_format.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';

/// Where bug reports go.
const String _kInstagramUrl = 'https://www.instagram.com/officialquran2u/';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;
const _kCard = AppColorsV2.surfaceLow;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TranslationMode _audioLang = TranslationMode.urdu;

  @override
  void initState() {
    super.initState();
    _loadAudioPref();
  }

  // Load the saved setting as soon as the screen opens
  Future<void> _loadAudioPref() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('audio_tarjumah_lang') ?? 'urdu';
    if (mounted) {
      setState(() {
        _audioLang = saved == 'english' ? TranslationMode.english : TranslationMode.urdu;
      });
    }
  }

  /// Bug reports go to Instagram DMs.
  ///
  /// `externalApplication` rather than the default launch mode: a plain
  /// instagram.com link opened in an in-app webview lands on a logged-out
  /// page asking the user to sign in, which is where most reports would die.
  /// Forcing an external launch hands the URL to the installed Instagram app
  /// when there is one, and to the browser when there is not.
  Future<void> _reportBug() async {
    final uri = Uri.parse(_kInstagramUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // Fall through to the message below.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open Instagram. Find us at @officialquran2u',
          style: AppTypeV2.manrope(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColorsV2.surfaceHigh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedImam       = ref.watch(selectedImamProvider);
    final selectedTranslation = ref.watch(selectedTranslationProvider);
    final tarjumahMode       = ref.watch(tarjumahModeProvider);
    final isTarjumahSupported = ref.watch(isTarjumahSupportedProvider);

    // PERF: bulkDownloadProvider and updateCheckProvider are deliberately NOT
    // watched here. bulkDownloadProvider emits on every download progress
    // tick, and watching it at this level rebuilt the entire settings tree —
    // roughly a thousand widget allocations and sixty-odd Google Fonts
    // lookups — several times a second for the whole length of a 114-surah
    // download. Both are now watched inside a Consumer wrapping only the few
    // widgets that actually read them, so a tick repaints a progress bar.

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        // No scroll listener: the nav dock is fixed. On the longest screen in
        // the app that is one provider read fewer per scroll notification.
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
            children: [
              Center(
                child: Text(
                  'Quran2U',
                  style: AppTypeV2.manrope(
                    color: _kGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Settings',
                style: AppTypeV2.manrope(
                  color: AppColorsV2.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalize your spiritual experience',
                style: AppTypeV2.manrope(
                  color: AppColorsV2.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              const _QuranAccountSection(),
              const SizedBox(height: 22),

              // PERF: `ListView(children: [...])` evaluates its whole list on
              // every build — every Container, Row and Text in the sections
              // below is allocated whether or not it is on screen. Builder
              // allocates ONE widget and defers the subtree to element
              // inflation, which for a SliverList means "when scrolled into
              // view". The two biggest sections on this screen are ~80 and
              // ~200 lines of inline tree; they now cost nothing until seen.
              if (selectedImam != null)
                Builder(
                  builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorsV2.surfaceLow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _kGreen.withValues(alpha: 0.18), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedImam.name.split(' ').last.characters.first.toUpperCase(),
                          style: AppTypeV2.manrope(
                            color: _kGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'CURRENT RECITER',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTypeV2.manrope(
                                  color: _kGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedImam.name,
                              style: AppTypeV2.manrope(
                                color: AppColorsV2.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedImam.country,
                              style: AppTypeV2.manrope(
                                color: AppColorsV2.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),

              const SizedBox(height: 22),

              const _SectionHeader(icon: Icons.equalizer_rounded, text: 'Audio & Playback'),
              const SizedBox(height: 10),

              // Extracted so that dragging the slider calls setState on a
              // 50-line widget instead of on the whole settings screen. It
              // used to own `_speed` on the screen's State, which meant every
              // frame of a drag re-allocated the entire settings tree.
              const _PlaybackSpeedCard(),

              const SizedBox(height: 12),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColorsV2.surfaceLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: tarjumahMode 
                        ? _kGold.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isTarjumahSupported
                                  ? _kGold.withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.record_voice_over_rounded,
                                color: isTarjumahSupported ? _kGold : Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Audio Tarjumah',
                                  style: AppTypeV2.manrope(
                                    color: isTarjumahSupported ? AppColorsV2.onSurface : Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isTarjumahSupported
                                      ? 'Voice Translation after Ayah'
                                      : 'Not available for Sheikh Bandar',
                                  style: AppTypeV2.manrope(
                                    color: isTarjumahSupported
                                        ? AppColorsV2.onSurfaceVariant
                                        : Colors.redAccent.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isTarjumahSupported ? tarjumahMode : false,
                            onChanged: isTarjumahSupported
                                ? (val) {
                                    ref.read(tarjumahModeProvider.notifier).state = val;
                                    ref.read(audioPlayerServiceProvider).player.stop();
                                    ref.read(interleavedAudioServiceProvider).player.stop();
                                  }
                                : null,
                            activeThumbColor: _kGreen,
                            activeTrackColor: _kGreen.withValues(alpha: 0.25),
                            inactiveThumbColor: Colors.white38,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                          ),
                        ],
                      ),
                    ),

                    // The Expanding Language Section (Auto-opens when switch is ON)
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 14),
                            Text('Audio Language',
                                style: AppTypeV2.manrope(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      setState(() => _audioLang = TranslationMode.urdu);
                                      // Save permanently
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('audio_tarjumah_lang', 'urdu');
                                      
                                      ref.read(interleavedAudioServiceProvider).activeMode = TranslationMode.urdu;
                                      ref.read(interleavedAudioServiceProvider).player.stop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _audioLang == TranslationMode.urdu
                                            ? AppColorsV2.surfaceHigh
                                            : AppColorsV2.surface,
                                        borderRadius: const BorderRadius.horizontal(
                                            left: Radius.circular(12)),
                                        border: Border.all(
                                            color: _audioLang == TranslationMode.urdu
                                                ? _kGold.withValues(alpha: 0.5)
                                                : Colors.white10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_audioLang == TranslationMode.urdu)
                                            const Icon(Icons.check, color: _kGold, size: 16),
                                          if (_audioLang == TranslationMode.urdu)
                                            const SizedBox(width: 6),
                                          Text('Urdu',
                                              style: AppTypeV2.manrope(
                                                  color: _audioLang == TranslationMode.urdu
                                                      ? _kGold
                                                      : Colors.white54,
                                                  fontWeight: _audioLang == TranslationMode.urdu
                                                      ? FontWeight.bold
                                                      : FontWeight.normal)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      setState(() => _audioLang = TranslationMode.english);
                                      // Save permanently
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('audio_tarjumah_lang', 'english');

                                      ref.read(interleavedAudioServiceProvider).activeMode = TranslationMode.english;
                                      ref.read(interleavedAudioServiceProvider).player.stop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _audioLang == TranslationMode.english
                                            ? AppColorsV2.surfaceHigh
                                            : AppColorsV2.surface,
                                        borderRadius: const BorderRadius.horizontal(
                                            right: Radius.circular(12)),
                                        border: Border.all(
                                            color: _audioLang == TranslationMode.english
                                                ? _kGold.withValues(alpha: 0.5)
                                                : Colors.white10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_audioLang == TranslationMode.english)
                                            const Icon(Icons.check, color: _kGold, size: 16),
                                          if (_audioLang == TranslationMode.english)
                                            const SizedBox(width: 6),
                                          Text('English',
                                              style: AppTypeV2.manrope(
                                                  color: _audioLang == TranslationMode.english
                                                      ? _kGold
                                                      : Colors.white54,
                                                  fontWeight: _audioLang == TranslationMode.english
                                                      ? FontWeight.bold
                                                      : FontWeight.normal)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: tarjumahMode
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const _SectionHeader(icon: Icons.translate_rounded, text: 'Translations'),
              const SizedBox(height: 10),
              _TileButton(
                icon: Icons.translate_rounded,
                iconColor: _kGreen,
                title: 'Translation Language',
                subtitle: selectedTranslation.name,
                onTap: () => _showTranslationSheet(context, ref),
                background: AppColorsV2.surfaceLow,
              ),

              const SizedBox(height: 22),

              const _SectionHeader(icon: Icons.library_books_rounded, text: 'Library'),
              const SizedBox(height: 10),

              // Everything that reads download state lives inside this one
              // Consumer. A progress tick now rebuilds these two tiles and a
              // progress bar, not the screen.
              Consumer(
                builder: (context, ref, _) {
                  final bulkState = ref.watch(bulkDownloadProvider);
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TileButton(
                              icon: Icons.download_for_offline_rounded,
                              iconColor: _kGold,
                              title: 'Manage Downloads',
                              subtitle: 'Offline Surahs',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
                              background: AppColorsV2.surfaceLow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TileButton(
                              icon: Icons.cloud_download_rounded,
                              iconColor: _kGreen,
                              title: 'Offline Mode',
                              subtitle: 'Download Entire Quran',
                              onTap: () => _QuranDownloadTile(bulkState: bulkState).show(context, ref),
                              background: _kGreen.withValues(alpha: 0.10),
                              borderColor: _kGreen.withValues(alpha: 0.22),
                            ),
                          ),
                        ],
                      ),
                      if (bulkState.isDownloading) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kGreen.withValues(alpha: 0.22)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _kGreen),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Surah ${bulkState.currentSurah} of 114  ·  '
                                      '${(bulkState.overallProgress * 100).toStringAsFixed(0)}%',
                                      style: AppTypeV2.manrope(
                                          color: _kGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        ref.read(bulkDownloadProvider.notifier).cancel(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(56, 28),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text('Cancel',
                                        style: AppTypeV2.manrope(fontSize: 12)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(bulkState.status,
                                  style: AppTypeV2.manrope(
                                      color: AppColorsV2.onSurfaceVariant, fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: bulkState.overallProgress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  valueColor: const AlwaysStoppedAnimation(_kGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),
              _TileButton(
                icon: Icons.palette_rounded,
                iconColor: _kGold,
                title: 'Tajweed Guide',
                subtitle: 'Color-coded pronunciation rules',
                onTap: () => _showTajweedGuide(context),
                background: AppColorsV2.surfaceLow,
              ),

              const SizedBox(height: 22),

              const _SectionHeader(
                  icon: Icons.psychology_alt_rounded, text: 'Daily Quiz'),
              const SizedBox(height: 10),
              const _QuizSection(),

              const SizedBox(height: 22),

              const _SectionHeader(
                  icon: Icons.volume_up_rounded, text: 'Adhan'),
              const SizedBox(height: 10),
              const _AdhanSection(),

              const SizedBox(height: 22),

              const _SectionHeader(
                  icon: Icons.notifications_active_rounded,
                  text: 'Daily Reminder'),
              const SizedBox(height: 10),
              const _NotificationSection(),

              const SizedBox(height: 22),

              const _SectionHeader(icon: Icons.bug_report_rounded, text: 'Support'),
              const SizedBox(height: 10),
              _TileButton(
                icon: Icons.bug_report_rounded,
                iconColor: AppColorsV2.danger,
                title: 'Report a Bug',
                subtitle: 'Message us on Instagram — @officialquran2u',
                onTap: _reportBug,
                background: AppColorsV2.surfaceLow,
              ),

              const SizedBox(height: 22),
              const _SectionHeader(icon: Icons.info_outline_rounded, text: 'About'),
              const SizedBox(height: 10),
              _TileButton(
                icon: Icons.history_rounded,
                iconColor: _kGold,
                title: "What's new",
                subtitle: 'Every change, v1.0.0 to today',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const ChangelogScreen()),
                ),
                background: AppColorsV2.surfaceLow,
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(24),
                tint: AppColorsV2.surfaceLow,
                child: Column(
                  children: [
                    const _InfoRow(icon: Icons.info_outline_rounded, label: 'App', value: 'Quran2U'),
                    const Divider(color: Colors.white10, height: 16),
                    // Scoped for the same reason as the download tiles: the
                    // update check resolving must not rebuild the screen.
                    Consumer(
                      builder: (context, ref, _) {
                        final update = ref.watch(updateCheckProvider).valueOrNull;
                        final hasUpdate = update?.isUpdateAvailable == true;
                        return _InfoRow(
                          icon: Icons.tag_rounded,
                          label: 'Version',
                          value: hasUpdate
                              ? 'New: ${update!.latestVersion}'
                              : (update?.currentVersion ?? '—'),
                          actionText: hasUpdate ? 'Update' : null,
                          onTap: hasUpdate
                              ? () async {
                                  final url = Uri.parse(update!.releaseUrl);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url,
                                        mode: LaunchMode.externalApplication);
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Made with ❤️ by d0tahmed',
                      textAlign: TextAlign.center,
                      style: AppTypeV2.manrope(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A gift for my mom and my late grandmother,\nmay ALLAH reward both',
                      textAlign: TextAlign.center,
                      style: AppTypeV2.manrope(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
    );
  }

  // Sheets no longer hide the dock on the way in and restore it on the way
  // out. A modal route covers the dock anyway, and the restore was guarded by
  // `context.mounted` — so a sheet dismissed as its screen was disposed left
  // the dock hidden with nothing left running to bring it back.
  void _showTajweedGuide(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsV2.surfaceLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _TajweedGuideSheet(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionHeader({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: _kGreen, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      );
}

class _TinyLabel extends StatelessWidget {
  final String text;
  const _TinyLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypeV2.manrope(
          color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.55),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      );
}

/// Adhan controls.
///
/// Per prayer rather than one global switch, because that is how people
/// actually live with it — Fajr loud, Dhuhr silent while at work. Tapping a
/// row cycles Adhan → Silent → Off, which is faster than a dropdown for three
/// states and needs no modal.
class _AdhanSection extends StatefulWidget {
  const _AdhanSection();

  @override
  State<_AdhanSection> createState() => _AdhanSectionState();
}

class _AdhanSectionState extends State<_AdhanSection> {
  bool _loading = true;
  bool _enabled = false;
  Map<String, AdhanMode> _modes = <String, AdhanMode>{};
  MapEntry<String, DateTime>? _next;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await AdhanService.isEnabled();
    final modes = await AdhanService.allModes();
    final next = await AdhanService.nextAudible();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _enabled = enabled;
      _modes = modes;
      _next = next;
    });
  }

  Future<void> _toggleMaster(bool on) async {
    setState(() => _enabled = on);
    if (on && _modes.values.every((m) => m == AdhanMode.off)) {
      // Turning it on with every prayer off would do nothing at all, so the
      // first enable opts into the obvious thing rather than making the user
      // tap five more times to reach it.
      await AdhanService.enableAll();
    } else {
      await AdhanService.setEnabled(on);
    }
    await _load();
  }

  Future<void> _cycle(String prayer) async {
    const order = <AdhanMode>[AdhanMode.full, AdhanMode.notify, AdhanMode.off];
    final current = _modes[prayer] ?? AdhanMode.off;
    final next = order[(order.indexOf(current) + 1) % order.length];
    setState(() => _modes = <String, AdhanMode>{..._modes, prayer: next});
    await AdhanService.setMode(prayer, next);
    await _load();
  }

  Color _modeColor(AdhanMode mode) {
    switch (mode) {
      case AdhanMode.full:
        return _kGreen;
      case AdhanMode.notify:
        return _kGold;
      case AdhanMode.off:
        return AppColorsV2.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      // This card's height animates, so it opts out of the glass gradient
      // cache — see FrostedCard.animatedSize. Without it the unfold stuttered
      // and took the rest of the screen's cached surfaces down with it.
      animatedSize: true,
      child: Column(
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.campaign_rounded, color: _kGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Play the adhan',
                        style: AppTypeV2.outfit(
                            color: AppColorsV2.onSurface,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700)),
                    Text(
                      _loading
                          ? 'Checking…'
                          : !_enabled
                              ? 'Off'
                              : _next == null
                                  ? 'No prayer selected'
                                  : 'Next: ${_next!.key} at '
                                      '${TimeFormat.clock(_next!.value)}',
                      style: AppTypeV2.outfit(
                          color: AppColorsV2.onSurfaceVariant, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              _Toggle(
                value: _enabled,
                onChanged: _loading ? null : _toggleMaster,
              ),
            ],
          ),

          // The per-prayer list drops in and folds away rather than appearing
          // whole. An `if` alone made the card jump to its new height in a
          // single frame, which reads as a glitch — the eye has nothing to
          // follow, so the five rows seem to have been there all along and
          // the toggle seems not to have done anything.
          //
          // AnimatedSize animates the CARD, and the rows inside slide up from
          // under the divider via the ClipRect, so the motion looks like a
          // panel unfolding instead of a box being stretched.
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _enabled ? 1 : 0,
                // RepaintBoundary so the rows are rasterised once and the
                // unfold only moves the clip over them.
                //
                // It works here precisely because the list's own size never
                // changes — it is always laid out at full height and the Align
                // above only reveals more of it — so the cached layer stays
                // valid for the whole animation. Without the boundary every
                // frame re-paints five rows, their dividers and their pills,
                // none of which have changed.
                child: RepaintBoundary(child: _prayerList(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The five per-prayer rows plus the footnote. Always built, so
  /// AnimatedSize has something to measure on the way closed as well as open.
  Widget _prayerList(BuildContext context) {
    return Column(
      children: [
            const Divider(color: Colors.white10, height: 20),
            for (final prayer in AdhanService.prayers)
              InkWell(
                onTap: () => _cycle(prayer),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AdhanService.prayerLabels[prayer] ?? prayer,
                          style: AppTypeV2.outfit(
                              color: AppColorsV2.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _modeColor(_modes[prayer] ?? AdhanMode.off)
                                .withValues(alpha: 0.45),
                          ),
                          color: _modeColor(_modes[prayer] ?? AdhanMode.off)
                              .withValues(alpha: 0.10),
                        ),
                        child: Text(
                          (_modes[prayer] ?? AdhanMode.off).label,
                          style: AppTypeV2.outfit(
                            color: _modeColor(_modes[prayer] ?? AdhanMode.off),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(color: Colors.white10, height: 20),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColorsV2.onSurfaceVariant),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Plays at alarm volume, so it is heard on silent. If the '
                    'adhan stops firing, your phone is closing the app in the '
                    'background — allow it to run unrestricted, and turn off '
                    'battery optimisation for Quran2U.',
                    style: AppTypeV2.outfit(
                        color: AppColorsV2.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.45),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}

/// The app's switch.
///
/// Material's `Switch` fills its whole track with the active colour on this
/// palette, so an enabled toggle reads as a solid green pill with no visible
/// thumb — it stops looking like a control. This keeps the thumb bright and
/// the track translucent, so "on" is obvious and the shape still says switch.
/// It also sidesteps the `activeColor`/`activeThumbColor` deprecation churn.
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _Toggle({required this.value, this.onChanged});

  static const Duration _dur = Duration(milliseconds: 170);

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: _dur,
          curve: Curves.easeOutCubic,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value
                ? _kGreen.withValues(alpha: 0.22)
                : AppColorsV2.surfaceHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value
                  ? _kGreen.withValues(alpha: 0.7)
                  : AppColorsV2.outlineVariant,
              width: 1.2,
            ),
          ),
          child: AnimatedAlign(
            duration: _dur,
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: _dur,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value
                    ? _kGreen
                    : AppColorsV2.onSurfaceVariant.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: _kGreen.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: -1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Daily quiz status, with the two entry points.
///
/// This exists in Settings as well as on the home screen because the streak is
/// the thing people come looking for, and they look for it where the numbers
/// live.
class _QuizSection extends StatefulWidget {
  const _QuizSection();

  @override
  State<_QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends State<_QuizSection> {
  QuizProgress? _p;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await QuizStorage.load();
    if (mounted) setState(() => _p = p);
  }

  Future<void> _go(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final done = p?.playedToday ?? false;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      tint: AppColorsV2.surfaceLow,
      child: Column(
        children: [
          Row(
            children: [
              const _IconBox(
                  icon: Icons.local_fire_department_rounded, color: _kGold),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p == null
                          ? 'Loading…'
                          : p.currentStreak == 0
                              ? 'No streak yet'
                              : '${p.currentStreak} day streak',
                      style: AppTypeV2.title(size: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p == null
                          ? ' '
                          : done
                              ? 'Today is done  ·  ${p.totalStars} stars all time'
                              : 'Today is waiting  ·  best ${p.bestStreak} days',
                      style: AppTypeV2.caption(
                          size: 11, color: AppColorsV2.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniAction(
                  icon: done
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  label: done ? 'Play again' : 'Start today',
                  filled: !done,
                  onTap: () => _go(const QuizScreen()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniAction(
                  icon: Icons.insights_rounded,
                  label: 'Progress',
                  onTap: () => _go(const QuizStatsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small square-shouldered button used inside the settings panels.
class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColorsV2.onPrimary : AppColorsV2.onSurface;
    return GlassPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? _kGreen : AppColorsV2.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? Colors.transparent : AppColorsV2.hairline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeV2.caption(size: 11.5, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily reminder status and controls.
///
/// A scheduled notification that silently fails is the worst kind of bug: the
/// user has no way to tell "not scheduled" from "scheduled and the OS ate it".
/// This shows what is actually armed, lets them fire one immediately to prove
/// the path works, and — only when the OS has withheld exact alarms — offers
/// the one settings toggle that fixes the drift.
class _NotificationSection extends StatefulWidget {
  const _NotificationSection();

  @override
  State<_NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<_NotificationSection> {
  bool _loading = true;
  bool _enabled = false;
  int _armed = 0;
  DateTime? _next;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    final pending = await NotificationService.pendingReminders();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _enabled = enabled;
      _armed = pending.length;
      _next = _armed > 0 ? _nextOccurrence() : null;
    });
  }

  /// The plugin does not expose a pending request's fire time, so derive it the
  /// same way the service does: the next reminder hour still in the future.
  static DateTime _nextOccurrence() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day,
        NotificationService.reminderHour, NotificationService.reminderMinute);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  String get _status {
    if (_loading) return 'Checking…';
    if (!_enabled) return 'Blocked in Android settings';
    if (_armed == 0) return 'Not scheduled';
    if (NotificationService.lastScheduleWasInexact) {
      return '$_armed days armed · time may drift';
    }
    return '$_armed days armed';
  }

  @override
  Widget build(BuildContext context) {
    final hour = NotificationService.reminderHour.toString().padLeft(2, '0');
    final minute = NotificationService.reminderMinute.toString().padLeft(2, '0');

    return _GlassCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.wb_twilight_rounded,
            label: 'Every day at $hour:$minute',
            value: _status,
          ),
          const Divider(color: Colors.white10, height: 16),
          // Deliberately not an _InfoRow. Label + chip + "next Fri 29 Aug" is
          // more than one line can hold on a 360dp phone, and squeezing it
          // ellipsised the label away. Stacking the two strings gives both
          // room and reads better besides.
          InkWell(
            onTap: () async {
              await NotificationService.showInstantNotification();
              await NotificationService.scheduleDailyReminders();
              await _refresh();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      color: Colors.white24, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send a test now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypeV2.outfit(
                              color: Colors.white38, fontSize: 13),
                        ),
                        if (_next != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Next reminder '
                            '${DateFormat('EEE d MMM').format(_next!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypeV2.outfit(
                              color: _kGold.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                    ),
                    child: Text('Test',
                        style: AppTypeV2.manrope(
                            color: _kGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
          // Only shown when it is actually the problem — an unconditional
          // "grant exact alarms" row is noise for the users who already have it.
          if (!_loading && NotificationService.lastScheduleWasInexact) ...[
            const Divider(color: Colors.white10, height: 16),
            _InfoRow(
              icon: Icons.alarm_rounded,
              label: 'Allow exact alarms',
              value: 'for on-time delivery',
              actionText: 'Fix',
              onTap: () async {
                await NotificationService.requestExactAlarmPermission();
                await NotificationService.scheduleDailyReminders();
                await _refresh();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Playback-speed card.
///
/// Owns its own `_speed` so a drag repaints this card and nothing else.
/// `onChanged` fires once per pointer move — roughly sixty times a second —
/// which is exactly the wrong thing to hang a whole-screen rebuild off.
/// The player is only told the new rate on `onChangeEnd`.
class _PlaybackSpeedCard extends ConsumerStatefulWidget {
  const _PlaybackSpeedCard();

  @override
  ConsumerState<_PlaybackSpeedCard> createState() => _PlaybackSpeedCardState();
}

class _PlaybackSpeedCardState extends ConsumerState<_PlaybackSpeedCard> {
  double _speed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColorsV2.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Playback Speed',
                style: AppTypeV2.manrope(
                  color: AppColorsV2.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_speed.toStringAsFixed(2)}x',
                  style: AppTypeV2.manrope(
                    color: _kGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _speed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (v) => setState(() => _speed = v),
            onChangeEnd: (v) =>
                ref.read(audioPlayerServiceProvider).setPlaybackRate(v),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TinyLabel('0.5X'),
              _TinyLabel('1.0X'),
              _TinyLabel('1.5X'),
              _TinyLabel('2.0X'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color background;
  final Color? borderColor;

  const _TileButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => FrostedCard(
        radius: 28,
        padding: const EdgeInsets.all(16),
        tint: background,
        accent: iconColor,
        edgeColor: borderColor == null
            ? iconColor
            : borderColor!.withValues(alpha: 1.0),
        edgeIntensity: borderColor == null ? 0.32 : 0.46,
        onTap: onTap,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      iconColor.withValues(alpha: 0.26),
                      iconColor.withValues(alpha: 0.08),
                    ],
                  ),
                  border:
                      Border.all(color: iconColor.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypeV2.manrope(
                  color: AppColorsV2.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypeV2.manrope(
                  color: AppColorsV2.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      );
}

extension on _QuranDownloadTile {
  void show(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsV2.surfaceLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DownloadWizardSheet(ref: ref),
    );
  }
}

class _TajweedGuideSheet extends StatelessWidget {
  const _TajweedGuideSheet();

  static const _rules = <_TajweedRule>[
    _TajweedRule(name: 'Ghunnah', nameArabic: 'غُنَّة', color: Color(0xFFFF7E1E), description: 'Nasal sound held for 2 counts', example: 'مِنَ', exampleHighlight: 'نَ'),
    _TajweedRule(name: 'Ikhfa', nameArabic: 'إِخْفَاء', color: Color(0xFFD500B2), description: 'Hidden pronunciation of noon sakinah/tanween', example: 'مِنْ بَعْدِ', exampleHighlight: 'نْ'),
    _TajweedRule(name: 'Ikhfa Shafawi', nameArabic: 'إِخْفَاء شَفَوِي', color: Color(0xFFD500B2), description: 'Hidden meem sakinah before baa', example: 'تَرْمِيهِمْ بِحِجَارَةٍ', exampleHighlight: 'مْ بِ'),
    _TajweedRule(name: 'Idgham', nameArabic: 'إِدْغَام', color: Color(0xFF169200), description: 'Merging noon sakinah into the next letter', example: 'مِنْ وَلِيٍّ', exampleHighlight: 'نْ وَ'),
    _TajweedRule(name: 'Iqlab', nameArabic: 'إِقْلَاب', color: Color(0xFF26BFFD), description: 'Noon sakinah converts to meem before baa', example: 'مِنۢ بَعْدِ', exampleHighlight: 'نۢ'),
    _TajweedRule(name: 'Qalqalah', nameArabic: 'قَلْقَلَة', color: Color(0xFFDD0000), description: 'Echoing bounce on letters ق ط ب ج د', example: 'يَخْلُقْ', exampleHighlight: 'قْ'),
    _TajweedRule(name: 'Madd (Normal)', nameArabic: 'مَدّ طَبِيعِي', color: Color(0xFF537FFF), description: 'Natural elongation — 2 counts', example: 'قَالَ', exampleHighlight: 'ـَا'),
    _TajweedRule(name: 'Madd (Permissible)', nameArabic: 'مَدّ جَائِز', color: Color(0xFF4050FF), description: 'Elongation 2-4-6 counts at end of verse', example: 'الرَّحِيمِ', exampleHighlight: 'ِي'),
    _TajweedRule(name: 'Madd (Obligatory)', nameArabic: 'مَدّ لَازِم', color: Color(0xFF2144C1), description: 'Obligatory elongation — 6 counts', example: 'الضَّآلِّين', exampleHighlight: 'ٓا'),
    _TajweedRule(name: 'Madd (Necessary)', nameArabic: 'مَدّ وَاجِب', color: Color(0xFF000EBC), description: 'Required elongation — 4-5 counts', example: 'جَآءَ', exampleHighlight: 'ٓا'),
    _TajweedRule(name: 'Laam Shamsiyah', nameArabic: 'لَام شَمْسِيَّة', color: Color(0xFFAAAAAA), description: 'Silent laam that assimilates into sun letters', example: 'الشَّمْسِ', exampleHighlight: 'ل'),
    _TajweedRule(name: 'Hamzat ul-Wasl', nameArabic: 'هَمْزَة الْوَصْل', color: Color(0xFFAAAAAA), description: 'Connecting hamza — silent when continuing', example: 'ٱلْحَمْدُ', exampleHighlight: 'ٱ'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColorsV2.surfaceLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette_rounded, color: _kGold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tajweed Guide',
                      style: AppTypeV2.outfit(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Color-coded pronunciation rules',
                      style: AppTypeV2.outfit(color: Colors.white38, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView.separated(
                // Rows hold no state worth preserving off-screen; the default
                // wraps every one of them in an AutomaticKeepAlive element.
                addAutomaticKeepAlives: false,
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                itemCount: _rules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final rule = _rules[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: rule.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: rule.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: rule.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: rule.color.withValues(alpha: 0.4), blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rule.name,
                                  style: AppTypeV2.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(rule.nameArabic,
                                  style: TextStyle(
                                      color: rule.color,
                                      fontSize: 13,
                                      fontFamily: AppTypeV2.amiriFamily)),
                              const SizedBox(height: 2),
                              Text(rule.description,
                                  style: AppTypeV2.outfit(
                                      color: Colors.white38, fontSize: 11, height: 1.3)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 90),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rule.example,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontFamily: AppTypeV2.amiriFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _TajweedRule {
  final String name;
  final String nameArabic;
  final Color color;
  final String description;
  final String example;
  final String exampleHighlight;

  const _TajweedRule({
    required this.name,
    required this.nameArabic,
    required this.color,
    required this.description,
    required this.example,
    required this.exampleHighlight,
  });
}

class _QuranDownloadTile extends ConsumerWidget {
  final BulkDownloadState bulkState;
  const _QuranDownloadTile({required this.bulkState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bulkState.isDownloading) {
      return _GlassCard(
        accentColor: _kGreen.withValues(alpha: 0.3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const _IconBox(icon: Icons.download_rounded, color: _kGreen),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Downloading Quran…',
                  style: AppTypeV2.outfit(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                'Surah ${bulkState.currentSurah} of 114  ·  ${(bulkState.overallProgress * 100).toStringAsFixed(0)}%',
                style: AppTypeV2.outfit(color: _kGreen, fontSize: 11),
              ),
            ])),
            TextButton(
              onPressed: () => ref.read(bulkDownloadProvider.notifier).cancel(),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red, padding: EdgeInsets.zero,
                  minimumSize: const Size(56, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('Cancel', style: AppTypeV2.outfit(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(bulkState.status,
              style: AppTypeV2.outfit(color: Colors.white38, fontSize: 10),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: bulkState.overallProgress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_kGreen),
            ),
          ),
        ]),
      );
    }

    return _GlassCard(
      child: InkWell(
        onTap: () => _showDownloadWizard(context, ref),
        borderRadius: BorderRadius.circular(14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen.withValues(alpha: 0.25), _kGold.withValues(alpha: 0.15)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.downloading_rounded, color: _kGreen, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Download Entire Quran',
                style: AppTypeV2.outfit(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Save all 114 Surahs offline',
                style: AppTypeV2.outfit(color: Colors.white38, fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
        ]),
      ),
    );
  }

  void _showDownloadWizard(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColorsV2.surfaceLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DownloadWizardSheet(ref: ref),
    );
  }
}

class _DownloadWizardSheet extends StatefulWidget {
  final WidgetRef ref;
  const _DownloadWizardSheet({required this.ref});
  @override
  State<_DownloadWizardSheet> createState() => _DownloadWizardSheetState();
}

class _DownloadWizardSheetState extends State<_DownloadWizardSheet> {
  int? _selectedImamId;
  bool _withTarjumah = false;

  @override
  Widget build(BuildContext context) {
    final imams = widget.ref.read(imamsProvider);
    final canStart = _selectedImamId != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColorsV2.surfaceLow,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.downloading_rounded, color: _kGreen, size: 22),
                      const SizedBox(width: 10),
                      Text('Download Entire Quran',
                          style: AppTypeV2.outfit(
                              color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    Text('Downloads all 114 Surahs offline.',
                        style: AppTypeV2.outfit(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 22),

                    Text('STEP 1 — SELECT RECITER',
                        style: AppTypeV2.outfit(
                            color: Colors.white38, fontSize: 10,
                            fontWeight: FontWeight.w600, letterSpacing: 1.4)),
                    const SizedBox(height: 10),
                    ...imams.map((imam) => _ImamChoice(
                      imam: imam,
                      selected: _selectedImamId == imam.id,
                      onTap: () => setState(() => _selectedImamId = imam.id),
                    )),
                    const SizedBox(height: 20),

                    Text('STEP 2 — TRANSLATION',
                        style: AppTypeV2.outfit(
                            color: Colors.white38, fontSize: 10,
                            fontWeight: FontWeight.w600, letterSpacing: 1.4)),
                    const SizedBox(height: 10),
                    _GlassCard(
                      accentColor: _withTarjumah ? _kGold.withValues(alpha: 0.3) : null,
                      child: Row(children: [
                        const _IconBox(icon: Icons.translate_rounded, color: _kGold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Include Urdu Tarjumah',
                                  style: AppTypeV2.outfit(
                                      color: Colors.white, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                _withTarjumah
                                    ? 'Per-ayah (Shamshad Ali Khan) · ~4× storage'
                                    : 'Recitation only · ~570 MB per reciter',
                                style: AppTypeV2.outfit(
                                    color: _withTarjumah ? _kGold : Colors.white38,
                                    fontSize: 10, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _withTarjumah,
                          onChanged: (v) => setState(() => _withTarjumah = v),
                          activeThumbColor: _kGold,
                          activeTrackColor: _kGold.withValues(alpha: 0.25),
                          inactiveThumbColor: Colors.white38,
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.sd_storage_outlined, color: Colors.white24, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _withTarjumah
                                ? 'Est. ~2.5 GB (Arabic + Urdu per ayah)'
                                : 'Est. ~570 MB (full Surah MP3s)',
                            style: AppTypeV2.outfit(
                                color: Colors.white38, fontSize: 11, height: 1.4),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: AnimatedOpacity(
                        opacity: canStart ? 1.0 : 0.45,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          onPressed: canStart ? () => _start(ctx, imams) : null,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text('Start Download',
                              style: AppTypeV2.outfit(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _kGreen,
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _start(BuildContext ctx, List<Imam> imams) {
    final imam = imams.firstWhere((i) => i.id == _selectedImamId!);
    widget.ref.read(bulkDownloadProvider.notifier).start(
      imamId: imam.id,
      imamIdentifier: imam.identifier,
      withTarjumah: _withTarjumah,
    );
    Navigator.pop(ctx);
  }
}

class _ImamChoice extends StatelessWidget {
  final Imam imam;
  final bool selected;
  final VoidCallback onTap;
  const _ImamChoice({required this.imam, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _kGreen.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _kGreen.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kGreen : Colors.white24, width: selected ? 2 : 1.5),
                color: selected ? _kGreen : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(imam.name,
                  style: AppTypeV2.outfit(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              Text(imam.country,
                  style: AppTypeV2.outfit(color: Colors.white30, fontSize: 10)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;

  /// Set on a card that grows and shrinks — the adhan panel. See
  /// [FrostedCard.animatedSize] for why a resizing card must not cache.
  final bool animatedSize;

  const _GlassCard({
    required this.child,
    this.accentColor,
    this.animatedSize = false,
  });

  @override
  Widget build(BuildContext context) => FrostedCard(
        radius: 14,
        padding: const EdgeInsets.all(16),
        tint: _kCard,
        accent: accentColor,
        edgeColor: accentColor,
        edgeIntensity: accentColor == null ? 0.18 : 0.36,
        animatedSize: animatedSize,
        child: child,
      );
}


class _ChoiceRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.icon, required this.label, required this.subtitle,
    required this.selected, required this.accentColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(icon, color: selected ? accentColor : Colors.white24, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppTypeV2.outfit(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              Text(subtitle,
                  style: AppTypeV2.outfit(color: Colors.white38, fontSize: 11)),
            ])),
            if (selected) Icon(Icons.check_rounded, color: accentColor, size: 18),
          ]),
        ),
      );
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.26),
              color.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: color, size: 18),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  final String? actionText;
  const _InfoRow({required this.icon, required this.label, required this.value, this.onTap, this.actionText});

  @override
  Widget build(BuildContext context) {
    // `Expanded` on the label rather than a `Spacer` after it. A Spacer only
    // works while everything fits: the moment label + chip + value exceed the
    // row it claims negative space and the children draw on top of each other,
    // which is exactly what the reminder row was doing.
    Widget child = Row(children: [
        Icon(icon, color: Colors.white24, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypeV2.outfit(color: Colors.white38, fontSize: 13),
          ),
        ),
        if (actionText != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
            ),
            child: Text(actionText!, style: AppTypeV2.manrope(color: _kGold, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
        if (value.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeV2.outfit(
                  color: actionText != null ? _kGold : Colors.white70,
                  fontSize: 13,
                  fontWeight: actionText != null ? FontWeight.w800 : FontWeight.w500)),
        ],
      ]);

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child),
      );
    }
    return child;
  }
}
class _QuranAccountSection extends ConsumerWidget {
  const _QuranAccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider).valueOrNull ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColorsV2.surfaceLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: _kGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quran.com Cloud Sync',
                      style: AppTypeV2.manrope(
                        color: AppColorsV2.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoggedIn ? 'Signed in to Quran.com' : 'Signed out',
                      style: AppTypeV2.manrope(
                        color: isLoggedIn ? _kGreen : AppColorsV2.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoggedIn) ...[
            Text(
              'Your bookmarks (saved Surahs & Ayahs) are safely backed up to the cloud.',
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Syncing bookmarks...', style: AppTypeV2.manrope(fontWeight: FontWeight.w600)),
                          backgroundColor: _kCard,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      ref.read(bookmarkSyncProvider.notifier).syncToCloud().then((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sync Complete', style: AppTypeV2.manrope(fontWeight: FontWeight.w600, color: _kGreen)),
                            backgroundColor: _kCard,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen.withValues(alpha: 0.1),
                      foregroundColor: _kGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text('Sync Now', style: AppTypeV2.manrope(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(quranAuthServiceProvider).logout();
                      ref.invalidate(isLoggedInProvider);
                      ref.invalidate(userProfileProvider);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColorsV2.danger,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text('Sign Out', style: AppTypeV2.manrope(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Sign in to securely back up your saved Ayahs and Surahs to the cloud and access them across devices.',
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: const Color(0xFF00311F),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  'Sign in & Sync Data',
                  style: AppTypeV2.manrope(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _showTranslationSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColorsV2.surfaceLow,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: const _TranslationSearchSheet(),
    ),
  );
}

class _TranslationSearchSheet extends ConsumerStatefulWidget {
  const _TranslationSearchSheet();

  @override
  ConsumerState<_TranslationSearchSheet> createState() => _TranslationSearchSheetState();
}

class _TranslationSearchSheetState extends ConsumerState<_TranslationSearchSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final translationsAsync = ref.watch(availableTranslationsProvider);
    final selectedOption = ref.watch(selectedTranslationProvider);

    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select Translation',
          style: AppTypeV2.outfit(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search language or translator...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
              filled: true,
              fillColor: AppColorsV2.surfaceHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        const SizedBox(height: 16),
        _ChoiceRow(
          icon: Icons.block_rounded,
          label: 'Off',
          subtitle: 'Arabic only',
          selected: selectedOption.id == 0,
          accentColor: const Color(0xFF10B981),
          onTap: () {
            ref.read(selectedTranslationProvider.notifier).setTranslation(0, 'Off');
            Navigator.pop(context);
          },
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: translationsAsync.when(
            data: (list) {
              final filtered = list.where((t) {
                final name = (t['name'] ?? '').toString().toLowerCase();
                final lang = (t['language_name'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || lang.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                // Rows hold no state worth preserving off-screen; the default
                // wraps every one of them in an AutomaticKeepAlive element.
                addAutomaticKeepAlives: false,
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final t = filtered[i];
                  final lang = t['language_name'] ?? '';
                  final langTitle = lang.isNotEmpty
                      ? lang[0].toUpperCase() + lang.substring(1)
                      : 'Unknown';
                  final name = t['name'] ?? '';
                  final subtitleStr = '$langTitle — $name';

                  return _ChoiceRow(
                    icon: Icons.translate_rounded,
                    label: langTitle,
                    subtitle: name,
                    selected: selectedOption.id == t['id'],
                    accentColor: const Color(0xFF10B981),
                    onTap: () {
                      ref
                          .read(selectedTranslationProvider.notifier)
                          .setTranslation(t['id'], subtitleStr);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981))),
            error: (e, st) => Center(
                child: Text('Error loading translations',
                    style: TextStyle(color: Colors.red.shade300))),
          ),
        ),
      ],
    );
  }
}
