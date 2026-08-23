// lib/data/daily_inspiration_data.dart
//
// The Daily Inspiration pool: one ayah and one hadith per rotation slot.
//
// This lives in `data/` rather than inside the screen because two callers need
// the SAME entry for the same calendar day — the screen that renders it, and
// the notification that announces it. When the pool was a private list inside
// the screen, the notification could only say "tap to read today's ayah",
// because it had no way to know what today's ayah actually was.
//
// Use [dailyIndexFor] everywhere. Do not recompute the index by hand; a second
// formula is a second chance for the notification and the screen to disagree.

import 'package:flutter/foundation.dart';

@immutable
class DailyContent {
  final String arabicAyah;
  final String translationAyah;
  final String referenceAyah;
  final String hadithText;
  final String referenceHadith;

  const DailyContent(
    this.arabicAyah,
    this.translationAyah,
    this.referenceAyah,
    this.hadithText,
    this.referenceHadith,
  );
}

/// Which entry belongs to [date].
///
/// Counts whole days from a fixed epoch, so the index advances by exactly one
/// per calendar day and wraps over the entire pool. Both operands are UTC, so
/// a daylight-saving shift can never make a day repeat or vanish.
///
/// It deliberately does NOT use `date.day`: the original code did
/// `(day - 1) % length`, which tops out at 31 and stranded every entry past
/// index 30 no matter how many were written.
int dailyIndexFor(DateTime date) {
  final days = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(2000, 1, 1))
      .inDays;
  return days % kDailyInspirations.length;
}

/// Today's entry, in the device's local calendar.
DailyContent get todayInspiration =>
    kDailyInspirations[dailyIndexFor(DateTime.now())];

