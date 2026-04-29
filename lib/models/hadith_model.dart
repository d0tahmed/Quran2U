// lib/models/hadith_model.dart

/// Which Hadith collection the user is reading.
enum HadithCollection {
  bukhari,
  muslim,
  abuDawud,
  tirmidhi,
  nasai,
  ibnMajah;

  String get displayName {
    switch (this) {
      case HadithCollection.bukhari:
        return 'Sahih al Bukhari';
      case HadithCollection.muslim:
        return 'Sahih Muslim';
      case HadithCollection.abuDawud:
        return 'Sunan Abu Dawood';
      case HadithCollection.tirmidhi:
        return "Jami' at-Tirmidhi";
      case HadithCollection.nasai:
        return "Sunan an-Nasa'i";
      case HadithCollection.ibnMajah:
        return 'Sunan Ibn Majah';
    }
  }

  String get subtitle {
    switch (this) {
      case HadithCollection.bukhari:
        return 'Most authentic collection';
      case HadithCollection.muslim:
        return 'Second most authentic collection';
      case HadithCollection.abuDawud:
        return 'Sunan — laws & practices';
      case HadithCollection.tirmidhi:
        return 'Comprehensive sunan collection';
      case HadithCollection.nasai:
        return 'Strictly verified sunan';
      case HadithCollection.ibnMajah:
        return 'Widely used sunan collection';
    }
  }

  /// CDN URL for the minified JSON of this collection in [language].
  /// Using .min.json wherever available halves the download size.
  String cdnUrl(HadithLanguage language) {
    const base = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';
    switch (this) {
      case HadithCollection.bukhari:
        switch (language) {
          case HadithLanguage.english:
            return '$base/eng-bukhari.min.json';
          case HadithLanguage.urdu:
            return '$base/urd-bukhari.min.json';
          case HadithLanguage.arabic:
            return '$base/ara-bukhari.min.json';
        }
      case HadithCollection.muslim:
        switch (language) {
          case HadithLanguage.english:
            return '$base/eng-muslim.min.json';
          case HadithLanguage.urdu:
            return '$base/urd-muslim.min.json';
          case HadithLanguage.arabic:
            return '$base/ara-muslim.min.json';
        }
      case HadithCollection.abuDawud:
        switch (language) {
          case HadithLanguage.english:
            return '$base/eng-abudawud.min.json';
          case HadithLanguage.urdu:
            return '$base/urd-abudawud.min.json';
          case HadithLanguage.arabic:
            return '$base/ara-abudawud.min.json';
        }
      case HadithCollection.tirmidhi:
        switch (language) {
          case HadithLanguage.english:
            return '$base/eng-tirmidhi.min.json';
          case HadithLanguage.urdu:
            return '$base/urd-tirmidhi.min.json';
          case HadithLanguage.arabic:
            return '$base/ara-tirmidhi.min.json';
        }
      case HadithCollection.nasai:
        switch (language) {
          case HadithLanguage.english:
            return '$base/eng-nasai.min.json';
          case HadithLanguage.urdu:
            return '$base/urd-nasai.min.json';
          case HadithLanguage.arabic:
            return '$base/ara-nasai.min.json';
        }
      case HadithCollection.ibnMajah:
        switch (language) {
          case HadithLanguage.english:
            return '$base/eng-ibnmajah.min.json';
          case HadithLanguage.urdu:
            return '$base/urd-ibnmajah.min.json';
          case HadithLanguage.arabic:
            return '$base/ara-ibnmajah.min.json';
        }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single Hadith entry from the CDN JSON.
class HadithEntry {
  final int    hadithNumber;
  final int    arabicNumber;
  final String text;
  final int    bookNumber;
  final int    hadithInBook;

  const HadithEntry({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.text,
    required this.bookNumber,
    required this.hadithInBook,
  });

  factory HadithEntry.fromJson(Map<String, dynamic> json) {
    final ref = json['reference'] as Map<String, dynamic>? ?? {};

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return double.tryParse(val)?.toInt() ?? 0;
      return 0;
    }

    return HadithEntry(
      hadithNumber: parseInt(json['hadithnumber']),
      arabicNumber: parseInt(json['arabicnumber']),
      text:         (json['text'] as String?) ?? '',
      bookNumber:   parseInt(ref['book']),
      hadithInBook: parseInt(ref['hadith']),
    );
  }

  factory HadithEntry.fromDb(Map<String, dynamic> row, HadithLanguage lang) {
    final String textCol;
    switch (lang) {
      case HadithLanguage.english: textCol = 'text_en'; break;
      case HadithLanguage.urdu:    textCol = 'text_ur'; break;
      case HadithLanguage.arabic:  textCol = 'text_ar'; break;
    }
    return HadithEntry(
      hadithNumber: row['hadith_number'] as int? ?? 0,
      arabicNumber: row['arabic_number'] as int? ?? 0,
      text:         row[textCol] as String? ?? '',
      bookNumber:   row['book_reference'] as int? ?? 0,
      hadithInBook: row['hadith_reference'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Represents one numbered section/book within a collection.
class HadithSection {
  final int    number;
  final String name;
  final int    firstHadith;
  final int    lastHadith;

  const HadithSection({
    required this.number,
    required this.name,
    required this.firstHadith,
    required this.lastHadith,
  });

  factory HadithSection.fromDb(Map<String, dynamic> row, HadithLanguage lang) {
    final String nameCol;
    switch (lang) {
      case HadithLanguage.english: nameCol = 'name_en'; break;
      case HadithLanguage.urdu:    nameCol = 'name_ur'; break;
      case HadithLanguage.arabic:  nameCol = 'name_ar'; break;
    }
    
    // Fallback to english name if the requested lang is empty
    String name = row[nameCol] as String? ?? '';
    if (name.trim().isEmpty) {
      name = row['name_en'] as String? ?? '';
    }

    return HadithSection(
      number:      row['section_number'] as int? ?? 0,
      name:        name,
      firstHadith: row['first_hadith'] as int? ?? 0,
      lastHadith:  row['last_hadith'] as int? ?? 0,
    );
  }

  int get hadithCount => (lastHadith - firstHadith + 1).clamp(0, 99999);
}

// ─────────────────────────────────────────────────────────────────────────────

/// The full parsed Hadith book (one language edition).
class HadithBook {
  final String             name;
  final HadithCollection   collection;
  final List<HadithSection> sections;
  final List<HadithEntry>   hadiths;

  const HadithBook({
    required this.name,
    required this.collection,
    required this.sections,
    required this.hadiths,
  });

  /// Returns all hadiths belonging to [section].
  List<HadithEntry> hadithsForSection(HadithSection section) {
    return hadiths
        .where((h) =>
            h.hadithNumber >= section.firstHadith &&
            h.hadithNumber <= section.lastHadith)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Family key: (collection, language) pair — used as the provider family param.
/// Dart Records give structural equality for free (no need for manual == / hashCode).
typedef HadithBookRequest = ({HadithCollection collection, HadithLanguage language});

// ─────────────────────────────────────────────────────────────────────────────

enum HadithLanguage { english, urdu, arabic }

extension HadithLanguageX on HadithLanguage {
  String get label {
    switch (this) {
      case HadithLanguage.english:
        return 'English';
      case HadithLanguage.urdu:
        return 'اردو';
      case HadithLanguage.arabic:
        return 'عربي';
    }
  }

  bool get isRtl => this == HadithLanguage.urdu || this == HadithLanguage.arabic;
}
