import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/downloads_screen.dart';

const _kGreen = Color(0xFF10B981);
const _kGold  = Color(0xFFEAB308);
const _kBg    = Color(0xFF05080F);
const _kCard  = Color(0xFF121B2B);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _speed = 1.0;
  bool _translationExpanded = false;
  bool _tarjumahExpanded = false;

  // SENIOR FIX: The function that safely opens the native email app
  Future<void> _reportBug() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'd0tahmedgithub@gmail.com', // LOCKED IN: Your official dev email!
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
            content: Text('Could not open email app. Email us at d0tahmedgithub@gmail.com', style: GoogleFonts.outfit()),
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
    final bulkState          = ref.watch(bulkDownloadProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Text('Settings',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Quran2U',
                style: GoogleFonts.outfit(
                    color: Colors.white24, fontSize: 11, letterSpacing: 2.0)),
            const SizedBox(height: 28),

            // ── Support / Bug Report ─────────────────────────────────────────
            _SectionLabel('Support'),
            const SizedBox(height: 10),
            _GlassCard(
              child: InkWell(
                onTap: _reportBug,
                borderRadius: BorderRadius.circular(14),
                child: Row(children: [
                  _IconBox(icon: Icons.bug_report_rounded, color: Colors.redAccent),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Report a Bug',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Help us improve the app',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ── Playback Speed ───────────────────────────────────────────────
            _SectionLabel('Playback Speed'),
            const SizedBox(height: 10),
            _GlassCard(
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0.5×', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
                    Text('${_speed.toStringAsFixed(1)}×',
                        style: GoogleFonts.outfit(
                            color: _kGreen, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('2.0×', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _kGreen,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                    thumbColor: Colors.white,
                    overlayColor: _kGreen.withValues(alpha: 0.15),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: _speed, min: 0.5, max: 2.0, divisions: 15,
                    onChanged: (v) => setState(() => _speed = v),
                    onChangeEnd: (v) => ref.read(audioPlayerServiceProvider).setPlaybackRate(v),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Written Translation ──────────────────────────────────────────
            _SectionLabel('Written Translation'),
            const SizedBox(height: 10),
            _ExpandableCard(
              expanded: _translationExpanded,
              onToggle: () => setState(() => _translationExpanded = !_translationExpanded),
              accentColor: _kGreen,
              iconData: Icons.translate_rounded,
              title: 'Translation Language',
              subtitle: selectedTranslation == 0
                  ? 'Off'
                  : selectedTranslation == 20
                      ? 'English — Sahih International'
                      : 'Urdu — Fateh Muhammad Jalandhari',
              children: [
                _ChoiceRow(
                  icon: Icons.block_rounded, label: 'Off', subtitle: 'Arabic only',
                  selected: selectedTranslation == 0,
                  accentColor: _kGreen,
                  onTap: () { ref.read(selectedTranslationProvider.notifier).state = 0;
                    setState(() => _translationExpanded = false); },
                ),
                _ChoiceRow(
                  icon: Icons.language_rounded, label: 'English',
                  subtitle: 'Sahih International',
                  selected: selectedTranslation == 20,
                  accentColor: _kGreen,
                  onTap: () { ref.read(selectedTranslationProvider.notifier).state = 20;
                    setState(() => _translationExpanded = false); },
                ),
                _ChoiceRow(
                  icon: Icons.text_fields_rounded, label: 'اردو',
                  subtitle: 'مولانا فتح محمد جالندھری',
                  selected: selectedTranslation == 97,
                  accentColor: _kGreen,
                  onTap: () { ref.read(selectedTranslationProvider.notifier).state = 97;
                    setState(() => _translationExpanded = false); },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Audio Tarjumah ───────────────────────────────────────────────
            _SectionLabel('Audio Tarjumah'),
            const SizedBox(height: 10),
            _GlassCard(
              accentColor: tarjumahMode ? _kGold : null,
              child: Row(
                children: [
                  _IconBox(icon: Icons.record_voice_over_rounded, color: _kGold),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Urdu Audio Tarjumah',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        tarjumahMode
                            ? 'ON — Shamshad Ali Khan'
                            : 'Off — Standard recitation',
                        style: GoogleFonts.outfit(
                            color: tarjumahMode ? _kGold : Colors.white38, fontSize: 11),
                      ),
                    ]),
                  ),
                  Switch(
                    value: tarjumahMode,
                    onChanged: (val) {
                      ref.read(tarjumahModeProvider.notifier).state = val;
                      ref.read(audioPlayerServiceProvider).player.stop();
                      ref.read(interleavedAudioServiceProvider).player.stop();
                    },
                    activeColor: _kGold,
                    activeTrackColor: _kGold.withValues(alpha: 0.25),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Library ──────────────────────────────────────────────────────
            _SectionLabel('Library'),
            const SizedBox(height: 10),

            // Downloads
            _GlassCard(
              child: InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DownloadsScreen())),
                borderRadius: BorderRadius.circular(14),
                child: Row(children: [
                  _IconBox(icon: Icons.download_for_offline_rounded, color: _kGreen),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Downloads',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Manage your offline Surahs',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            // Download Entire Quran
            _QuranDownloadTile(bulkState: bulkState),
            const SizedBox(height: 10),

            // Tajweed Guide
            _GlassCard(
              child: InkWell(
                onTap: () => _showTajweedGuide(context),
                borderRadius: BorderRadius.circular(14),
                child: Row(children: [
                  _IconBox(icon: Icons.palette_rounded, color: _kGold),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tajweed Guide',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Color-coded pronunciation rules',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ── Current Reciter ──────────────────────────────────────────────
            _SectionLabel('Current Reciter'),
            const SizedBox(height: 10),
            if (selectedImam != null)
              _GlassCard(
                accentColor: _kGreen.withValues(alpha: 0.3),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: _kGreen.withValues(alpha: 0.15),
                    child: Text(
                      selectedImam.name.split(' ').last[0],
                      style: const TextStyle(color: _kGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(selectedImam.name,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(selectedImam.country,
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ])),
                  const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                ]),
              ),
            const SizedBox(height: 24),

            // ── About ────────────────────────────────────────────────────────
            _SectionLabel('About'),
            const SizedBox(height: 10),
            _GlassCard(
              child: Column(children: [
                _InfoRow(icon: Icons.info_outline_rounded, label: 'App', value: 'Quran2U'),
                const Divider(color: Colors.white10, height: 16),
                _InfoRow(icon: Icons.tag_rounded, label: 'Version', value: '1.0.0'),
                const Divider(color: Colors.white10, height: 16),
                _InfoRow(icon: Icons.library_music_outlined, label: 'Audio', value: 'mp3quran.net'),
                const Divider(color: Colors.white10, height: 16),
                _InfoRow(icon: Icons.api_outlined, label: 'Data', value: 'api.quran.com'),
              ]),
            ),
            const SizedBox(height: 52),

            // ── Footer ───────────────────────────────────────────────────────
            Center(
              child: Column(children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
                    children: const [
                      TextSpan(text: 'Made with '),
                      TextSpan(text: '❤️'),
                      TextSpan(text: ' by '),
                      TextSpan(text: '@d0tahmed',
                          style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A gift for my Mother and my late Grandmother.\nMay Allah reward both.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.white24,
                      height: 1.65, fontStyle: FontStyle.italic),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showTajweedGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1421),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _TajweedGuideSheet(),
    );
  }
}

// ── Tajweed Guide Sheet ────────────────────────────────────────────────────────
class _TajweedGuideSheet extends StatelessWidget {
  const _TajweedGuideSheet();

  static const _rules = <_TajweedRule>[
    _TajweedRule(
      name: 'Ghunnah', nameArabic: 'غُنَّة',
      color: Color(0xFFFF7E1E),
      description: 'Nasal sound held for 2 counts',
      example: 'مِنَ', exampleHighlight: 'نَ',
    ),
    _TajweedRule(
      name: 'Ikhfa', nameArabic: 'إِخْفَاء',
      color: Color(0xFFD500B2),
      description: 'Hidden pronunciation of noon sakinah/tanween',
      example: 'مِنْ بَعْدِ', exampleHighlight: 'نْ',
    ),
    _TajweedRule(
      name: 'Ikhfa Shafawi', nameArabic: 'إِخْفَاء شَفَوِي',
      color: Color(0xFFD500B2),
      description: 'Hidden meem sakinah before baa',
      example: 'تَرْمِيهِمْ بِحِجَارَةٍ', exampleHighlight: 'مْ بِ',
    ),
    _TajweedRule(
      name: 'Idgham', nameArabic: 'إِدْغَام',
      color: Color(0xFF169200),
      description: 'Merging noon sakinah into the next letter',
      example: 'مِنْ وَلِيٍّ', exampleHighlight: 'نْ وَ',
    ),
    _TajweedRule(
      name: 'Iqlab', nameArabic: 'إِقْلَاب',
      color: Color(0xFF26BFFD),
      description: 'Noon sakinah converts to meem before baa',
      example: 'مِنۢ بَعْدِ', exampleHighlight: 'نۢ',
    ),
    _TajweedRule(
      name: 'Qalqalah', nameArabic: 'قَلْقَلَة',
      color: Color(0xFFDD0000),
      description: 'Echoing bounce on letters ق ط ب ج د',
      example: 'يَخْلُقْ', exampleHighlight: 'قْ',
    ),
    _TajweedRule(
      name: 'Madd (Normal)', nameArabic: 'مَدّ طَبِيعِي',
      color: Color(0xFF537FFF),
      description: 'Natural elongation — 2 counts',
      example: 'قَالَ', exampleHighlight: 'ـَا',
    ),
    _TajweedRule(
      name: 'Madd (Permissible)', nameArabic: 'مَدّ جَائِز',
      color: Color(0xFF4050FF),
      description: 'Elongation 2-4-6 counts at end of verse',
      example: 'الرَّحِيمِ', exampleHighlight: 'ِي',
    ),
    _TajweedRule(
      name: 'Madd (Obligatory)', nameArabic: 'مَدّ لَازِم',
      color: Color(0xFF2144C1),
      description: 'Obligatory elongation — 6 counts',
      example: 'الضَّآلِّين', exampleHighlight: 'ٓا',
    ),
    _TajweedRule(
      name: 'Madd (Necessary)', nameArabic: 'مَدّ وَاجِب',
      color: Color(0xFF000EBC),
      description: 'Required elongation — 4-5 counts',
      example: 'جَآءَ', exampleHighlight: 'ٓا',
    ),
    _TajweedRule(
      name: 'Laam Shamsiyah', nameArabic: 'لَام شَمْسِيَّة',
      color: Color(0xFFAAAAAA),
      description: 'Silent laam that assimilates into sun letters',
      example: 'الشَّمْسِ', exampleHighlight: 'ل',
    ),
    _TajweedRule(
      name: 'Hamzat ul-Wasl', nameArabic: 'هَمْزَة الْوَصْل',
      color: Color(0xFFAAAAAA),
      description: 'Connecting hamza — silent when continuing',
      example: 'ٱلْحَمْدُ', exampleHighlight: 'ٱ',
    ),
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
            // Header
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
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tajweed Guide',
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Color-coded pronunciation rules',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            // Rules list
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
                        // Color dot
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
                        // Info
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
                        // Arabic example
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

// ── Download Entire Quran tile ─────────────────────────────────────────────────
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
            _IconBox(icon: Icons.download_rounded, color: _kGreen),
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

  void _showDownloadWizard(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1421),
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
                        _IconBox(icon: Icons.translate_rounded, color: _kGold),
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
                          activeColor: _kGold,
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

class _ExpandableCard extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final Color accentColor;
  final IconData iconData;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ExpandableCard({
    required this.expanded, required this.onToggle, required this.accentColor,
    required this.iconData, required this.title, required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: expanded ? accentColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              _IconBox(icon: iconData, color: accentColor),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: GoogleFonts.outfit(color: accentColor, fontSize: 11)),
              ])),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38, size: 22),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: [
            const Divider(color: Colors.white10, height: 1),
            ...children,
          ]),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ]),
    );
  }
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
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Colors.white24, size: 16),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ]);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.outfit(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5));
}