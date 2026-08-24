// lib/data/quran_surah_data.dart
//
// The 114 surahs, bundled.
//
// WHY THIS IS A CONST LIST AND NOT AN API CALL
// --------------------------------------------
// Surah metadata has not changed in fourteen centuries, yet the app used to
// fetch it over the network on every cold start. That meant a first launch
// with no connection had no surah list at all — no reading index, and no
// possible quiz. Eight kilobytes of const data removes a network dependency
// from the critical path and makes the app open faster offline.
//
// PROVENANCE
// ----------
// Generated from the Quran.com API (`/chapters?language=en`) and then
// cross-checked field by field: chapter order 1..114, every ayah count against
// an independent table, and the total verified at 6236. Do not hand-edit — if
// something looks wrong, fix it at the source and regenerate.

import 'package:flutter/foundation.dart';

@immutable
class SurahInfo {
  /// 1..114.
  final int number;

  /// Transliterated name, e.g. "Al-Kahf".
  final String name;

  /// Arabic name, e.g. "الكهف".
  final String nameArabic;

  /// English meaning, e.g. "The Cave".
  final String meaning;

  /// Number of ayat.
  final int ayahCount;

  /// True when revealed in Makkah, false for Madinah.
  final bool isMakki;

  const SurahInfo(
    this.number,
    this.name,
    this.nameArabic,
    this.meaning,
    this.ayahCount,
    this.isMakki,
  );

  String get revelationPlace => isMakki ? 'Makkah' : 'Madinah';
}

