// lib/services/hijri_date.dart
//
// Dependency-free Hijri (Islamic) calendar.
//
// Uses the arithmetic/tabular Islamic calendar (the "Kuwaiti algorithm"),
// which tracks Umm al-Qura to within ±1 day. Because moon sighting differs by
// region anyway, [HijriDate.adjustment] lets the user nudge the result by
// -2..+2 days — the same control every major Islamic app ships.

class HijriDate {
  final int year;
  final int month; // 1..12
  final int day; // 1..30

  const HijriDate(this.year, this.month, this.day);

  /// Global day offset applied to every conversion. Persisted by
  /// [hijriAdjustmentProvider]; defaults to 0.
  static int adjustment = 0;

  static const List<String> monthNamesEn = <String>[
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhul Qadah',
    'Dhul Hijjah',
  ];

  static const List<String> monthNamesAr = <String>[
    'مُحَرَّم',
    'صَفَر',
    'رَبيع الأوَّل',
    'رَبيع الآخِر',
    'جُمادى الأولى',
    'جُمادى الآخِرة',
    'رَجَب',
    'شَعبان',
    'رَمَضان',
    'شَوّال',
    'ذو القَعدة',
    'ذو الحِجّة',
  ];

  /// Gregorian → Julian Day Number.
  static int _gregorianToJdn(int year, int month, int day) {
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;
  }

  /// Converts a Gregorian [date] to its Hijri equivalent.
  factory HijriDate.fromDate(DateTime date) {
    var jdn = _gregorianToJdn(date.year, date.month, date.day) + adjustment;

    var l = jdn - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j = (((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor()) +
        ((l / 5670).floor() * ((43 * l) / 15238).floor());
    l = l -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final month = ((24 * l) / 709).floor();
    final day = l - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;

    return HijriDate(year, month.clamp(1, 12), day);
  }

  factory HijriDate.today() => HijriDate.fromDate(DateTime.now());

  String get monthNameEn => monthNamesEn[(month - 1).clamp(0, 11)];
  String get monthNameAr => monthNamesAr[(month - 1).clamp(0, 11)];

  /// "5 Rabi al-Awwal 1448 AH"
  String get formattedEn => '$day $monthNameEn $year AH';

  /// "٥ رَبيع الأوَّل ١٤٤٨ هـ"
  String get formattedAr =>
      '${toArabicNumerals('$day')} $monthNameAr ${toArabicNumerals('$year')} هـ';

  /// Short form used on the home masthead: "5 Rabi al-Awwal 1448"
  String get short => '$day $monthNameEn $year';

  /// True during Ramadan — lets the UI mark the month.
  bool get isRamadan => month == 9;

  static const List<String> _arabicDigits = <String>[
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
  ];

  static String toArabicNumerals(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final digit = int.tryParse(ch);
      buffer.write(digit == null ? ch : _arabicDigits[digit]);
    }
    return buffer.toString();
  }

  @override
  String toString() => formattedEn;
}
