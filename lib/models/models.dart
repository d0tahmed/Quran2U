import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

// ============================================================================
// IMAM MODEL
// ============================================================================
@freezed
class Imam with _$Imam {
  const factory Imam({
    required int id,
    required String name,
    required String identifier, // For API calls (e.g., 'ar.abdulbasitmurattal')
    required String country,
    @Default('') String imageUrl,
  }) = _Imam;

  factory Imam.fromJson(Map<String, dynamic> json) => _$ImamFromJson(json);
}

// ============================================================================
// SURAH MODEL
// ============================================================================
@freezed
class Surah with _$Surah {
  const factory Surah({
    required int number,
    required String name,
    required String nameArabic,
    required String nameTranslation, // English meaning
    required int ayahCount,
    required String revelationType, // 'Meccan' or 'Medinan'
    @Default('') String audioUrl, // Placeholder, populated per Imam
    @Default(false) bool isBookmarked,
    @Default(false) bool isDownloaded,
    @Default('') String localPath, // Local file path if downloaded
  }) = _Surah;

  factory Surah.fromJson(Map<String, dynamic> json) => _$SurahFromJson(json);
}

// ============================================================================
// AYAH MODEL
// ============================================================================
@freezed
class Ayah with _$Ayah {
  const factory Ayah({
    required int number, // Global ayah number
    required int numberInSurah, // Ayah number within Surah
    required int surahNumber,
    required String text,
    @Default('') String translation, // Urdu translation
    @Default(0.0) double startTime, // In seconds (for Phase 2)
    @Default(0.0) double endTime,
    @Default(false) bool isBookmarked,
  }) = _Ayah;

  factory Ayah.fromJson(Map<String, dynamic> json) => _$AyahFromJson(json);
}

// ============================================================================
// BOOKMARK MODEL
// ============================================================================
@freezed
class Bookmark with _$Bookmark {
  const factory Bookmark({
    required String id, // UUID
    required int surahNumber,
    int? ayahNumber, // Null if bookmark is Surah-level
    required String title,
    required DateTime createdAt,
    @Default('') String notes,
  }) = _Bookmark;

  factory Bookmark.fromJson(Map<String, dynamic> json) =>
      _$BookmarkFromJson(json);
}

// ============================================================================
// PLAYBACK STATE MODEL
// ============================================================================
@freezed
class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    required bool isPlaying,
    required Duration currentPosition,
    required Duration totalDuration,
    @Default(1.0) double playbackRate,
    required int currentSurahNumber,
    int? currentAyahNumber, // Null for MVP
  }) = _PlaybackState;

  factory PlaybackState.fromJson(Map<String, dynamic> json) =>
      _$PlaybackStateFromJson(json);
}

// ============================================================================
// APP SETTINGS MODEL
// ============================================================================
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    required int selectedImamId,
    @Default(1.0) double playbackRate,
    @Default(true) bool autoPlayNextSurah,
    @Default(false) bool showTranslation, // Phase 2
    @Default(false) bool repeatSurah,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

// ============================================================================
// DOWNLOAD PROGRESS MODEL
// ============================================================================
@freezed
class DownloadProgress with _$DownloadProgress {
  const factory DownloadProgress({
    required int surahNumber,
    required int imamId,
    @Default(0.0) double progress, // 0.0 to 1.0
    @Default('')
    String status, // 'pending', 'downloading', 'completed', 'failed'
    @Default('') String? error,
  }) = _DownloadProgress;

  factory DownloadProgress.fromJson(Map<String, dynamic> json) =>
      _$DownloadProgressFromJson(json);
}
