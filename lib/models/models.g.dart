// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImamImpl _$$ImamImplFromJson(Map<String, dynamic> json) => _$ImamImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      identifier: json['identifier'] as String,
      country: json['country'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
    );

Map<String, dynamic> _$$ImamImplToJson(_$ImamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'identifier': instance.identifier,
      'country': instance.country,
      'imageUrl': instance.imageUrl,
    };

_$SurahImpl _$$SurahImplFromJson(Map<String, dynamic> json) => _$SurahImpl(
      number: (json['number'] as num).toInt(),
      name: json['name'] as String,
      nameArabic: json['nameArabic'] as String,
      nameTranslation: json['nameTranslation'] as String,
      ayahCount: (json['ayahCount'] as num).toInt(),
      revelationType: json['revelationType'] as String,
      audioUrl: json['audioUrl'] as String? ?? '',
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localPath: json['localPath'] as String? ?? '',
    );

Map<String, dynamic> _$$SurahImplToJson(_$SurahImpl instance) =>
    <String, dynamic>{
      'number': instance.number,
      'name': instance.name,
      'nameArabic': instance.nameArabic,
      'nameTranslation': instance.nameTranslation,
      'ayahCount': instance.ayahCount,
      'revelationType': instance.revelationType,
      'audioUrl': instance.audioUrl,
      'isBookmarked': instance.isBookmarked,
      'isDownloaded': instance.isDownloaded,
      'localPath': instance.localPath,
    };

_$AyahImpl _$$AyahImplFromJson(Map<String, dynamic> json) => _$AyahImpl(
      number: (json['number'] as num).toInt(),
      numberInSurah: (json['numberInSurah'] as num).toInt(),
      surahNumber: (json['surahNumber'] as num).toInt(),
      text: json['text'] as String,
      translation: json['translation'] as String? ?? '',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble() ?? 0.0,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );

Map<String, dynamic> _$$AyahImplToJson(_$AyahImpl instance) =>
    <String, dynamic>{
      'number': instance.number,
      'numberInSurah': instance.numberInSurah,
      'surahNumber': instance.surahNumber,
      'text': instance.text,
      'translation': instance.translation,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'isBookmarked': instance.isBookmarked,
    };

_$BookmarkImpl _$$BookmarkImplFromJson(Map<String, dynamic> json) =>
    _$BookmarkImpl(
      id: json['id'] as String,
      surahNumber: (json['surahNumber'] as num).toInt(),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt(),
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$BookmarkImplToJson(_$BookmarkImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'surahNumber': instance.surahNumber,
      'ayahNumber': instance.ayahNumber,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'notes': instance.notes,
    };

_$PlaybackStateImpl _$$PlaybackStateImplFromJson(Map<String, dynamic> json) =>
    _$PlaybackStateImpl(
      isPlaying: json['isPlaying'] as bool,
      currentPosition:
          Duration(microseconds: (json['currentPosition'] as num).toInt()),
      totalDuration:
          Duration(microseconds: (json['totalDuration'] as num).toInt()),
      playbackRate: (json['playbackRate'] as num?)?.toDouble() ?? 1.0,
      currentSurahNumber: (json['currentSurahNumber'] as num).toInt(),
      currentAyahNumber: (json['currentAyahNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$PlaybackStateImplToJson(_$PlaybackStateImpl instance) =>
    <String, dynamic>{
      'isPlaying': instance.isPlaying,
      'currentPosition': instance.currentPosition.inMicroseconds,
      'totalDuration': instance.totalDuration.inMicroseconds,
      'playbackRate': instance.playbackRate,
      'currentSurahNumber': instance.currentSurahNumber,
      'currentAyahNumber': instance.currentAyahNumber,
    };

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      selectedImamId: (json['selectedImamId'] as num).toInt(),
      playbackRate: (json['playbackRate'] as num?)?.toDouble() ?? 1.0,
      autoPlayNextSurah: json['autoPlayNextSurah'] as bool? ?? true,
      showTranslation: json['showTranslation'] as bool? ?? false,
      repeatSurah: json['repeatSurah'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'selectedImamId': instance.selectedImamId,
      'playbackRate': instance.playbackRate,
      'autoPlayNextSurah': instance.autoPlayNextSurah,
      'showTranslation': instance.showTranslation,
      'repeatSurah': instance.repeatSurah,
    };

_$DownloadProgressImpl _$$DownloadProgressImplFromJson(
        Map<String, dynamic> json) =>
    _$DownloadProgressImpl(
      surahNumber: (json['surahNumber'] as num).toInt(),
      imamId: (json['imamId'] as num).toInt(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$$DownloadProgressImplToJson(
        _$DownloadProgressImpl instance) =>
    <String, dynamic>{
      'surahNumber': instance.surahNumber,
      'imamId': instance.imamId,
      'progress': instance.progress,
      'status': instance.status,
      'error': instance.error,
    };
