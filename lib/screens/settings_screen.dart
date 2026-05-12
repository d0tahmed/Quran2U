import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quran_recitation/screens/main_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for permanent save
import 'package:url_launcher/url_launcher.dart'; 
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/downloads_screen.dart';
import 'package:quran_recitation/screens/login_screen.dart';
import 'package:quran_recitation/services/interleaved_audio_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

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
  double _speed = 1.0;

  
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

  Future<void> _reportBug() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'd0tahmedgithub@gmail.com', 
      queryParameters: {
        'subject': 'Bug Report: Quran2U App',
        'body': 'Describe the bug here...\n\n',
      },
    );
    
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email app');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open email app. Email us at d0tahmedgithub@gmail.com',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedImam       = ref.watch(selectedImamProvider);
    final selectedTranslation = ref.watch(selectedTranslationProvider);
    final tarjumahMode       = ref.watch(tarjumahModeProvider);
    final isTarjumahSupported = ref.watch(isTarjumahSupportedProvider); 
    final bulkState          = ref.watch(bulkDownloadProvider);
    final updateAsync        = ref.watch(updateCheckProvider);

    return Scaffold(
      backgroundColor: _kBg,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
            children: [
              Center(
                child: Text(
                  'Quran2U',
                  style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(
                  color: AppColorsV2.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalize your spiritual experience',
                style: GoogleFonts.manrope(
                  color: AppColorsV2.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),

              const _QuranAccountSection(),
              const SizedBox(height: 22),

              if (selectedImam != null)
                Container(
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
                          style: GoogleFonts.manrope(
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
                                style: GoogleFonts.manrope(
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
                              style: GoogleFonts.manrope(
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
                              style: GoogleFonts.manrope(
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

              const SizedBox(height: 22),

              const _SectionHeader(icon: Icons.equalizer_rounded, text: 'Audio & Playback'),
              const SizedBox(height: 10),

              Container(
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
                          style: GoogleFonts.manrope(
                            color: AppColorsV2.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${_speed.toStringAsFixed(2)}x',
                            style: GoogleFonts.manrope(
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
                      onChangeEnd: (v) => ref.read(audioPlayerServiceProvider).setPlaybackRate(v),
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
              ),

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
                                  style: GoogleFonts.manrope(
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
                                  style: GoogleFonts.manrope(
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
                                style: GoogleFonts.manrope(
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
                                              style: GoogleFonts.manrope(
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
                                              style: GoogleFonts.manrope(
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
                              style: GoogleFonts.manrope(
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
                                style: GoogleFonts.manrope(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(bulkState.status,
                          style: GoogleFonts.manrope(
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

              const _SectionHeader(icon: Icons.bug_report_rounded, text: 'Support'),
              const SizedBox(height: 10),
              _TileButton(
                icon: Icons.bug_report_rounded,
                iconColor: AppColorsV2.danger,
                title: 'Report a Bug',
                subtitle: 'Help us improve the app',
                onTap: _reportBug,
                background: AppColorsV2.surfaceLow,
              ),

              const SizedBox(height: 22),
              const _SectionHeader(icon: Icons.info_outline_rounded, text: 'flutte'),
              const SizedBox(height: 10),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(24),
                tint: AppColorsV2.surfaceLow,
                child: Column(
                  children: [
                    const _InfoRow(icon: Icons.info_outline_rounded, label: 'App', value: 'Quran2U'),
                    const Divider(color: Colors.white10, height: 16),
                    _InfoRow(
                      icon: Icons.tag_rounded, 
                      label: 'Version', 
                      value: updateAsync.valueOrNull?.isUpdateAvailable == true ? 'New: ${updateAsync.valueOrNull!.latestVersion}' : (updateAsync.valueOrNull?.currentVersion ?? '2.0.0'),
                      actionText: updateAsync.valueOrNull?.isUpdateAvailable == true ? 'Update' : null,
                      onTap: updateAsync.valueOrNull?.isUpdateAvailable == true ? () async {
                        final url = Uri.parse(updateAsync.valueOrNull!.releaseUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      } : null,
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    const _InfoRow(icon: Icons.library_music_outlined, label: 'Audio', value: 'mp3quran.net'),
                    const Divider(color: Colors.white10, height: 16),
                    const _InfoRow(icon: Icons.api_outlined, label: 'Data', value: 'api.quran.com'),
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
                      style: GoogleFonts.manrope(
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
                      style: GoogleFonts.manrope(
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
      ),
    );
  }

  void _showTajweedGuide(BuildContext context) async {
    ref.read(navBarVisibleProvider.notifier).state = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1421),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _TajweedGuideSheet(),
    );
    if (context.mounted) {
      ref.read(navBarVisibleProvider.notifier).state = true;
    }
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
              style: GoogleFonts.manrope(
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
        style: GoogleFonts.manrope(
          color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.55),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.6,
        ),
      );
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
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: AppColorsV2.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  color: AppColorsV2.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

extension on _QuranDownloadTile {
  void show(BuildContext context, WidgetRef ref) async {
    ref.read(navBarVisibleProvider.notifier).state = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1421),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DownloadWizardSheet(ref: ref),
    );
    if (context.mounted) {
      ref.read(navBarVisibleProvider.notifier).state = true;
    }
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
          color: Color(0xFF0E1421),
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
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Color-coded pronunciation rules',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: ListView.separated(
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
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(rule.nameArabic,
                                  style: TextStyle(
                                      color: rule.color,
                                      fontSize: 13,
                                      fontFamily: GoogleFonts.amiri().fontFamily)),
                              const SizedBox(height: 2),
                              Text(rule.description,
                                  style: GoogleFonts.outfit(
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
                              fontFamily: GoogleFonts.amiri().fontFamily,
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
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                'Surah ${bulkState.currentSurah} of 114  ·  ${(bulkState.overallProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(color: _kGreen, fontSize: 11),
              ),
            ])),
            TextButton(
              onPressed: () => ref.read(bulkDownloadProvider.notifier).cancel(),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red, padding: EdgeInsets.zero,
                  minimumSize: const Size(56, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text('Cancel', style: GoogleFonts.outfit(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(bulkState.status,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
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
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Save all 114 Surahs offline',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
        ]),
      ),
    );
  }

  void _showDownloadWizard(BuildContext context, WidgetRef ref) async {
    ref.read(navBarVisibleProvider.notifier).state = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1421),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DownloadWizardSheet(ref: ref),
    );
    if (context.mounted) {
      ref.read(navBarVisibleProvider.notifier).state = true;
    }
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
          color: Color(0xFF0E1421),
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
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    Text('Downloads all 114 Surahs offline.',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 22),

                    Text('STEP 1 — SELECT RECITER',
                        style: GoogleFonts.outfit(
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
                        style: GoogleFonts.outfit(
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
                                  style: GoogleFonts.outfit(
                                      color: Colors.white, fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                _withTarjumah
                                    ? 'Per-ayah (Shamshad Ali Khan) · ~4× storage'
                                    : 'Recitation only · ~570 MB per reciter',
                                style: GoogleFonts.outfit(
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
                            style: GoogleFonts.outfit(
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
                              style: GoogleFonts.outfit(
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
                  style: GoogleFonts.outfit(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              Text(imam.country,
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
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
  const _GlassCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor ?? Colors.white.withValues(alpha: 0.07)),
        ),
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
                  style: GoogleFonts.outfit(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              Text(subtitle,
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
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
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
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
    Widget child = Row(children: [
        Icon(icon, color: Colors.white24, size: 16),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        if (actionText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGold.withValues(alpha: 0.3)),
            ),
            child: Text(actionText!, style: GoogleFonts.manrope(color: _kGold, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
        ],
        Text(value,
            style: GoogleFonts.outfit(
                color: actionText != null ? _kGold : Colors.white70, 
                fontSize: 13, 
                fontWeight: actionText != null ? FontWeight.w800 : FontWeight.w500)),
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
                      style: GoogleFonts.manrope(
                        color: AppColorsV2.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoggedIn ? 'Signed in to Quran.com' : 'Signed out',
                      style: GoogleFonts.manrope(
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
              style: GoogleFonts.manrope(
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
                          content: Text('Syncing bookmarks...', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                          backgroundColor: _kCard,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      ref.read(bookmarkSyncProvider.notifier).syncToCloud().then((_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sync Complete', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: _kGreen)),
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
                    label: Text('Sync Now', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
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
                    label: Text('Sign Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Sign in to securely back up your saved Ayahs and Surahs to the cloud and access them across devices.',
              style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 14),
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
  ref.read(navBarVisibleProvider.notifier).state = false;
  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0E1421),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: const _TranslationSearchSheet(),
    ),
  );
  if (context.mounted) {
    ref.read(navBarVisibleProvider.notifier).state = true;
  }
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
          style: GoogleFonts.outfit(
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
