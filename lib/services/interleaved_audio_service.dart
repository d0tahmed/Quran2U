import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for permanent save
import 'package:quran_recitation/services/download_service.dart';

const _everyayahFolders = <int, String>{
  1: 'Abdurrahmaan_As-Sudais_192kbps',
  2: 'Alafasy_128kbps',
  3: 'Yasser_Ad-Dussary_128kbps',
  4: 'MaherAlMuaiqly128kbps',
  5: 'Saood_ash-Shuraym_128kbps',
  8: 'Ali_Jaber_64kbps',
  10: 'Nasser_Alqatami_128kbps',
  9: 'Muhammad_Ayyoub_128kbps',
};

const _arabicFallbackFolder = 'Alafasy_128kbps';
const _everyayahBase = 'https://www.everyayah.com/data';
const _urduFolder    = 'translations/urdu_shamshad_ali_khan_46kbps';
const _englishFolder = 'English/Sahih_Intnl_Ibrahim_Walk_192kbps';

enum TranslationMode { none, urdu, english }

class InterleavedAudioService {
  final AudioPlayer _player = AudioPlayer();
  final _downloadService = DownloadService();

  int? _loadedSurah;
  int? _loadedImamId;
  TranslationMode _loadedMode = TranslationMode.none;

  ConcatenatingAudioSource? _playlist;
  int _lastAppendedAyah = 0;
  int _totalAyahs = 0;
  String _arabicFolder = '';
  StreamSubscription<int?>? _indexSub;

  TranslationMode activeMode = TranslationMode.urdu;

  final Map<int, (int, bool)> _segmentMetadata = {};

  Stream<PlayerState>  get playerStateStream  => _player.playerStateStream;
  Stream<Duration?>    get durationStream     => _player.durationStream;
  Stream<Duration>     get positionStream     => _player.positionStream;
  Stream<int?>         get currentIndexStream => _player.currentIndexStream;

  Stream<int?> get currentAyahStream =>
      _player.currentIndexStream.map((idx) =>
          idx != null ? _segmentMetadata[idx]?.$1 : null);

  Stream<bool> get isUrduSegmentStream =>
      _player.currentIndexStream.map((idx) =>
          idx != null ? (_segmentMetadata[idx]?.$2 ?? false) : false);

  AudioPlayer get player => _player;

  Future<void> setLoopMode(bool loop) async {
    try {
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    } catch (e) {
      debugPrint('InterleavedAudioService.setLoopMode error: $e');
    }
  }

  Future<void> buildAndPlay({
    required int surahNumber,
    required int ayahCount,
    required int imamId,
    TranslationMode mode = TranslationMode.urdu, 
  }) async {
    // 👇 BULLETPROOF FIX: Force read from the phone's hard drive so it NEVER resets 👇
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('audio_tarjumah_lang') ?? 'urdu';
    activeMode = savedLang == 'english' ? TranslationMode.english : TranslationMode.urdu;

    if (_loadedSurah == surahNumber &&
        _loadedImamId == imamId &&
        _loadedMode == activeMode) { 
      if (!_player.playing) play();
      return;
    }

    try {
      _loadedSurah      = surahNumber;
      _loadedImamId     = imamId;
      _loadedMode       = activeMode; 
      _totalAyahs       = ayahCount;
      _arabicFolder     = _everyayahFolders[imamId] ?? _arabicFallbackFolder;
      _lastAppendedAyah = 0;
      _segmentMetadata.clear();

      _playlist = ConcatenatingAudioSource(children: []);
      await _appendNextChunk(10);

      _indexSub?.cancel();
      _indexSub = _player.currentIndexStream.listen((idx) {
        if (idx != null && _playlist != null) {
          final remaining = _playlist!.length - idx;
          if (remaining <= 6 && _lastAppendedAyah < _totalAyahs) {
            _appendNextChunk(10);
          }
        }
      });

      _player.setAudioSource(_playlist!).then((_) => play());
    } catch (e) {
      debugPrint('InterleavedAudioService.buildAndPlay error: $e');
      _loadedSurah  = null;
      _loadedImamId = null;
      rethrow;
    }
  }

  Future<void> _appendNextChunk(int count) async {
    if (_playlist == null || _loadedSurah == null) return;

    final start = _lastAppendedAyah + 1;
    final end   = (start + count - 1).clamp(0, _totalAyahs);
    if (start > end) return;

    final sources = <AudioSource>[];
    int currentSegmentIndex = _playlist!.length;

    final translationFolder = activeMode == TranslationMode.english
        ? _englishFolder
        : _urduFolder;

    for (int ayah = start; ayah <= end; ayah++) {
      final s = _loadedSurah!.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');

      final localArabic = await _downloadService.getLocalArabicAyahPath(
          _loadedSurah!, ayah, _loadedImamId!);

      final arabicMediaItem = MediaItem(
        id:    'arabic_${_loadedSurah}_$ayah',
        title: 'Ayah $ayah (Arabic)',
        album: 'Surah $_loadedSurah',
      );

      bool addedLocalArabic = false;
      if (localArabic != null) {
        final f = File(localArabic);
        if (f.existsSync() && f.lengthSync() > 1000) {
          sources.add(AudioSource.file(localArabic, tag: arabicMediaItem));
          addedLocalArabic = true;
        }
      }
      if (!addedLocalArabic) {
        sources.add(AudioSource.uri(
          Uri.parse('$_everyayahBase/$_arabicFolder/$s$a.mp3'),
          tag: arabicMediaItem,
        ));
      }

      _segmentMetadata[currentSegmentIndex] = (ayah, false);
      currentSegmentIndex++;

      final langLabel = activeMode == TranslationMode.english ? 'English' : 'Urdu';

      final translationMediaItem = MediaItem(
        id:    '${activeMode.name}_${_loadedSurah}_$ayah',
        title: 'Ayah $ayah ($langLabel)',
        album: 'Surah $_loadedSurah',
      );

      bool addedLocalTranslation = false;
      if (activeMode == TranslationMode.urdu) {
        final localUrdu = await _downloadService.getLocalUrduAyahPath(
            _loadedSurah!, ayah, _loadedImamId!);
        if (localUrdu != null) {
          final f = File(localUrdu);
          if (f.existsSync() && f.lengthSync() > 1000) {
            sources.add(AudioSource.file(localUrdu, tag: translationMediaItem));
            addedLocalTranslation = true;
          }
        }
      }

      if (!addedLocalTranslation) {
        sources.add(AudioSource.uri(
          Uri.parse('$_everyayahBase/$translationFolder/$s$a.mp3'),
          tag: translationMediaItem,
        ));
      }

      _segmentMetadata[currentSegmentIndex] = (ayah, true);
      currentSegmentIndex++;
    }

    await _playlist!.addAll(sources);
    _lastAppendedAyah = end;
  }

  Future<void> play()  async { try { await _player.play();  } catch (e) { debugPrint('play: $e'); } }
  Future<void> pause() async { try { await _player.pause(); } catch (e) { debugPrint('pause: $e'); } }
  Future<void> seek(Duration position) async { try { await _player.seek(position); } catch (e) { debugPrint('seek: $e'); } }
  Future<void> setSpeed(double speed)  async { try { await _player.setSpeed(speed); } catch (e) { debugPrint('setSpeed: $e'); } }

  Future<void> dispose() async {
    _loadedSurah  = null;
    _loadedImamId = null;
    _indexSub?.cancel();
    await _player.dispose();
  }
}