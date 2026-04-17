import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/widgets/glass_panel.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBg = AppColorsV2.bg;
const _kCard = AppColorsV2.surfaceLow;

class DailyInspirationScreen extends StatelessWidget {
  const DailyInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rotates daily — day 1 → index 0, day 31 → index 30
    final dayOfMonth   = DateTime.now().day;
    final contentIndex = (dayOfMonth - 1) % _dailyData.length;
    final todayData    = _dailyData[contentIndex];

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
              physics: const NeverScrollableScrollPhysics(),
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
                            Text('Daily Inspiration',
                                style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6)),
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
                          Text('Ayah of the Day',
                              style: GoogleFonts.manrope(
                                  color: _kGold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0)),
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
                              maxLines: 4,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  height: 1.9,
                                  fontFamily: GoogleFonts.amiri().fontFamily),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: Colors.white10, height: 1),
                            ),
                            Text(
                              '"${todayData.translationAyah}"',
                              textAlign: TextAlign.center,
                              maxLines: 5,
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
                          Text('Hadith of the Day',
                              style: GoogleFonts.manrope(
                                  color: _kGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0)),
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

// ─────────────────────────────────────────────────────────────────────────────
// 31 daily entries — one per day of the month (fully offline, hardcoded)
// ─────────────────────────────────────────────────────────────────────────────

class _DailyContent {
  final String arabicAyah;
  final String translationAyah;
  final String referenceAyah;
  final String hadithText;
  final String referenceHadith;
  const _DailyContent(this.arabicAyah, this.translationAyah,
      this.referenceAyah, this.hadithText, this.referenceHadith);
}

const _dailyData = [
  // 1
  _DailyContent(
    "فَٱذۡكُرُونِیٓ أَذۡكُرۡكُمۡ وَٱشۡكُرُوا۟ لِی وَلَا تَكۡفُرُونِ",
    "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
    "Surah Al-Baqarah 2:152",
    "The most beloved of deeds to Allah are those that are most consistent, even if they are small.",
    "Sahih al-Bukhari 6464",
  ),
  // 2
  _DailyContent(
    "إِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا",
    "Indeed, with hardship will be ease.",
    "Surah Ash-Sharh 94:6",
    "There is no disease that Allah has created except that He also has created its treatment.",
    "Sahih al-Bukhari 5678",
  ),
  // 3
  _DailyContent(
    "وَهُوَ مَعَكُمۡ أَیۡنَ مَا كُنتُمۡ",
    "And He is with you wherever you are.",
    "Surah Al-Hadid 57:4",
    "Whoever travels a path in search of knowledge, Allah will make easy for him a path to Paradise.",
    "Sahih Muslim 2699",
  ),
  // 4
  _DailyContent(
    "وَعَسَىٰٓ أَن تَكۡرَهُوا۟ شَیۡـًٔا وَهُوَ خَیۡرٌ لَّكُمۡ",
    "But perhaps you hate a thing and it is good for you.",
    "Surah Al-Baqarah 2:216",
    "The strong person is not the one who can overpower others. The strong person is the one who controls himself when he is angry.",
    "Sahih al-Bukhari 6114",
  ),
  // 5
  _DailyContent(
    "حَسۡبُنَا ٱللَّهُ وَنِعۡمَ ٱلۡوَكِیلُ",
    "Allah is sufficient for us, and He is the best Disposer of affairs.",
    "Surah Al-Imran 3:173",
    "Be mindful of Allah and Allah will protect you. Be mindful of Allah and you will find Him in front of you.",
    "Jami' at-Tirmidhi 2516",
  ),
  // 6
  _DailyContent(
    "إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِینَ",
    "Indeed, Allah is with the patient.",
    "Surah Al-Baqarah 2:153",
    "Wondrous is the affair of the believer, for all of his affairs are good. If something pleasing befalls him he is grateful, and that is good for him. If something harmful befalls him he is patient, and that is good for him.",
    "Sahih Muslim 2999",
  ),
  // 7
  _DailyContent(
    "وَقُل رَّبِّ زِدۡنِی عِلۡمًا",
    "And say: My Lord, increase me in knowledge.",
    "Surah Ta-Ha 20:114",
    "Seeking knowledge is an obligation upon every Muslim.",
    "Sunan Ibn Majah 224",
  ),
  // 8
  _DailyContent(
    "إِنَّ ٱللَّهَ لَا یُغَیِّرُ مَا بِقَوۡمٍ حَتَّىٰ یُغَیِّرُوا۟ مَا بِأَنفُسِهِمۡ",
    "Indeed, Allah will not change the condition of a people until they change what is in themselves.",
    "Surah Ar-Ra'd 13:11",
    "None of you will believe until he loves for his brother what he loves for himself.",
    "Sahih al-Bukhari 13",
  ),
  // 9
  _DailyContent(
    "وَٱسۡتَعِینُوا۟ بِٱلصَّبۡرِ وَٱلصَّلَوٰةِ",
    "And seek help through patience and prayer.",
    "Surah Al-Baqarah 2:45",
    "The prayer is a light, charity is a proof, patience is illumination, and the Quran is evidence for or against you.",
    "Sahih Muslim 223",
  ),
  // 10
  _DailyContent(
    "وَمَن یَتَّقِ ٱللَّهَ یَجۡعَل لَّهُۥ مَخۡرَجًا",
    "And whoever fears Allah — He will make for him a way out.",
    "Surah At-Talaq 65:2",
    "A man is upon the religion of his close friend, so let each one of you look carefully at whom he takes as a close friend.",
    "Jami' at-Tirmidhi 2378",
  ),
  // 11
  _DailyContent(
    "وَلَذِكۡرُ ٱللَّهِ أَكۡبَرُ",
    "And the remembrance of Allah is greater.",
    "Surah Al-Ankabut 29:45",
    "The comparison of the one who remembers his Lord and the one who does not is like the living and the dead.",
    "Sahih al-Bukhari 6407",
  ),
  // 12
  _DailyContent(
    "قُلۡ هُوَ ٱللَّهُ أَحَدٌ",
    "Say: He is Allah, the One.",
    "Surah Al-Ikhlas 112:1",
    "By Allah, if you were to put your full trust in Allah as He deserves, He would provide for you just as He provides for the birds — they go out in the morning hungry and return in the evening full.",
    "Jami' at-Tirmidhi 2344",
  ),
  // 13
  _DailyContent(
    "وَمَا تَوۡفِیقِیٓ إِلَّا بِٱللَّهِ",
    "And my success is not but through Allah.",
    "Surah Hud 11:88",
    "Make things easy, and do not make things difficult. Give glad tidings, and do not repel people.",
    "Sahih al-Bukhari 69",
  ),
  // 14
  _DailyContent(
    "فَإِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا ۝ إِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا",
    "For indeed, with hardship will be ease. Indeed, with hardship will be ease.",
    "Surah Ash-Sharh 94:5-6",
    "The believer's shade on the Day of Resurrection will be his charity.",
    "Jami' at-Tirmidhi 1925",
  ),
  // 15
  _DailyContent(
    "رَبَّنَا ٱغۡفِرۡ لَنَا ذُنُوبَنَا وَإِسۡرَافَنَا فِیٓ أَمۡرِنَا",
    "Our Lord, forgive us our sins and the excess committed in our affairs.",
    "Surah Al-Imran 3:147",
    "He who eats and is grateful is like the one who fasts and is patient.",
    "Sunan Ibn Majah 1765",
  ),
  // 16
  _DailyContent(
    "وَمَا خَلَقۡتُ ٱلۡجِنَّ وَٱلۡإِنسَ إِلَّا لِیَعۡبُدُونِ",
    "I did not create jinn and humans except to worship Me.",
    "Surah Adh-Dhariyat 51:56",
    "Kindness is not found in anything except that it beautifies it, and it is not removed from anything except that it disgraces it.",
    "Sahih Muslim 2594",
  ),
  // 17
  _DailyContent(
    "يُرِيدُ ٱللَّهُ بِكُمُ ٱلۡيُسۡرَ وَلَا يُرِيدُ بِكُمُ ٱلۡعُسۡرَ",
    "Allah intends for you ease and does not intend for you hardship.",
    "Surah Al-Baqarah 2:185",
    "The best among you are those who have the best manners and character.",
    "Sahih al-Bukhari 3559",
  ),
  // 18
  _DailyContent(
    "وَٱللَّهُ یُحِبُّ ٱلۡمُحۡسِنِینَ",
    "And Allah loves those who do good.",
    "Surah Al-Imran 3:134",
    "Whoever removes a worldly grief from a believer, Allah will remove from him one of the griefs of the Day of Resurrection.",
    "Sahih Muslim 2699",
  ),
  // 19
  _DailyContent(
    "وَلَا تَیۡـَٔسُوا۟ مِن رَّوۡحِ ٱللَّهِ",
    "And do not despair of relief from Allah.",
    "Surah Yusuf 12:87",
    "Do not belittle any act of kindness, even if it is just meeting your brother with a cheerful face.",
    "Sahih Muslim 2626",
  ),
  // 20
  _DailyContent(
    "وَٱللَّهُ خَیۡرُ ٱلۡرَّٰزِقِینَ",
    "And Allah is the best of providers.",
    "Surah Al-Jumu'ah 62:11",
    "The upper hand is better than the lower hand. The upper hand is the one that gives and the lower is the one that takes.",
    "Sahih al-Bukhari 1429",
  ),
  // 21
  _DailyContent(
    "وَتَوَكَّلۡ عَلَى ٱللَّهِ وَكَفَىٰ بِٱللَّهِ وَكِیلًا",
    "And rely upon Allah; and sufficient is Allah as Disposer of affairs.",
    "Surah Al-Ahzab 33:3",
    "Preserve what Allah has entrusted to you, and Allah will preserve you. Know Allah in times of ease and He will know you in times of hardship.",
    "Jami' at-Tirmidhi 2516",
  ),
  // 22
  _DailyContent(
    "إِنَّمَا ٱلۡمُؤۡمِنُونَ إِخۡوَةٌ",
    "The believers are but brothers.",
    "Surah Al-Hujurat 49:10",
    "He who believes in Allah and the Last Day should speak good or keep silent.",
    "Sahih al-Bukhari 6018",
  ),
  // 23
  _DailyContent(
    "وَٱللَّهُ لَطِیفُۢ بِعِبَادِهِۦ",
    "And Allah is Kind to His servants.",
    "Surah Ash-Shura 42:19",
    "When Allah loves a servant, He tests him. Whoever accepts that earns His pleasure; whoever is discontent earns His wrath.",
    "Jami' at-Tirmidhi 2396",
  ),
  // 24
  _DailyContent(
    "ٱدۡعُونِیٓ أَسۡتَجِبۡ لَكُمۡ",
    "Call upon Me; I will respond to you.",
    "Surah Ghafir 40:60",
    "Dua is worship.",
    "Jami' at-Tirmidhi 3247",
  ),
  // 25
  _DailyContent(
    "وَمَن یَتَوَكَّلۡ عَلَى ٱللَّهِ فَهُوَ حَسۡبُهُۥٓ",
    "And whoever relies upon Allah — then He is sufficient for him.",
    "Surah At-Talaq 65:3",
    "The most complete of the believers in faith are those with the best character, and the best of you are those who are best to their women.",
    "Jami' at-Tirmidhi 1162",
  ),
  // 26
  _DailyContent(
    "ٱلَّذِینَ ءَامَنُوا۟ وَتَطۡمَئِنُّ قُلُوبُهُم بِذِكۡرِ ٱللَّهِ",
    "Those who have believed and whose hearts are assured by the remembrance of Allah.",
    "Surah Ar-Ra'd 13:28",
    "There are two blessings which many people lose: health and free time.",
    "Sahih al-Bukhari 6412",
  ),
  // 27
  _DailyContent(
    "وَٱلَّذِینَ جَـٰهَدُوا۟ فِینَا لَنَهۡدِیَنَّهُمۡ سُبُلَنَا",
    "And those who strive for Us — We will surely guide them to Our ways.",
    "Surah Al-Ankabut 29:69",
    "The best of you is the one who learns the Quran and teaches it.",
    "Sahih al-Bukhari 5027",
  ),
  // 28
  _DailyContent(
    "رَبَّنَا لَا تُزِغۡ قُلُوبَنَا بَعۡدَ إِذۡ هَدَیۡتَنَا",
    "Our Lord, do not let our hearts deviate after You have guided us.",
    "Surah Al-Imran 3:8",
    "Actions are judged by their intentions, and every person will get the reward according to what he has intended.",
    "Sahih al-Bukhari 1",
  ),
  // 29
  _DailyContent(
    "إِنَّ ٱللَّهَ كَانَ عَلِیمًا حَكِیمًا",
    "Indeed, Allah is ever Knowing and Wise.",
    "Surah An-Nisa 4:11",
    "Allah does not look at your appearance or your wealth, but He looks at your hearts and your deeds.",
    "Sahih Muslim 2564",
  ),
  // 30
  _DailyContent(
    "وَبَشِّرِ ٱلصَّـٰبِرِینَ",
    "And give good tidings to the patient.",
    "Surah Al-Baqarah 2:155",
    "Whoever would love to be saved from the Fire and enter Paradise, then let him die with faith in Allah and the Last Day.",
    "Sahih Muslim 1844",
  ),
  // 31
  _DailyContent(
    "قُلۡ إِنَّ صَلَاتِی وَنُسُكِی وَمَحۡیَایَ وَمَمَاتِی لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ",
    "Say: Indeed, my prayer, my rites of sacrifice, my living and my dying are for Allah, Lord of the worlds.",
    "Surah Al-An'am 6:162",
    "The most beloved speech to Allah is when the servant says: Glory be to You, O Allah, and I praise You, and blessed is Your Name, and exalted is Your Majesty, and there is no god but You.",
    "Sahih Muslim 601",
  ),
  // 32
  _DailyContent(
    "فَابْتَغُوا عِنْدَ اللَّهِ الرِّزْقَ وَاعْبُدُوهُ وَاشْكُرُوا لَهُ",
    "So seek provision from Allah, and worship Him and be grateful to Him.",
    "Surah Al-'Ankabut 29:17",
    "The most beloved of places to Allah are the mosques, and the most hated of places to Allah are the markets.",
    "Sahih Muslim 671",
  ),
  // 33
  _DailyContent(
    "إِنَّمَا یُوَفَّى ٱلصَّـٰبِرُونَ أَجۡرَهُم بِغَیۡرِ حِسَابٍ",
    "Indeed, the patient will be given their reward without account.",
    "Surah Az-Zumar 39:10",
    "No fatigue, nor disease, nor sorrow, nor sadness, nor hurt, nor distress befalls a Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his sins for that.",
    "Sahih al-Bukhari 5641",
  ),
  // 34
  _DailyContent(
    "لَا یُكَلِّفُ ٱللَّهُ نَفۡسًا إِلَّا وُسۡعَهَا",
    "Allah does not burden a soul beyond that it can bear.",
    "Surah Al-Baqarah 2:286",
    "Allah says: 'I am as My servant thinks I am. I am with him when he makes mention of Me.'",
    "Sahih al-Bukhari 7405",
  ),
  // 35
  _DailyContent(
    "وَٱسۡتَعِینُوا۟ بِٱلصَّبۡرِ وَٱلصَّلَوٰةِ",
    "And seek help through patience and prayer.",
    "Surah Al-Baqarah 2:45",
    "The first matter that the slave will be brought to account for on the Day of Judgment is the prayer.",
    "Sunan Ibn Majah 1425",
  ),
  // 36
  _DailyContent(
    "وَٱللَّهُ یَعۡلَمُ وَأَنتُمۡ لَا تَعۡلَمُونَ",
    "And Allah knows, while you know not.",
    "Surah Al-Baqarah 2:216",
    "Verily, Allah does not look to your bodies nor to your faces, but He looks to your hearts.",
    "Sahih Muslim 2564",
  ),
];