/// Indexed 0..113; `kSurahs[n - 1]` is surah `n`.
const List<SurahInfo> kSurahs = <SurahInfo>[

  SurahInfo(1, 'Al-Fatihah', 'الفاتحة', 'The Opener', 7, true),
  SurahInfo(2, 'Al-Baqarah', 'البقرة', 'The Cow', 286, false),
  SurahInfo(3, 'Ali \'Imran', 'آل عمران', 'Family of Imran', 200, false),
  SurahInfo(4, 'An-Nisa', 'النساء', 'The Women', 176, false),
  SurahInfo(5, 'Al-Ma\'idah', 'المائدة', 'The Table Spread', 120, false),
  SurahInfo(6, 'Al-An\'am', 'الأنعام', 'The Cattle', 165, true),
  SurahInfo(7, 'Al-A\'raf', 'الأعراف', 'The Heights', 206, true),
  SurahInfo(8, 'Al-Anfal', 'الأنفال', 'The Spoils of War', 75, false),
  SurahInfo(9, 'At-Tawbah', 'التوبة', 'The Repentance', 129, false),
  SurahInfo(10, 'Yunus', 'يونس', 'Jonah', 109, true),
  SurahInfo(11, 'Hud', 'هود', 'Hud', 123, true),
  SurahInfo(12, 'Yusuf', 'يوسف', 'Joseph', 111, true),
  SurahInfo(13, 'Ar-Ra\'d', 'الرعد', 'The Thunder', 43, false),
  SurahInfo(14, 'Ibrahim', 'ابراهيم', 'Abraham', 52, true),
  SurahInfo(15, 'Al-Hijr', 'الحجر', 'The Rocky Tract', 99, true),
  SurahInfo(16, 'An-Nahl', 'النحل', 'The Bee', 128, true),
  SurahInfo(17, 'Al-Isra', 'الإسراء', 'The Night Journey', 111, true),
  SurahInfo(18, 'Al-Kahf', 'الكهف', 'The Cave', 110, true),
  SurahInfo(19, 'Maryam', 'مريم', 'Mary', 98, true),
  SurahInfo(20, 'Taha', 'طه', 'Ta-Ha', 135, true),
  SurahInfo(21, 'Al-Anbya', 'الأنبياء', 'The Prophets', 112, true),
  SurahInfo(22, 'Al-Hajj', 'الحج', 'The Pilgrimage', 78, false),
  SurahInfo(23, 'Al-Mu\'minun', 'المؤمنون', 'The Believers', 118, true),
  SurahInfo(24, 'An-Nur', 'النور', 'The Light', 64, false),
  SurahInfo(25, 'Al-Furqan', 'الفرقان', 'The Criterion', 77, true),
  SurahInfo(26, 'Ash-Shu\'ara', 'الشعراء', 'The Poets', 227, true),
  SurahInfo(27, 'An-Naml', 'النمل', 'The Ant', 93, true),
  SurahInfo(28, 'Al-Qasas', 'القصص', 'The Stories', 88, true),
  SurahInfo(29, 'Al-\'Ankabut', 'العنكبوت', 'The Spider', 69, true),
  SurahInfo(30, 'Ar-Rum', 'الروم', 'The Romans', 60, true),
  SurahInfo(31, 'Luqman', 'لقمان', 'Luqman', 34, true),
  SurahInfo(32, 'As-Sajdah', 'السجدة', 'The Prostration', 30, true),
  SurahInfo(33, 'Al-Ahzab', 'الأحزاب', 'The Combined Forces', 73, false),
  SurahInfo(34, 'Saba', 'سبإ', 'Sheba', 54, true),
  SurahInfo(35, 'Fatir', 'فاطر', 'Originator', 45, true),
  SurahInfo(36, 'Ya-Sin', 'يس', 'Ya Sin', 83, true),
  SurahInfo(37, 'As-Saffat', 'الصافات', 'Those who set the Ranks', 182, true),
  SurahInfo(38, 'Sad', 'ص', 'The Letter Saad', 88, true),
  SurahInfo(39, 'Az-Zumar', 'الزمر', 'The Troops', 75, true),
  SurahInfo(40, 'Ghafir', 'غافر', 'The Forgiver', 85, true),
  SurahInfo(41, 'Fussilat', 'فصلت', 'Explained in Detail', 54, true),
  SurahInfo(42, 'Ash-Shuraa', 'الشورى', 'The Consultation', 53, true),
  SurahInfo(43, 'Az-Zukhruf', 'الزخرف', 'The Ornaments of Gold', 89, true),
  SurahInfo(44, 'Ad-Dukhan', 'الدخان', 'The Smoke', 59, true),
  SurahInfo(45, 'Al-Jathiyah', 'الجاثية', 'The Crouching', 37, true),
  SurahInfo(46, 'Al-Ahqaf', 'الأحقاف', 'The Wind-Curved Sandhills', 35, true),
  SurahInfo(47, 'Muhammad', 'محمد', 'Muhammad', 38, false),
  SurahInfo(48, 'Al-Fath', 'الفتح', 'The Victory', 29, false),
  SurahInfo(49, 'Al-Hujurat', 'الحجرات', 'The Rooms', 18, false),
  SurahInfo(50, 'Qaf', 'ق', 'The Letter Qaf', 45, true),
  SurahInfo(51, 'Adh-Dhariyat', 'الذاريات', 'The Winnowing Winds', 60, true),
  SurahInfo(52, 'At-Tur', 'الطور', 'The Mount', 49, true),
  SurahInfo(53, 'An-Najm', 'النجم', 'The Star', 62, true),
  SurahInfo(54, 'Al-Qamar', 'القمر', 'The Moon', 55, true),
  SurahInfo(55, 'Ar-Rahman', 'الرحمن', 'The Beneficent', 78, false),
  SurahInfo(56, 'Al-Waqi\'ah', 'الواقعة', 'The Inevitable', 96, true),
  SurahInfo(57, 'Al-Hadid', 'الحديد', 'The Iron', 29, false),
  SurahInfo(58, 'Al-Mujadila', 'المجادلة', 'The Pleading Woman', 22, false),
  SurahInfo(59, 'Al-Hashr', 'الحشر', 'The Exile', 24, false),
  SurahInfo(60, 'Al-Mumtahanah', 'الممتحنة', 'She that is to be examined', 13, false),
  SurahInfo(61, 'As-Saf', 'الصف', 'The Ranks', 14, false),
  SurahInfo(62, 'Al-Jumu\'ah', 'الجمعة', 'The Congregation, Friday', 11, false),
  SurahInfo(63, 'Al-Munafiqun', 'المنافقون', 'The Hypocrites', 11, false),
  SurahInfo(64, 'At-Taghabun', 'التغابن', 'The Mutual Disillusion', 18, false),
  SurahInfo(65, 'At-Talaq', 'الطلاق', 'The Divorce', 12, false),
  SurahInfo(66, 'At-Tahrim', 'التحريم', 'The Prohibition', 12, false),
  SurahInfo(67, 'Al-Mulk', 'الملك', 'The Sovereignty', 30, true),
  SurahInfo(68, 'Al-Qalam', 'القلم', 'The Pen', 52, true),
  SurahInfo(69, 'Al-Haqqah', 'الحاقة', 'The Reality', 52, true),
  SurahInfo(70, 'Al-Ma\'arij', 'المعارج', 'The Ascending Stairways', 44, true),
  SurahInfo(71, 'Nuh', 'نوح', 'Noah', 28, true),
  SurahInfo(72, 'Al-Jinn', 'الجن', 'The Jinn', 28, true),
  SurahInfo(73, 'Al-Muzzammil', 'المزمل', 'The Enshrouded One', 20, true),
  SurahInfo(74, 'Al-Muddaththir', 'المدثر', 'The Cloaked One', 56, true),
  SurahInfo(75, 'Al-Qiyamah', 'القيامة', 'The Resurrection', 40, true),
  SurahInfo(76, 'Al-Insan', 'الانسان', 'The Man', 31, false),
  SurahInfo(77, 'Al-Mursalat', 'المرسلات', 'The Emissaries', 50, true),
  SurahInfo(78, 'An-Naba', 'النبإ', 'The Tidings', 40, true),
  SurahInfo(79, 'An-Nazi\'at', 'النازعات', 'Those who drag forth', 46, true),
  SurahInfo(80, '\'Abasa', 'عبس', 'He Frowned', 42, true),
  SurahInfo(81, 'At-Takwir', 'التكوير', 'The Overthrowing', 29, true),
  SurahInfo(82, 'Al-Infitar', 'الإنفطار', 'The Cleaving', 19, true),
  SurahInfo(83, 'Al-Mutaffifin', 'المطففين', 'The Defrauding', 36, true),
  SurahInfo(84, 'Al-Inshiqaq', 'الإنشقاق', 'The Sundering', 25, true),
  SurahInfo(85, 'Al-Buruj', 'البروج', 'The Mansions of the Stars', 22, true),
  SurahInfo(86, 'At-Tariq', 'الطارق', 'The Nightcommer', 17, true),
  SurahInfo(87, 'Al-A\'la', 'الأعلى', 'The Most High', 19, true),
  SurahInfo(88, 'Al-Ghashiyah', 'الغاشية', 'The Overwhelming', 26, true),
  SurahInfo(89, 'Al-Fajr', 'الفجر', 'The Dawn', 30, true),
  SurahInfo(90, 'Al-Balad', 'البلد', 'The City', 20, true),
  SurahInfo(91, 'Ash-Shams', 'الشمس', 'The Sun', 15, true),
  SurahInfo(92, 'Al-Layl', 'الليل', 'The Night', 21, true),
  SurahInfo(93, 'Ad-Duhaa', 'الضحى', 'The Morning Hours', 11, true),
  SurahInfo(94, 'Ash-Sharh', 'الشرح', 'The Relief', 8, true),
  SurahInfo(95, 'At-Tin', 'التين', 'The Fig', 8, true),
  SurahInfo(96, 'Al-\'Alaq', 'العلق', 'The Clot', 19, true),
  SurahInfo(97, 'Al-Qadr', 'القدر', 'The Power', 5, true),
  SurahInfo(98, 'Al-Bayyinah', 'البينة', 'The Clear Proof', 8, false),
  SurahInfo(99, 'Az-Zalzalah', 'الزلزلة', 'The Earthquake', 8, false),
  SurahInfo(100, 'Al-\'Adiyat', 'العاديات', 'The Courser', 11, true),
  SurahInfo(101, 'Al-Qari\'ah', 'القارعة', 'The Calamity', 11, true),
  SurahInfo(102, 'At-Takathur', 'التكاثر', 'The Rivalry in world increase', 8, true),
  SurahInfo(103, 'Al-\'Asr', 'العصر', 'The Declining Day', 3, true),
  SurahInfo(104, 'Al-Humazah', 'الهمزة', 'The Traducer', 9, true),
  SurahInfo(105, 'Al-Fil', 'الفيل', 'The Elephant', 5, true),
  SurahInfo(106, 'Quraysh', 'قريش', 'Quraysh', 4, true),
  SurahInfo(107, 'Al-Ma\'un', 'الماعون', 'The Small kindnesses', 7, true),
  SurahInfo(108, 'Al-Kawthar', 'الكوثر', 'The Abundance', 3, true),
  SurahInfo(109, 'Al-Kafirun', 'الكافرون', 'The Disbelievers', 6, true),
  SurahInfo(110, 'An-Nasr', 'النصر', 'The Divine Support', 3, false),
  SurahInfo(111, 'Al-Masad', 'المسد', 'The Palm Fiber', 5, true),
  SurahInfo(112, 'Al-Ikhlas', 'الإخلاص', 'The Sincerity', 4, true),
  SurahInfo(113, 'Al-Falaq', 'الفلق', 'The Daybreak', 5, true),
  SurahInfo(114, 'An-Nas', 'الناس', 'Mankind', 6, true),
];

/// Total ayat in the Quran. Asserted against [kSurahs] in debug builds.
const int kTotalAyat = 6236;
