// lib/providers/reading_progress_provider.dart
//
// "Continue reading" state — the last place the user was in the mushaf.
// Persisted to SharedPreferences so it survives restarts.
//
// Two things can set it:
//   • turning a page in the Read Quran mushaf  → page-based position
//   • bookmarking an ayah in the surah reader  → ayah-based position
// Both are stored together, so the home card can always offer an exact resume.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Total pages in the standard Madani mushaf.
const int kMushafPageCount = 604;

@immutable
class ReadingProgress {
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int ayahNumber;
  final int ayahCount;

  /// Mushaf page 1..604. 0 when the position came from the surah reader only.
  final int page;

  /// Which script tab the user was reading: 0 Uthmani, 1 Indo-Pak, 2 Tajweed.
  final int scriptTab;

  final DateTime updatedAt;

  const ReadingProgress({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.ayahNumber,
    required this.ayahCount,
    required this.updatedAt,
    this.page = 0,
    this.scriptTab = 0,
  });

  bool get hasPage => page > 0;
  bool get hasSurah => surahNumber > 0 && ayahCount > 0;

  /// Progress through the whole mushaf, when reading by page.
  double get pageFraction =>
      hasPage ? (page / kMushafPageCount).clamp(0.0, 1.0) : 0.0;

  /// Progress through the current surah, when reading by ayah.
  double get surahFraction =>
      hasSurah ? (ayahNumber / ayahCount).clamp(0.0, 1.0) : 0.0;

  /// The bar the home card draws — page progress wins because it is the
  /// position the reader actually resumes at.
  double get fraction => hasPage ? pageFraction : surahFraction;

  int get percent => (fraction * 100).round();

  /// One line describing exactly where the reader is.
  String get positionLabel {
    if (hasPage && hasSurah) {
      return 'Page $page of $kMushafPageCount · Ayah $ayahNumber';
    }
    if (hasPage) return 'Page $page of $kMushafPageCount';
    if (hasSurah) return 'Ayah $ayahNumber of $ayahCount';
    return 'Tap to start reading';
  }

  ReadingProgress copyWith({
    int? surahNumber,
    String? surahName,
    String? surahNameArabic,
    int? ayahNumber,
    int? ayahCount,
    int? page,
    int? scriptTab,
    DateTime? updatedAt,
  }) =>
      ReadingProgress(
        surahNumber: surahNumber ?? this.surahNumber,
        surahName: surahName ?? this.surahName,
        surahNameArabic: surahNameArabic ?? this.surahNameArabic,
        ayahNumber: ayahNumber ?? this.ayahNumber,
        ayahCount: ayahCount ?? this.ayahCount,
        page: page ?? this.page,
        scriptTab: scriptTab ?? this.scriptTab,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        's': surahNumber,
        'n': surahName,
        'a': surahNameArabic,
        'v': ayahNumber,
        'c': ayahCount,
        'p': page,
        'k': scriptTab,
        't': updatedAt.millisecondsSinceEpoch,
      };

  static int _int(dynamic v, [int fallback = 0]) =>
      v is num ? v.toInt() : fallback;

  static ReadingProgress? fromJson(Map<String, dynamic> json) {
    final surah = _int(json['s'], -1);
    final page = _int(json['p']);
    // Nothing usable stored.
    if (surah <= 0 && page <= 0) return null;
    return ReadingProgress(
      surahNumber: surah < 0 ? 0 : surah,
      surahName: json['n']?.toString() ?? '',
      surahNameArabic: json['a']?.toString() ?? '',
      ayahNumber: _int(json['v'], 1),
      ayahCount: _int(json['c']),
      page: page,
      scriptTab: _int(json['k']).clamp(0, 2),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(_int(json['t'])),
    );
  }
}

class ReadingProgressNotifier extends StateNotifier<ReadingProgress?> {
  static const _key = 'reading_progress_v2';

  ReadingProgressNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      state = ReadingProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      // A corrupt entry simply means "no progress yet".
    }
  }

  Future<void> _save() async {
    try {
      final current = state;
      final prefs = await SharedPreferences.getInstance();
      if (current == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, jsonEncode(current.toJson()));
      }
    } catch (_) {}
  }

  /// Records a position in the surah reader.
  void recordSurah({
    required int surahNumber,
    required String surahName,
    required String surahNameArabic,
    required int ayahNumber,
    required int ayahCount,
  }) {
    final current = state;
    if (current != null &&
        current.surahNumber == surahNumber &&
        current.ayahNumber == ayahNumber &&
        !current.hasPage) {
      return; // nothing changed — skip the disk write
    }
    state = ReadingProgress(
      surahNumber: surahNumber,
      surahName: surahName,
      surahNameArabic: surahNameArabic,
      ayahNumber: ayahNumber,
      ayahCount: ayahCount,
      // Moving inside a surah invalidates any stored mushaf page.
      page: 0,
      scriptTab: current?.scriptTab ?? 0,
      updatedAt: DateTime.now(),
    );
    _save();
  }

  /// Records a position in the Read Quran mushaf.
  void recordPage({
    required int page,
    required int scriptTab,
    String surahName = '',
    String surahNameArabic = '',
    int surahNumber = 0,
  }) {
    final current = state;
    if (current != null &&
        current.page == page &&
        current.scriptTab == scriptTab) {
      return;
    }
    state = ReadingProgress(
      surahNumber: surahNumber > 0 ? surahNumber : (current?.surahNumber ?? 0),
      surahName: surahName.isNotEmpty ? surahName : (current?.surahName ?? ''),
      surahNameArabic: surahNameArabic.isNotEmpty
          ? surahNameArabic
          : (current?.surahNameArabic ?? ''),
      ayahNumber: current?.ayahNumber ?? 1,
      ayahCount: current?.ayahCount ?? 0,
      page: page.clamp(1, kMushafPageCount),
      scriptTab: scriptTab.clamp(0, 2),
      updatedAt: DateTime.now(),
    );
    _save();
  }

  void clear() {
    state = null;
    _save();
  }
}

final readingProgressProvider =
    StateNotifierProvider<ReadingProgressNotifier, ReadingProgress?>(
        (ref) => ReadingProgressNotifier());