/// Every Arabic string here was taken verbatim from the Quran.com API
/// (`/verses/by_key/<key>?fields=text_uthmani`). Where an excerpt was needed to
/// fit the card it was cut at a clause boundary — never retyped — so the
/// diacritics are exactly as published.
const List<DailyContent> kDailyInspirations = <DailyContent>[

  // 1
  DailyContent(
    "فَٱذۡكُرُونِیٓ أَذۡكُرۡكُمۡ وَٱشۡكُرُوا۟ لِی وَلَا تَكۡفُرُونِ",
    "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
    "Surah Al-Baqarah 2:152",
    "The most beloved of deeds to Allah are those that are most consistent, even if they are small.",
    "Sahih al-Bukhari 6464",
  ),
  // 2
  DailyContent(
    "إِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا",
    "Indeed, with hardship will be ease.",
    "Surah Ash-Sharh 94:6",
    "There is no disease that Allah has created except that He also has created its treatment.",
    "Sahih al-Bukhari 5678",
  ),
  // 3
  DailyContent(
    "وَهُوَ مَعَكُمۡ أَیۡنَ مَا كُنتُمۡ",
    "And He is with you wherever you are.",
    "Surah Al-Hadid 57:4",
    "Whoever travels a path in search of knowledge, Allah will make easy for him a path to Paradise.",
    "Sahih Muslim 2699",
  ),
  // 4
  DailyContent(
    "وَعَسَىٰٓ أَن تَكۡرَهُوا۟ شَیۡـًٔا وَهُوَ خَیۡرٌ لَّكُمۡ",
    "But perhaps you hate a thing and it is good for you.",
    "Surah Al-Baqarah 2:216",
    "The strong person is not the one who can overpower others. The strong person is the one who controls himself when he is angry.",
    "Sahih al-Bukhari 6114",
  ),
  // 5
  DailyContent(
    "حَسۡبُنَا ٱللَّهُ وَنِعۡمَ ٱلۡوَكِیلُ",
    "Allah is sufficient for us, and He is the best Disposer of affairs.",
    "Surah Al-Imran 3:173",
    "Be mindful of Allah and Allah will protect you. Be mindful of Allah and you will find Him in front of you.",
    "Jami' at-Tirmidhi 2516",
  ),
  // 6
  DailyContent(
    "إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِینَ",
    "Indeed, Allah is with the patient.",
    "Surah Al-Baqarah 2:153",
    "Wondrous is the affair of the believer, for all of his affairs are good. If something pleasing befalls him he is grateful, and that is good for him. If something harmful befalls him he is patient, and that is good for him.",
    "Sahih Muslim 2999",
  ),
  // 7
  DailyContent(
    "وَقُل رَّبِّ زِدۡنِی عِلۡمًا",
    "And say: My Lord, increase me in knowledge.",
    "Surah Ta-Ha 20:114",
    "Seeking knowledge is an obligation upon every Muslim.",
    "Sunan Ibn Majah 224",
  ),
  // 8
  DailyContent(
    "إِنَّ ٱللَّهَ لَا یُغَیِّرُ مَا بِقَوۡمٍ حَتَّىٰ یُغَیِّرُوا۟ مَا بِأَنفُسِهِمۡ",
    "Indeed, Allah will not change the condition of a people until they change what is in themselves.",
    "Surah Ar-Ra'd 13:11",
    "None of you will believe until he loves for his brother what he loves for himself.",
    "Sahih al-Bukhari 13",
  ),
  // 9
  DailyContent(
    "وَٱسۡتَعِینُوا۟ بِٱلصَّبۡرِ وَٱلصَّلَوٰةِ",
    "And seek help through patience and prayer.",
    "Surah Al-Baqarah 2:45",
    "The prayer is a light, charity is a proof, patience is illumination, and the Quran is evidence for or against you.",
    "Sahih Muslim 223",
  ),
  // 10
  DailyContent(
    "وَمَن یَتَّقِ ٱللَّهَ یَجۡعَل لَّهُۥ مَخۡرَجًا",
    "And whoever fears Allah — He will make for him a way out.",
    "Surah At-Talaq 65:2",
    "A man is upon the religion of his close friend, so let each one of you look carefully at whom he takes as a close friend.",
    "Jami' at-Tirmidhi 2378",
  ),
  // 11
  DailyContent(
    "وَلَذِكۡرُ ٱللَّهِ أَكۡبَرُ",
    "And the remembrance of Allah is greater.",
    "Surah Al-Ankabut 29:45",
    "The comparison of the one who remembers his Lord and the one who does not is like the living and the dead.",
    "Sahih al-Bukhari 6407",
  ),
  // 12
  DailyContent(
    "قُلۡ هُوَ ٱللَّهُ أَحَدٌ",
    "Say: He is Allah, the One.",
    "Surah Al-Ikhlas 112:1",
    "By Allah, if you were to put your full trust in Allah as He deserves, He would provide for you just as He provides for the birds — they go out in the morning hungry and return in the evening full.",
    "Jami' at-Tirmidhi 2344",
  ),
  // 13
  DailyContent(
    "وَمَا تَوۡفِیقِیٓ إِلَّا بِٱللَّهِ",
    "And my success is not but through Allah.",
    "Surah Hud 11:88",
    "Make things easy, and do not make things difficult. Give glad tidings, and do not repel people.",
    "Sahih al-Bukhari 69",
  ),
  // 14
  DailyContent(
    "فَإِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا ۝ إِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا",
    "For indeed, with hardship will be ease. Indeed, with hardship will be ease.",
    "Surah Ash-Sharh 94:5-6",
    "The believer's shade on the Day of Resurrection will be his charity.",
    "Jami' at-Tirmidhi 1925",
  ),
  // 15
  DailyContent(
    "رَبَّنَا ٱغۡفِرۡ لَنَا ذُنُوبَنَا وَإِسۡرَافَنَا فِیٓ أَمۡرِنَا",
    "Our Lord, forgive us our sins and the excess committed in our affairs.",
    "Surah Al-Imran 3:147",
    "He who eats and is grateful is like the one who fasts and is patient.",
    "Sunan Ibn Majah 1765",
  ),
  // 16
  DailyContent(
    "وَمَا خَلَقۡتُ ٱلۡجِنَّ وَٱلۡإِنسَ إِلَّا لِیَعۡبُدُونِ",
    "I did not create jinn and humans except to worship Me.",
    "Surah Adh-Dhariyat 51:56",
    "Kindness is not found in anything except that it beautifies it, and it is not removed from anything except that it disgraces it.",
    "Sahih Muslim 2594",
  ),
  // 17
  DailyContent(
    "يُرِيدُ ٱللَّهُ بِكُمُ ٱلۡيُسۡرَ وَلَا يُرِيدُ بِكُمُ ٱلۡعُسۡرَ",
    "Allah intends for you ease and does not intend for you hardship.",
    "Surah Al-Baqarah 2:185",
    "The best among you are those who have the best manners and character.",
    "Sahih al-Bukhari 3559",
  ),
  // 18
  DailyContent(
    "وَٱللَّهُ یُحِبُّ ٱلۡمُحۡسِنِینَ",
    "And Allah loves those who do good.",
    "Surah Al-Imran 3:134",
    "Whoever removes a worldly grief from a believer, Allah will remove from him one of the griefs of the Day of Resurrection.",
    "Sahih Muslim 2699",
  ),
  // 19
  DailyContent(
    "وَلَا تَیۡـَٔسُوا۟ مِن رَّوۡحِ ٱللَّهِ",
    "And do not despair of relief from Allah.",
    "Surah Yusuf 12:87",
    "Do not belittle any act of kindness, even if it is just meeting your brother with a cheerful face.",
    "Sahih Muslim 2626",
  ),
  // 20
  DailyContent(
    "وَٱللَّهُ خَیۡرُ ٱلۡرَّٰزِقِینَ",
    "And Allah is the best of providers.",
    "Surah Al-Jumu'ah 62:11",
    "The upper hand is better than the lower hand. The upper hand is the one that gives and the lower is the one that takes.",
    "Sahih al-Bukhari 1429",
  ),
  // 21
  DailyContent(
    "وَتَوَكَّلۡ عَلَى ٱللَّهِ وَكَفَىٰ بِٱللَّهِ وَكِیلًا",
    "And rely upon Allah; and sufficient is Allah as Disposer of affairs.",
    "Surah Al-Ahzab 33:3",
    "Preserve what Allah has entrusted to you, and Allah will preserve you. Know Allah in times of ease and He will know you in times of hardship.",
    "Jami' at-Tirmidhi 2516",
  ),
  // 22
  DailyContent(
    "إِنَّمَا ٱلۡمُؤۡمِنُونَ إِخۡوَةٌ",
    "The believers are but brothers.",
    "Surah Al-Hujurat 49:10",
    "He who believes in Allah and the Last Day should speak good or keep silent.",
    "Sahih al-Bukhari 6018",
  ),
  // 23
  DailyContent(
    "وَٱللَّهُ لَطِیفُۢ بِعِبَادِهِۦ",
    "And Allah is Kind to His servants.",
    "Surah Ash-Shura 42:19",
    "When Allah loves a servant, He tests him. Whoever accepts that earns His pleasure; whoever is discontent earns His wrath.",
    "Jami' at-Tirmidhi 2396",
  ),
  // 24
  DailyContent(
    "ٱدۡعُونِیٓ أَسۡتَجِبۡ لَكُمۡ",
    "Call upon Me; I will respond to you.",
    "Surah Ghafir 40:60",
    "Dua is worship.",
    "Jami' at-Tirmidhi 3247",
  ),
  // 25
  DailyContent(
    "وَمَن یَتَوَكَّلۡ عَلَى ٱللَّهِ فَهُوَ حَسۡبُهُۥٓ",
    "And whoever relies upon Allah — then He is sufficient for him.",
    "Surah At-Talaq 65:3",
    "The most complete of the believers in faith are those with the best character, and the best of you are those who are best to their women.",
    "Jami' at-Tirmidhi 1162",
  ),
  // 26
  DailyContent(
    "ٱلَّذِینَ ءَامَنُوا۟ وَتَطۡمَئِنُّ قُلُوبُهُم بِذِكۡرِ ٱللَّهِ",
    "Those who have believed and whose hearts are assured by the remembrance of Allah.",
    "Surah Ar-Ra'd 13:28",
    "There are two blessings which many people lose: health and free time.",
    "Sahih al-Bukhari 6412",
  ),
  // 27
  DailyContent(
    "وَٱلَّذِینَ جَـٰهَدُوا۟ فِینَا لَنَهۡدِیَنَّهُمۡ سُبُلَنَا",
    "And those who strive for Us — We will surely guide them to Our ways.",
    "Surah Al-Ankabut 29:69",
    "The best of you is the one who learns the Quran and teaches it.",
    "Sahih al-Bukhari 5027",
  ),
  // 28
  DailyContent(
    "رَبَّنَا لَا تُزِغۡ قُلُوبَنَا بَعۡدَ إِذۡ هَدَیۡتَنَا",
    "Our Lord, do not let our hearts deviate after You have guided us.",
    "Surah Al-Imran 3:8",
    "Actions are judged by their intentions, and every person will get the reward according to what he has intended.",
    "Sahih al-Bukhari 1",
  ),
  // 29
  DailyContent(
    "إِنَّ ٱللَّهَ كَانَ عَلِیمًا حَكِیمًا",
    "Indeed, Allah is ever Knowing and Wise.",
    "Surah An-Nisa 4:11",
    "Allah does not look at your appearance or your wealth, but He looks at your hearts and your deeds.",
    "Sahih Muslim 2564",
  ),
  // 30
  DailyContent(
    "وَبَشِّرِ ٱلصَّـٰبِرِینَ",
    "And give good tidings to the patient.",
    "Surah Al-Baqarah 2:155",
    "Whoever would love to be saved from the Fire and enter Paradise, then let him die with faith in Allah and the Last Day.",
    "Sahih Muslim 1844",
  ),
  // 31
  DailyContent(
    "قُلۡ إِنَّ صَلَاتِی وَنُسُكِی وَمَحۡیَایَ وَمَمَاتِی لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ",
    "Say: Indeed, my prayer, my rites of sacrifice, my living and my dying are for Allah, Lord of the worlds.",
    "Surah Al-An'am 6:162",
    "The most beloved speech to Allah is when the servant says: Glory be to You, O Allah, and I praise You, and blessed is Your Name, and exalted is Your Majesty, and there is no god but You.",
    "Sahih Muslim 601",
  ),
  // 32
  DailyContent(
    "فَابْتَغُوا عِنْدَ اللَّهِ الرِّزْقَ وَاعْبُدُوهُ وَاشْكُرُوا لَهُ",
    "So seek provision from Allah, and worship Him and be grateful to Him.",
    "Surah Al-'Ankabut 29:17",
    "The most beloved of places to Allah are the mosques, and the most hated of places to Allah are the markets.",
    "Sahih Muslim 671",
  ),
  // 33
  DailyContent(
    "إِنَّمَا یُوَفَّى ٱلصَّـٰبِرُونَ أَجۡرَهُم بِغَیۡرِ حِسَابٍ",
    "Indeed, the patient will be given their reward without account.",
    "Surah Az-Zumar 39:10",
    "No fatigue, nor disease, nor sorrow, nor sadness, nor hurt, nor distress befalls a Muslim, even if it were the prick he receives from a thorn, but that Allah expiates some of his sins for that.",
    "Sahih al-Bukhari 5641",
  ),
  // 34
  DailyContent(
    "لَا یُكَلِّفُ ٱللَّهُ نَفۡسًا إِلَّا وُسۡعَهَا",
    "Allah does not burden a soul beyond that it can bear.",
    "Surah Al-Baqarah 2:286",
    "Allah says: 'I am as My servant thinks I am. I am with him when he makes mention of Me.'",
    "Sahih al-Bukhari 7405",
  ),
  // 35
  DailyContent(
    "وَٱسۡتَعِینُوا۟ بِٱلصَّبۡرِ وَٱلصَّلَوٰةِ",
    "And seek help through patience and prayer.",
    "Surah Al-Baqarah 2:45",
    "The first matter that the slave will be brought to account for on the Day of Judgment is the prayer.",
    "Sunan Ibn Majah 1425",
  ),
  // 36
  DailyContent(
    "وَٱللَّهُ یَعۡلَمُ وَأَنتُمۡ لَا تَعۡلَمُونَ",
    "And Allah knows, while you know not.",
    "Surah Al-Baqarah 2:216",
    "Verily, Allah does not look to your bodies nor to your faces, but He looks to your hearts.",
    "Sahih Muslim 2564",
  ),
  // 37
  DailyContent(
    "وَإِذَا سَأَلَكَ عِبَادِى عَنِّى فَإِنِّى قَرِيبٌ",
    "And when My servants ask you concerning Me — indeed I am near.",
    "Surah Al-Baqarah 2:186",
    "Supplication is itself worship.",
    "Sunan al-Tirmidhi 3372",
  ),
  // 38
  DailyContent(
    "وَلَا تَهِنُوا۟ وَلَا تَحْزَنُوا۟ وَأَنتُمُ ٱلْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ",
    "So do not weaken and do not grieve, and you will be superior if you are believers.",
    "Surah Al-Imran 3:139",
    "The strong believer is better and more beloved to Allah than the weak believer, though there is good in both.",
    "Sahih Muslim 2664",
  ),
  // 39
  DailyContent(
    "يَـٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱصْبِرُوا۟ وَصَابِرُوا۟ وَرَابِطُوا۟ وَٱتَّقُوا۟ ٱللَّهَ لَعَلَّكُمْ تُفْلِحُونَ",
    "O you who have believed, persevere and endure and remain stationed, and fear Allah that you may be successful.",
    "Surah Al-Imran 3:200",
    "Whoever remains patient, Allah will make him patient. Nobody can be given a better and more abundant gift than patience.",
    "Sahih al-Bukhari 1469",
  ),
  // 40
  DailyContent(
    "وَٱصْبِرُوٓا۟ ۚ إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ",
    "And be patient. Indeed, Allah is with the patient.",
    "Surah Al-Anfal 8:46",
    "The believers, in their mutual love, mercy and compassion, are like one body: when one limb aches, the whole body responds with sleeplessness and fever.",
    "Sahih Muslim 2586",
  ),
  // 41
  DailyContent(
    "سَلَـٰمٌ عَلَيْكُم بِمَا صَبَرْتُمْ ۚ فَنِعْمَ عُقْبَى ٱلدَّارِ",
    "Peace be upon you for what you patiently endured. And excellent is the final home.",
    "Surah Ar-Ra'd 13:24",
    "How wonderful is the affair of the believer — all of it is good. If something good happens he is grateful, and that is good for him; if hardship befalls him he is patient, and that is good for him.",
    "Sahih Muslim 2999",
  ),
  // 42
  DailyContent(
    "مَنْ عَمِلَ صَـٰلِحًا مِّن ذَكَرٍ أَوْ أُنثَىٰ وَهُوَ مُؤْمِنٌ فَلَنُحْيِيَنَّهُۥ حَيَوٰةً طَيِّبَةً",
    "Whoever does righteousness, whether male or female, while being a believer — We will surely cause him to live a good life.",
    "Surah An-Nahl 16:97",
    "Richness is not having many possessions; true richness is the richness of the soul.",
    "Sahih al-Bukhari 6446",
  ),
  // 43
  DailyContent(
    "إِنَّ ٱللَّهَ مَعَ ٱلَّذِينَ ٱتَّقَوا۟ وَّٱلَّذِينَ هُم مُّحْسِنُونَ",
    "Indeed, Allah is with those who fear Him and those who are doers of good.",
    "Surah An-Nahl 16:128",
    "Allah has prescribed excellence in all things.",
    "Sahih Muslim 1955",
  ),
  // 44
  DailyContent(
    "وَقَضَىٰ رَبُّكَ أَلَّا تَعْبُدُوٓا۟ إِلَّآ إِيَّاهُ وَبِٱلْوَٰلِدَيْنِ إِحْسَـٰنًا",
    "And your Lord has decreed that you worship none but Him, and to parents, good treatment.",
    "Surah Al-Isra 17:23",
    "A man asked who was most deserving of his good company. He said: Your mother — three times — then your father.",
    "Sahih al-Bukhari 5971",
  ),
  // 45
  DailyContent(
    "وَعِبَادُ ٱلرَّحْمَـٰنِ ٱلَّذِينَ يَمْشُونَ عَلَى ٱلْأَرْضِ هَوْنًا وَإِذَا خَاطَبَهُمُ ٱلْجَـٰهِلُونَ قَالُوا۟ سَلَـٰمًا",
    "And the servants of the Most Merciful are those who walk upon the earth easily, and when the ignorant address them harshly, they say words of peace.",
    "Surah Al-Furqan 25:63",
    "No one who has an atom's weight of arrogance in his heart will enter Paradise.",
    "Sahih Muslim 91",
  ),
  // 46
  DailyContent(
    "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَٰجِنَا وَذُرِّيَّـٰتِنَا قُرَّةَ أَعْيُنٍ",
    "Our Lord, grant us from among our spouses and offspring comfort to our eyes.",
    "Surah Al-Furqan 25:74",
    "The best of you is the one who is best to his family, and I am the best of you to my family.",
    "Sunan al-Tirmidhi 3895",
  ),
  // 47
  DailyContent(
    "يَـٰبُنَىَّ أَقِمِ ٱلصَّلَوٰةَ وَأْمُرْ بِٱلْمَعْرُوفِ وَٱنْهَ عَنِ ٱلْمُنكَرِ وَٱصْبِرْ عَلَىٰ مَآ أَصَابَكَ",
    "O my son, establish prayer, enjoin what is right, forbid what is wrong, and be patient over what befalls you.",
    "Surah Luqman 31:17",
    "Whoever among you sees an evil, let him change it with his hand; if he cannot, then with his tongue; if he cannot, then with his heart — and that is the weakest of faith.",
    "Sahih Muslim 49",
  ),
  // 48
  DailyContent(
    "لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ ۚ إِنَّ ٱللَّهَ يَغْفِرُ ٱلذُّنُوبَ جَمِيعًا",
    "Do not despair of the mercy of Allah. Indeed, Allah forgives all sins.",
    "Surah Az-Zumar 39:53",
    "Allah is more pleased with the repentance of His servant than one of you would be who found his lost camel in the desert.",
    "Sahih al-Bukhari 6309",
  ),
  // 49
  DailyContent(
    "وَلَا تَسْتَوِى ٱلْحَسَنَةُ وَلَا ٱلسَّيِّئَةُ ۚ ٱدْفَعْ بِٱلَّتِى هِىَ أَحْسَنُ",
    "Good and evil are not equal. Repel evil by that which is better.",
    "Surah Fussilat 41:34",
    "Fear Allah wherever you are, follow a bad deed with a good one and it will erase it, and treat people with good character.",
    "Sunan al-Tirmidhi 1987",
  ),
  // 50
  DailyContent(
    "وَلَمَن صَبَرَ وَغَفَرَ إِنَّ ذَٰلِكَ لَمِنْ عَزْمِ ٱلْأُمُورِ",
    "And whoever is patient and forgives — indeed, that is of the matters requiring determination.",
    "Surah Ash-Shura 42:43",
    "Charity does not decrease wealth; Allah increases the honour of the one who forgives; and no one humbles himself for Allah except that Allah raises him.",
    "Sahih Muslim 2588",
  ),
  // 51
  DailyContent(
    "إِنَّ أَكْرَمَكُمْ عِندَ ٱللَّهِ أَتْقَىٰكُمْ",
    "Indeed, the most noble of you in the sight of Allah is the most righteous of you.",
    "Surah Al-Hujurat 49:13",
    "There is no superiority of an Arab over a non-Arab, nor of a non-Arab over an Arab, except by piety.",
    "Musnad Ahmad 23489",
  ),
  // 52
  DailyContent(
    "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ ٱلْوَرِيدِ",
    "And We are closer to him than his jugular vein.",
    "Surah Qaf 50:16",
    "Actions are but by intentions, and every person will have only what he intended.",
    "Sahih al-Bukhari 1",
  ),
  // 53
  DailyContent(
    "مَآ أَصَابَ مِن مُّصِيبَةٍ إِلَّا بِإِذْنِ ٱللَّهِ",
    "No disaster strikes except by permission of Allah.",
    "Surah At-Taghabun 64:11",
    "Know that what has befallen you was never going to miss you, and what missed you was never going to befall you.",
    "Sunan Abi Dawud 4699",
  ),
  // 54
  DailyContent(
    "سَيَجْعَلُ ٱللَّهُ بَعْدَ عُسْرٍ يُسْرًا",
    "Allah will bring about, after hardship, ease.",
    "Surah At-Talaq 65:7",
    "Know that victory comes with patience, relief with affliction, and ease with hardship.",
    "Sunan al-Tirmidhi 2516",
  ),
  // 55
  DailyContent(
    "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰٓ",
    "And your Lord is going to give you, and you will be satisfied.",
    "Surah Ad-Duha 93:5",
    "Whoever is not grateful to people is not grateful to Allah.",
    "Sunan Abi Dawud 4811",
  ),
  // 56
  DailyContent(
    "فَمَن يَعْمَلْ مِثْقَالَ ذَرَّةٍ خَيْرًا يَرَهُۥ",
    "So whoever does an atom's weight of good will see it.",
    "Surah Az-Zalzalah 99:7",
    "Do not belittle any good deed, even meeting your brother with a cheerful face.",
    "Sahih Muslim 2626",
  ),
];
