// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Imam _$ImamFromJson(Map<String, dynamic> json) {
  return _Imam.fromJson(json);
}

/// @nodoc
mixin _$Imam {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get identifier =>
      throw _privateConstructorUsedError; // For API calls (e.g., 'ar.abdulbasitmurattal')
  String get country => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ImamCopyWith<Imam> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImamCopyWith<$Res> {
  factory $ImamCopyWith(Imam value, $Res Function(Imam) then) =
      _$ImamCopyWithImpl<$Res, Imam>;
  @useResult
  $Res call(
      {int id,
      String name,
      String identifier,
      String country,
      String imageUrl});
}

/// @nodoc
class _$ImamCopyWithImpl<$Res, $Val extends Imam>
    implements $ImamCopyWith<$Res> {
  _$ImamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? identifier = null,
    Object? country = null,
    Object? imageUrl = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImamImplCopyWith<$Res> implements $ImamCopyWith<$Res> {
  factory _$$ImamImplCopyWith(
          _$ImamImpl value, $Res Function(_$ImamImpl) then) =
      __$$ImamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String identifier,
      String country,
      String imageUrl});
}

/// @nodoc
class __$$ImamImplCopyWithImpl<$Res>
    extends _$ImamCopyWithImpl<$Res, _$ImamImpl>
    implements _$$ImamImplCopyWith<$Res> {
  __$$ImamImplCopyWithImpl(_$ImamImpl _value, $Res Function(_$ImamImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? identifier = null,
    Object? country = null,
    Object? imageUrl = null,
  }) {
    return _then(_$ImamImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      identifier: null == identifier
          ? _value.identifier
          : identifier // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImamImpl implements _Imam {
  const _$ImamImpl(
      {required this.id,
      required this.name,
      required this.identifier,
      required this.country,
      this.imageUrl = ''});

  factory _$ImamImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImamImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String identifier;
// For API calls (e.g., 'ar.abdulbasitmurattal')
  @override
  final String country;
  @override
  @JsonKey()
  final String imageUrl;

  @override
  String toString() {
    return 'Imam(id: $id, name: $name, identifier: $identifier, country: $country, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.identifier, identifier) ||
                other.identifier == identifier) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, identifier, country, imageUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImamImplCopyWith<_$ImamImpl> get copyWith =>
      __$$ImamImplCopyWithImpl<_$ImamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImamImplToJson(
      this,
    );
  }
}

abstract class _Imam implements Imam {
  const factory _Imam(
      {required final int id,
      required final String name,
      required final String identifier,
      required final String country,
      final String imageUrl}) = _$ImamImpl;

  factory _Imam.fromJson(Map<String, dynamic> json) = _$ImamImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get identifier;
  @override // For API calls (e.g., 'ar.abdulbasitmurattal')
  String get country;
  @override
  String get imageUrl;
  @override
  @JsonKey(ignore: true)
  _$$ImamImplCopyWith<_$ImamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Surah _$SurahFromJson(Map<String, dynamic> json) {
  return _Surah.fromJson(json);
}

/// @nodoc
mixin _$Surah {
  int get number => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get nameArabic => throw _privateConstructorUsedError;
  String get nameTranslation =>
      throw _privateConstructorUsedError; // English meaning
  int get ayahCount => throw _privateConstructorUsedError;
  String get revelationType =>
      throw _privateConstructorUsedError; // 'Meccan' or 'Medinan'
  String get audioUrl =>
      throw _privateConstructorUsedError; // Placeholder, populated per Imam
  bool get isBookmarked => throw _privateConstructorUsedError;
  bool get isDownloaded => throw _privateConstructorUsedError;
  String get localPath => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SurahCopyWith<Surah> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SurahCopyWith<$Res> {
  factory $SurahCopyWith(Surah value, $Res Function(Surah) then) =
      _$SurahCopyWithImpl<$Res, Surah>;
  @useResult
  $Res call(
      {int number,
      String name,
      String nameArabic,
      String nameTranslation,
      int ayahCount,
      String revelationType,
      String audioUrl,
      bool isBookmarked,
      bool isDownloaded,
      String localPath});
}

/// @nodoc
class _$SurahCopyWithImpl<$Res, $Val extends Surah>
    implements $SurahCopyWith<$Res> {
  _$SurahCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? name = null,
    Object? nameArabic = null,
    Object? nameTranslation = null,
    Object? ayahCount = null,
    Object? revelationType = null,
    Object? audioUrl = null,
    Object? isBookmarked = null,
    Object? isDownloaded = null,
    Object? localPath = null,
  }) {
    return _then(_value.copyWith(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameArabic: null == nameArabic
          ? _value.nameArabic
          : nameArabic // ignore: cast_nullable_to_non_nullable
              as String,
      nameTranslation: null == nameTranslation
          ? _value.nameTranslation
          : nameTranslation // ignore: cast_nullable_to_non_nullable
              as String,
      ayahCount: null == ayahCount
          ? _value.ayahCount
          : ayahCount // ignore: cast_nullable_to_non_nullable
              as int,
      revelationType: null == revelationType
          ? _value.revelationType
          : revelationType // ignore: cast_nullable_to_non_nullable
              as String,
      audioUrl: null == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isBookmarked: null == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool,
      isDownloaded: null == isDownloaded
          ? _value.isDownloaded
          : isDownloaded // ignore: cast_nullable_to_non_nullable
              as bool,
      localPath: null == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SurahImplCopyWith<$Res> implements $SurahCopyWith<$Res> {
  factory _$$SurahImplCopyWith(
          _$SurahImpl value, $Res Function(_$SurahImpl) then) =
      __$$SurahImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int number,
      String name,
      String nameArabic,
      String nameTranslation,
      int ayahCount,
      String revelationType,
      String audioUrl,
      bool isBookmarked,
      bool isDownloaded,
      String localPath});
}

/// @nodoc
class __$$SurahImplCopyWithImpl<$Res>
    extends _$SurahCopyWithImpl<$Res, _$SurahImpl>
    implements _$$SurahImplCopyWith<$Res> {
  __$$SurahImplCopyWithImpl(
      _$SurahImpl _value, $Res Function(_$SurahImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? name = null,
    Object? nameArabic = null,
    Object? nameTranslation = null,
    Object? ayahCount = null,
    Object? revelationType = null,
    Object? audioUrl = null,
    Object? isBookmarked = null,
    Object? isDownloaded = null,
    Object? localPath = null,
  }) {
    return _then(_$SurahImpl(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameArabic: null == nameArabic
          ? _value.nameArabic
          : nameArabic // ignore: cast_nullable_to_non_nullable
              as String,
      nameTranslation: null == nameTranslation
          ? _value.nameTranslation
          : nameTranslation // ignore: cast_nullable_to_non_nullable
              as String,
      ayahCount: null == ayahCount
          ? _value.ayahCount
          : ayahCount // ignore: cast_nullable_to_non_nullable
              as int,
      revelationType: null == revelationType
          ? _value.revelationType
          : revelationType // ignore: cast_nullable_to_non_nullable
              as String,
      audioUrl: null == audioUrl
          ? _value.audioUrl
          : audioUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isBookmarked: null == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool,
      isDownloaded: null == isDownloaded
          ? _value.isDownloaded
          : isDownloaded // ignore: cast_nullable_to_non_nullable
              as bool,
      localPath: null == localPath
          ? _value.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SurahImpl implements _Surah {
  const _$SurahImpl(
      {required this.number,
      required this.name,
      required this.nameArabic,
      required this.nameTranslation,
      required this.ayahCount,
      required this.revelationType,
      this.audioUrl = '',
      this.isBookmarked = false,
      this.isDownloaded = false,
      this.localPath = ''});

  factory _$SurahImpl.fromJson(Map<String, dynamic> json) =>
      _$$SurahImplFromJson(json);

  @override
  final int number;
  @override
  final String name;
  @override
  final String nameArabic;
  @override
  final String nameTranslation;
// English meaning
  @override
  final int ayahCount;
  @override
  final String revelationType;
// 'Meccan' or 'Medinan'
  @override
  @JsonKey()
  final String audioUrl;
// Placeholder, populated per Imam
  @override
  @JsonKey()
  final bool isBookmarked;
  @override
  @JsonKey()
  final bool isDownloaded;
  @override
  @JsonKey()
  final String localPath;

  @override
  String toString() {
    return 'Surah(number: $number, name: $name, nameArabic: $nameArabic, nameTranslation: $nameTranslation, ayahCount: $ayahCount, revelationType: $revelationType, audioUrl: $audioUrl, isBookmarked: $isBookmarked, isDownloaded: $isDownloaded, localPath: $localPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SurahImpl &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameArabic, nameArabic) ||
                other.nameArabic == nameArabic) &&
            (identical(other.nameTranslation, nameTranslation) ||
                other.nameTranslation == nameTranslation) &&
            (identical(other.ayahCount, ayahCount) ||
                other.ayahCount == ayahCount) &&
            (identical(other.revelationType, revelationType) ||
                other.revelationType == revelationType) &&
            (identical(other.audioUrl, audioUrl) ||
                other.audioUrl == audioUrl) &&
            (identical(other.isBookmarked, isBookmarked) ||
                other.isBookmarked == isBookmarked) &&
            (identical(other.isDownloaded, isDownloaded) ||
                other.isDownloaded == isDownloaded) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      number,
      name,
      nameArabic,
      nameTranslation,
      ayahCount,
      revelationType,
      audioUrl,
      isBookmarked,
      isDownloaded,
      localPath);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SurahImplCopyWith<_$SurahImpl> get copyWith =>
      __$$SurahImplCopyWithImpl<_$SurahImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SurahImplToJson(
      this,
    );
  }
}

abstract class _Surah implements Surah {
  const factory _Surah(
      {required final int number,
      required final String name,
      required final String nameArabic,
      required final String nameTranslation,
      required final int ayahCount,
      required final String revelationType,
      final String audioUrl,
      final bool isBookmarked,
      final bool isDownloaded,
      final String localPath}) = _$SurahImpl;

  factory _Surah.fromJson(Map<String, dynamic> json) = _$SurahImpl.fromJson;

  @override
  int get number;
  @override
  String get name;
  @override
  String get nameArabic;
  @override
  String get nameTranslation;
  @override // English meaning
  int get ayahCount;
  @override
  String get revelationType;
  @override // 'Meccan' or 'Medinan'
  String get audioUrl;
  @override // Placeholder, populated per Imam
  bool get isBookmarked;
  @override
  bool get isDownloaded;
  @override
  String get localPath;
  @override
  @JsonKey(ignore: true)
  _$$SurahImplCopyWith<_$SurahImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Ayah _$AyahFromJson(Map<String, dynamic> json) {
  return _Ayah.fromJson(json);
}

/// @nodoc
mixin _$Ayah {
  int get number => throw _privateConstructorUsedError; // Global ayah number
  int get numberInSurah =>
      throw _privateConstructorUsedError; // Ayah number within Surah
  int get surahNumber => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String get translation =>
      throw _privateConstructorUsedError; // Urdu translation
  double get startTime =>
      throw _privateConstructorUsedError; // In seconds (for Phase 2)
  double get endTime => throw _privateConstructorUsedError;
  bool get isBookmarked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AyahCopyWith<Ayah> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AyahCopyWith<$Res> {
  factory $AyahCopyWith(Ayah value, $Res Function(Ayah) then) =
      _$AyahCopyWithImpl<$Res, Ayah>;
  @useResult
  $Res call(
      {int number,
      int numberInSurah,
      int surahNumber,
      String text,
      String translation,
      double startTime,
      double endTime,
      bool isBookmarked});
}

/// @nodoc
class _$AyahCopyWithImpl<$Res, $Val extends Ayah>
    implements $AyahCopyWith<$Res> {
  _$AyahCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? numberInSurah = null,
    Object? surahNumber = null,
    Object? text = null,
    Object? translation = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? isBookmarked = null,
  }) {
    return _then(_value.copyWith(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      numberInSurah: null == numberInSurah
          ? _value.numberInSurah
          : numberInSurah // ignore: cast_nullable_to_non_nullable
              as int,
      surahNumber: null == surahNumber
          ? _value.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      translation: null == translation
          ? _value.translation
          : translation // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as double,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as double,
      isBookmarked: null == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AyahImplCopyWith<$Res> implements $AyahCopyWith<$Res> {
  factory _$$AyahImplCopyWith(
          _$AyahImpl value, $Res Function(_$AyahImpl) then) =
      __$$AyahImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int number,
      int numberInSurah,
      int surahNumber,
      String text,
      String translation,
      double startTime,
      double endTime,
      bool isBookmarked});
}

/// @nodoc
class __$$AyahImplCopyWithImpl<$Res>
    extends _$AyahCopyWithImpl<$Res, _$AyahImpl>
    implements _$$AyahImplCopyWith<$Res> {
  __$$AyahImplCopyWithImpl(_$AyahImpl _value, $Res Function(_$AyahImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? numberInSurah = null,
    Object? surahNumber = null,
    Object? text = null,
    Object? translation = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? isBookmarked = null,
  }) {
    return _then(_$AyahImpl(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      numberInSurah: null == numberInSurah
          ? _value.numberInSurah
          : numberInSurah // ignore: cast_nullable_to_non_nullable
              as int,
      surahNumber: null == surahNumber
          ? _value.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      translation: null == translation
          ? _value.translation
          : translation // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as double,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as double,
      isBookmarked: null == isBookmarked
          ? _value.isBookmarked
          : isBookmarked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AyahImpl implements _Ayah {
  const _$AyahImpl(
      {required this.number,
      required this.numberInSurah,
      required this.surahNumber,
      required this.text,
      this.translation = '',
      this.startTime = 0.0,
      this.endTime = 0.0,
      this.isBookmarked = false});

  factory _$AyahImpl.fromJson(Map<String, dynamic> json) =>
      _$$AyahImplFromJson(json);

  @override
  final int number;
// Global ayah number
  @override
  final int numberInSurah;
// Ayah number within Surah
  @override
  final int surahNumber;
  @override
  final String text;
  @override
  @JsonKey()
  final String translation;
// Urdu translation
  @override
  @JsonKey()
  final double startTime;
// In seconds (for Phase 2)
  @override
  @JsonKey()
  final double endTime;
  @override
  @JsonKey()
  final bool isBookmarked;

  @override
  String toString() {
    return 'Ayah(number: $number, numberInSurah: $numberInSurah, surahNumber: $surahNumber, text: $text, translation: $translation, startTime: $startTime, endTime: $endTime, isBookmarked: $isBookmarked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AyahImpl &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.numberInSurah, numberInSurah) ||
                other.numberInSurah == numberInSurah) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.translation, translation) ||
                other.translation == translation) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.isBookmarked, isBookmarked) ||
                other.isBookmarked == isBookmarked));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, number, numberInSurah,
      surahNumber, text, translation, startTime, endTime, isBookmarked);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AyahImplCopyWith<_$AyahImpl> get copyWith =>
      __$$AyahImplCopyWithImpl<_$AyahImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AyahImplToJson(
      this,
    );
  }
}

abstract class _Ayah implements Ayah {
  const factory _Ayah(
      {required final int number,
      required final int numberInSurah,
      required final int surahNumber,
      required final String text,
      final String translation,
      final double startTime,
      final double endTime,
      final bool isBookmarked}) = _$AyahImpl;

  factory _Ayah.fromJson(Map<String, dynamic> json) = _$AyahImpl.fromJson;

  @override
  int get number;
  @override // Global ayah number
  int get numberInSurah;
  @override // Ayah number within Surah
  int get surahNumber;
  @override
  String get text;
  @override
  String get translation;
  @override // Urdu translation
  double get startTime;
  @override // In seconds (for Phase 2)
  double get endTime;
  @override
  bool get isBookmarked;
  @override
  @JsonKey(ignore: true)
  _$$AyahImplCopyWith<_$AyahImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Bookmark _$BookmarkFromJson(Map<String, dynamic> json) {
  return _Bookmark.fromJson(json);
}

/// @nodoc
mixin _$Bookmark {
  String get id => throw _privateConstructorUsedError; // UUID
  int get surahNumber => throw _privateConstructorUsedError;
  int? get ayahNumber =>
      throw _privateConstructorUsedError; // Null if bookmark is Surah-level
  String get title => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;
  bool get isDeleted => throw _privateConstructorUsedError;
  int? get cloudId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BookmarkCopyWith<Bookmark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookmarkCopyWith<$Res> {
  factory $BookmarkCopyWith(Bookmark value, $Res Function(Bookmark) then) =
      _$BookmarkCopyWithImpl<$Res, Bookmark>;
  @useResult
  $Res call(
      {String id,
      int surahNumber,
      int? ayahNumber,
      String title,
      DateTime createdAt,
      String notes,
      bool isSynced,
      bool isDeleted,
      int? cloudId});
}

/// @nodoc
class _$BookmarkCopyWithImpl<$Res, $Val extends Bookmark>
    implements $BookmarkCopyWith<$Res> {
  _$BookmarkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? surahNumber = null,
    Object? ayahNumber = freezed,
    Object? title = null,
    Object? createdAt = null,
    Object? notes = null,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? cloudId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      surahNumber: null == surahNumber
          ? _value.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      ayahNumber: freezed == ayahNumber
          ? _value.ayahNumber
          : ayahNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      cloudId: freezed == cloudId
          ? _value.cloudId
          : cloudId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookmarkImplCopyWith<$Res>
    implements $BookmarkCopyWith<$Res> {
  factory _$$BookmarkImplCopyWith(
          _$BookmarkImpl value, $Res Function(_$BookmarkImpl) then) =
      __$$BookmarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      int surahNumber,
      int? ayahNumber,
      String title,
      DateTime createdAt,
      String notes,
      bool isSynced,
      bool isDeleted,
      int? cloudId});
}

/// @nodoc
class __$$BookmarkImplCopyWithImpl<$Res>
    extends _$BookmarkCopyWithImpl<$Res, _$BookmarkImpl>
    implements _$$BookmarkImplCopyWith<$Res> {
  __$$BookmarkImplCopyWithImpl(
      _$BookmarkImpl _value, $Res Function(_$BookmarkImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? surahNumber = null,
    Object? ayahNumber = freezed,
    Object? title = null,
    Object? createdAt = null,
    Object? notes = null,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? cloudId = freezed,
  }) {
    return _then(_$BookmarkImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      surahNumber: null == surahNumber
          ? _value.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      ayahNumber: freezed == ayahNumber
          ? _value.ayahNumber
          : ayahNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      cloudId: freezed == cloudId
          ? _value.cloudId
          : cloudId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookmarkImpl implements _Bookmark {
  const _$BookmarkImpl(
      {required this.id,
      required this.surahNumber,
      this.ayahNumber,
      required this.title,
      required this.createdAt,
      this.notes = '',
      this.isSynced = false,
      this.isDeleted = false,
      this.cloudId});

  factory _$BookmarkImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookmarkImplFromJson(json);

  @override
  final String id;
// UUID
  @override
  final int surahNumber;
  @override
  final int? ayahNumber;
// Null if bookmark is Surah-level
  @override
  final String title;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final int? cloudId;

  @override
  String toString() {
    return 'Bookmark(id: $id, surahNumber: $surahNumber, ayahNumber: $ayahNumber, title: $title, createdAt: $createdAt, notes: $notes, isSynced: $isSynced, isDeleted: $isDeleted, cloudId: $cloudId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookmarkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.ayahNumber, ayahNumber) ||
                other.ayahNumber == ayahNumber) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.cloudId, cloudId) || other.cloudId == cloudId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, surahNumber, ayahNumber,
      title, createdAt, notes, isSynced, isDeleted, cloudId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookmarkImplCopyWith<_$BookmarkImpl> get copyWith =>
      __$$BookmarkImplCopyWithImpl<_$BookmarkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookmarkImplToJson(
      this,
    );
  }
}

abstract class _Bookmark implements Bookmark {
  const factory _Bookmark(
      {required final String id,
      required final int surahNumber,
      final int? ayahNumber,
      required final String title,
      required final DateTime createdAt,
      final String notes,
      final bool isSynced,
      final bool isDeleted,
      final int? cloudId}) = _$BookmarkImpl;

  factory _Bookmark.fromJson(Map<String, dynamic> json) =
      _$BookmarkImpl.fromJson;

  @override
  String get id;
  @override // UUID
  int get surahNumber;
  @override
  int? get ayahNumber;
  @override // Null if bookmark is Surah-level
  String get title;
  @override
  DateTime get createdAt;
  @override
  String get notes;
  @override
  bool get isSynced;
  @override
  bool get isDeleted;
  @override
  int? get cloudId;
  @override
  @JsonKey(ignore: true)
  _$$BookmarkImplCopyWith<_$BookmarkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaybackState _$PlaybackStateFromJson(Map<String, dynamic> json) {
  return _PlaybackState.fromJson(json);
}

/// @nodoc
mixin _$PlaybackState {
  bool get isPlaying => throw _privateConstructorUsedError;
  Duration get currentPosition => throw _privateConstructorUsedError;
  Duration get totalDuration => throw _privateConstructorUsedError;
  double get playbackRate => throw _privateConstructorUsedError;
  int get currentSurahNumber => throw _privateConstructorUsedError;
  int? get currentAyahNumber => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlaybackStateCopyWith<PlaybackState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaybackStateCopyWith<$Res> {
  factory $PlaybackStateCopyWith(
          PlaybackState value, $Res Function(PlaybackState) then) =
      _$PlaybackStateCopyWithImpl<$Res, PlaybackState>;
  @useResult
  $Res call(
      {bool isPlaying,
      Duration currentPosition,
      Duration totalDuration,
      double playbackRate,
      int currentSurahNumber,
      int? currentAyahNumber});
}

/// @nodoc
class _$PlaybackStateCopyWithImpl<$Res, $Val extends PlaybackState>
    implements $PlaybackStateCopyWith<$Res> {
  _$PlaybackStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPlaying = null,
    Object? currentPosition = null,
    Object? totalDuration = null,
    Object? playbackRate = null,
    Object? currentSurahNumber = null,
    Object? currentAyahNumber = freezed,
  }) {
    return _then(_value.copyWith(
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPosition: null == currentPosition
          ? _value.currentPosition
          : currentPosition // ignore: cast_nullable_to_non_nullable
              as Duration,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      playbackRate: null == playbackRate
          ? _value.playbackRate
          : playbackRate // ignore: cast_nullable_to_non_nullable
              as double,
      currentSurahNumber: null == currentSurahNumber
          ? _value.currentSurahNumber
          : currentSurahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      currentAyahNumber: freezed == currentAyahNumber
          ? _value.currentAyahNumber
          : currentAyahNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlaybackStateImplCopyWith<$Res>
    implements $PlaybackStateCopyWith<$Res> {
  factory _$$PlaybackStateImplCopyWith(
          _$PlaybackStateImpl value, $Res Function(_$PlaybackStateImpl) then) =
      __$$PlaybackStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isPlaying,
      Duration currentPosition,
      Duration totalDuration,
      double playbackRate,
      int currentSurahNumber,
      int? currentAyahNumber});
}

/// @nodoc
class __$$PlaybackStateImplCopyWithImpl<$Res>
    extends _$PlaybackStateCopyWithImpl<$Res, _$PlaybackStateImpl>
    implements _$$PlaybackStateImplCopyWith<$Res> {
  __$$PlaybackStateImplCopyWithImpl(
      _$PlaybackStateImpl _value, $Res Function(_$PlaybackStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPlaying = null,
    Object? currentPosition = null,
    Object? totalDuration = null,
    Object? playbackRate = null,
    Object? currentSurahNumber = null,
    Object? currentAyahNumber = freezed,
  }) {
    return _then(_$PlaybackStateImpl(
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPosition: null == currentPosition
          ? _value.currentPosition
          : currentPosition // ignore: cast_nullable_to_non_nullable
              as Duration,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      playbackRate: null == playbackRate
          ? _value.playbackRate
          : playbackRate // ignore: cast_nullable_to_non_nullable
              as double,
      currentSurahNumber: null == currentSurahNumber
          ? _value.currentSurahNumber
          : currentSurahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      currentAyahNumber: freezed == currentAyahNumber
          ? _value.currentAyahNumber
          : currentAyahNumber // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaybackStateImpl implements _PlaybackState {
  const _$PlaybackStateImpl(
      {required this.isPlaying,
      required this.currentPosition,
      required this.totalDuration,
      this.playbackRate = 1.0,
      required this.currentSurahNumber,
      this.currentAyahNumber});

  factory _$PlaybackStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaybackStateImplFromJson(json);

  @override
  final bool isPlaying;
  @override
  final Duration currentPosition;
  @override
  final Duration totalDuration;
  @override
  @JsonKey()
  final double playbackRate;
  @override
  final int currentSurahNumber;
  @override
  final int? currentAyahNumber;

  @override
  String toString() {
    return 'PlaybackState(isPlaying: $isPlaying, currentPosition: $currentPosition, totalDuration: $totalDuration, playbackRate: $playbackRate, currentSurahNumber: $currentSurahNumber, currentAyahNumber: $currentAyahNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaybackStateImpl &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.currentPosition, currentPosition) ||
                other.currentPosition == currentPosition) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.playbackRate, playbackRate) ||
                other.playbackRate == playbackRate) &&
            (identical(other.currentSurahNumber, currentSurahNumber) ||
                other.currentSurahNumber == currentSurahNumber) &&
            (identical(other.currentAyahNumber, currentAyahNumber) ||
                other.currentAyahNumber == currentAyahNumber));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, isPlaying, currentPosition,
      totalDuration, playbackRate, currentSurahNumber, currentAyahNumber);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaybackStateImplCopyWith<_$PlaybackStateImpl> get copyWith =>
      __$$PlaybackStateImplCopyWithImpl<_$PlaybackStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaybackStateImplToJson(
      this,
    );
  }
}

abstract class _PlaybackState implements PlaybackState {
  const factory _PlaybackState(
      {required final bool isPlaying,
      required final Duration currentPosition,
      required final Duration totalDuration,
      final double playbackRate,
      required final int currentSurahNumber,
      final int? currentAyahNumber}) = _$PlaybackStateImpl;

  factory _PlaybackState.fromJson(Map<String, dynamic> json) =
      _$PlaybackStateImpl.fromJson;

  @override
  bool get isPlaying;
  @override
  Duration get currentPosition;
  @override
  Duration get totalDuration;
  @override
  double get playbackRate;
  @override
  int get currentSurahNumber;
  @override
  int? get currentAyahNumber;
  @override
  @JsonKey(ignore: true)
  _$$PlaybackStateImplCopyWith<_$PlaybackStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) {
  return _AppSettings.fromJson(json);
}

/// @nodoc
mixin _$AppSettings {
  int get selectedImamId => throw _privateConstructorUsedError;
  double get playbackRate => throw _privateConstructorUsedError;
  bool get autoPlayNextSurah => throw _privateConstructorUsedError;
  bool get showTranslation => throw _privateConstructorUsedError; // Phase 2
  bool get repeatSurah => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
          AppSettings value, $Res Function(AppSettings) then) =
      _$AppSettingsCopyWithImpl<$Res, AppSettings>;
  @useResult
  $Res call(
      {int selectedImamId,
      double playbackRate,
      bool autoPlayNextSurah,
      bool showTranslation,
      bool repeatSurah});
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res, $Val extends AppSettings>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedImamId = null,
    Object? playbackRate = null,
    Object? autoPlayNextSurah = null,
    Object? showTranslation = null,
    Object? repeatSurah = null,
  }) {
    return _then(_value.copyWith(
      selectedImamId: null == selectedImamId
          ? _value.selectedImamId
          : selectedImamId // ignore: cast_nullable_to_non_nullable
              as int,
      playbackRate: null == playbackRate
          ? _value.playbackRate
          : playbackRate // ignore: cast_nullable_to_non_nullable
              as double,
      autoPlayNextSurah: null == autoPlayNextSurah
          ? _value.autoPlayNextSurah
          : autoPlayNextSurah // ignore: cast_nullable_to_non_nullable
              as bool,
      showTranslation: null == showTranslation
          ? _value.showTranslation
          : showTranslation // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatSurah: null == repeatSurah
          ? _value.repeatSurah
          : repeatSurah // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppSettingsImplCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$$AppSettingsImplCopyWith(
          _$AppSettingsImpl value, $Res Function(_$AppSettingsImpl) then) =
      __$$AppSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int selectedImamId,
      double playbackRate,
      bool autoPlayNextSurah,
      bool showTranslation,
      bool repeatSurah});
}

/// @nodoc
class __$$AppSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsCopyWithImpl<$Res, _$AppSettingsImpl>
    implements _$$AppSettingsImplCopyWith<$Res> {
  __$$AppSettingsImplCopyWithImpl(
      _$AppSettingsImpl _value, $Res Function(_$AppSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedImamId = null,
    Object? playbackRate = null,
    Object? autoPlayNextSurah = null,
    Object? showTranslation = null,
    Object? repeatSurah = null,
  }) {
    return _then(_$AppSettingsImpl(
      selectedImamId: null == selectedImamId
          ? _value.selectedImamId
          : selectedImamId // ignore: cast_nullable_to_non_nullable
              as int,
      playbackRate: null == playbackRate
          ? _value.playbackRate
          : playbackRate // ignore: cast_nullable_to_non_nullable
              as double,
      autoPlayNextSurah: null == autoPlayNextSurah
          ? _value.autoPlayNextSurah
          : autoPlayNextSurah // ignore: cast_nullable_to_non_nullable
              as bool,
      showTranslation: null == showTranslation
          ? _value.showTranslation
          : showTranslation // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatSurah: null == repeatSurah
          ? _value.repeatSurah
          : repeatSurah // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSettingsImpl implements _AppSettings {
  const _$AppSettingsImpl(
      {required this.selectedImamId,
      this.playbackRate = 1.0,
      this.autoPlayNextSurah = true,
      this.showTranslation = false,
      this.repeatSurah = false});

  factory _$AppSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSettingsImplFromJson(json);

  @override
  final int selectedImamId;
  @override
  @JsonKey()
  final double playbackRate;
  @override
  @JsonKey()
  final bool autoPlayNextSurah;
  @override
  @JsonKey()
  final bool showTranslation;
// Phase 2
  @override
  @JsonKey()
  final bool repeatSurah;

  @override
  String toString() {
    return 'AppSettings(selectedImamId: $selectedImamId, playbackRate: $playbackRate, autoPlayNextSurah: $autoPlayNextSurah, showTranslation: $showTranslation, repeatSurah: $repeatSurah)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsImpl &&
            (identical(other.selectedImamId, selectedImamId) ||
                other.selectedImamId == selectedImamId) &&
            (identical(other.playbackRate, playbackRate) ||
                other.playbackRate == playbackRate) &&
            (identical(other.autoPlayNextSurah, autoPlayNextSurah) ||
                other.autoPlayNextSurah == autoPlayNextSurah) &&
            (identical(other.showTranslation, showTranslation) ||
                other.showTranslation == showTranslation) &&
            (identical(other.repeatSurah, repeatSurah) ||
                other.repeatSurah == repeatSurah));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, selectedImamId, playbackRate,
      autoPlayNextSurah, showTranslation, repeatSurah);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      __$$AppSettingsImplCopyWithImpl<_$AppSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSettingsImplToJson(
      this,
    );
  }
}

abstract class _AppSettings implements AppSettings {
  const factory _AppSettings(
      {required final int selectedImamId,
      final double playbackRate,
      final bool autoPlayNextSurah,
      final bool showTranslation,
      final bool repeatSurah}) = _$AppSettingsImpl;

  factory _AppSettings.fromJson(Map<String, dynamic> json) =
      _$AppSettingsImpl.fromJson;

  @override
  int get selectedImamId;
  @override
  double get playbackRate;
  @override
  bool get autoPlayNextSurah;
  @override
  bool get showTranslation;
  @override // Phase 2
  bool get repeatSurah;
  @override
  @JsonKey(ignore: true)
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DownloadProgress _$DownloadProgressFromJson(Map<String, dynamic> json) {
  return _DownloadProgress.fromJson(json);
}

/// @nodoc
mixin _$DownloadProgress {
  int get surahNumber => throw _privateConstructorUsedError;
  int get imamId => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError; // 0.0 to 1.0
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'downloading', 'completed', 'failed'
  String? get error => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DownloadProgressCopyWith<DownloadProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DownloadProgressCopyWith<$Res> {
  factory $DownloadProgressCopyWith(
          DownloadProgress value, $Res Function(DownloadProgress) then) =
      _$DownloadProgressCopyWithImpl<$Res, DownloadProgress>;
  @useResult
  $Res call(
      {int surahNumber,
      int imamId,
      double progress,
      String status,
      String? error});
}

/// @nodoc
class _$DownloadProgressCopyWithImpl<$Res, $Val extends DownloadProgress>
    implements $DownloadProgressCopyWith<$Res> {
  _$DownloadProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surahNumber = null,
    Object? imamId = null,
    Object? progress = null,
    Object? status = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      surahNumber: null == surahNumber
          ? _value.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      imamId: null == imamId
          ? _value.imamId
          : imamId // ignore: cast_nullable_to_non_nullable
              as int,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DownloadProgressImplCopyWith<$Res>
    implements $DownloadProgressCopyWith<$Res> {
  factory _$$DownloadProgressImplCopyWith(_$DownloadProgressImpl value,
          $Res Function(_$DownloadProgressImpl) then) =
      __$$DownloadProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int surahNumber,
      int imamId,
      double progress,
      String status,
      String? error});
}

/// @nodoc
class __$$DownloadProgressImplCopyWithImpl<$Res>
    extends _$DownloadProgressCopyWithImpl<$Res, _$DownloadProgressImpl>
    implements _$$DownloadProgressImplCopyWith<$Res> {
  __$$DownloadProgressImplCopyWithImpl(_$DownloadProgressImpl _value,
      $Res Function(_$DownloadProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surahNumber = null,
    Object? imamId = null,
    Object? progress = null,
    Object? status = null,
    Object? error = freezed,
  }) {
    return _then(_$DownloadProgressImpl(
      surahNumber: null == surahNumber
          ? _value.surahNumber
          : surahNumber // ignore: cast_nullable_to_non_nullable
              as int,
      imamId: null == imamId
          ? _value.imamId
          : imamId // ignore: cast_nullable_to_non_nullable
              as int,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DownloadProgressImpl implements _DownloadProgress {
  const _$DownloadProgressImpl(
      {required this.surahNumber,
      required this.imamId,
      this.progress = 0.0,
      this.status = '',
      this.error = ''});

  factory _$DownloadProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$DownloadProgressImplFromJson(json);

  @override
  final int surahNumber;
  @override
  final int imamId;
  @override
  @JsonKey()
  final double progress;
// 0.0 to 1.0
  @override
  @JsonKey()
  final String status;
// 'pending', 'downloading', 'completed', 'failed'
  @override
  @JsonKey()
  final String? error;

  @override
  String toString() {
    return 'DownloadProgress(surahNumber: $surahNumber, imamId: $imamId, progress: $progress, status: $status, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DownloadProgressImpl &&
            (identical(other.surahNumber, surahNumber) ||
                other.surahNumber == surahNumber) &&
            (identical(other.imamId, imamId) || other.imamId == imamId) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, surahNumber, imamId, progress, status, error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DownloadProgressImplCopyWith<_$DownloadProgressImpl> get copyWith =>
      __$$DownloadProgressImplCopyWithImpl<_$DownloadProgressImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DownloadProgressImplToJson(
      this,
    );
  }
}

abstract class _DownloadProgress implements DownloadProgress {
  const factory _DownloadProgress(
      {required final int surahNumber,
      required final int imamId,
      final double progress,
      final String status,
      final String? error}) = _$DownloadProgressImpl;

  factory _DownloadProgress.fromJson(Map<String, dynamic> json) =
      _$DownloadProgressImpl.fromJson;

  @override
  int get surahNumber;
  @override
  int get imamId;
  @override
  double get progress;
  @override // 0.0 to 1.0
  String get status;
  @override // 'pending', 'downloading', 'completed', 'failed'
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$DownloadProgressImplCopyWith<_$DownloadProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
