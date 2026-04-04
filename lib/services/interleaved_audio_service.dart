import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran_recitation/services/download_service.dart';

const _everyayahFolders = <int, String>{
  1: 'Abdurrahmaan_As-Sudais_192kbps',
  2: 'Alafasy_128kbps',
  3: 'Yasser_Ad-Dussary_128kbps',
  4: 'MaherAlMuaiqly128kbps',
  5: 'Saood_ash-Shuraym_128kbps',
};
const _arabicFallbackFolder = 'Alafasy_128kbps';
const _everyayahBase = 'https://www.everyayah.com/data';
const _urduFolder = 'translations/urdu_shamshad_ali_khan_46kbps';

class InterleavedAudioService {
  final AudioPlayer _player = AudioPlayer();
  final _downloadService = DownloadService();

  int? _loadedSurah;
  int? _loadedImamId;

  ConcatenatingAudioSource? _playlist;
  int _lastAppendedAyah = 0;
  int _totalAyahs = 0;
  String _arabicFolder = '';
  StreamSubscription<int?>? _indexSub;

  final Map<int, (int, bool)> _segmentMetadata = {};

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Stream<int?> get currentAyahStream => _player.currentIndexStream
      .map((idx) => idx != null ? _segmentMetadata[idx]?.$1 : null);

  Stream<bool> get isUrduSegmentStream =>
      _player.currentIndexStream.map((idx) => idx != null ? (_segmentMetadata[idx]?.$2 ?? false) : false);

  AudioPlayer get player => _player;

  Future<void> buildAndPlay({
    required int surahNumber,
    required int ayahCount,
    required int imamId,
  }) async {
    if (_loadedSurah == surahNumber && _loadedImamId == imamId) {
      if (!_player.playing) play();
      return;
    }

    try {
      _loadedSurah = surahNumber;
      _loadedImamId = imamId;
      _totalAyahs = ayahCount;
      _arabicFolder = _everyayahFolders[imamId] ?? _arabicFallbackFolder;
      _lastAppendedAyah = 0;
      _segmentMetadata.clear();

      // SENIOR FIX: Removed "useLazyPreparation: true". 
      // Background isolate crashes natively if this is enabled!
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

      _player.setAudioSource(_playlist!, preload: false).then((_) => play());
    } catch (e) {
      debugPrint('InterleavedAudioService.buildAndPlay error: $e');
      _loadedSurah = null;
      _loadedImamId = null;
      rethrow;
    }
  }
  
  Future<void> _appendNextChunk(int count) async {
    if (_playlist == null || _loadedSurah == null) return;

    final start = _lastAppendedAyah + 1;
    final end = (start + count - 1).clamp(0, _totalAyahs);
    if (start > end) return;

    final sources = <AudioSource>[];
    int currentSegmentIndex = _playlist!.length;

    for (int ayah = start; ayah <= end; ayah++) {
      final s = _loadedSurah!.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');

      // ── Arabic ayah ──
      final localArabic = await _downloadService.getLocalArabicAyahPath(
          _loadedSurah!, ayah, _loadedImamId!);
          
      final arabicMediaItem = MediaItem(
          id: 'arabic_${_loadedSurah}_$ayah', 
          title: 'Ayah $ayah (Arabic)', 
          album: 'Surah $_loadedSurah'
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
          tag: arabicMediaItem
        ));
      }
      
      _segmentMetadata[currentSegmentIndex] = (ayah, false);
      currentSegmentIndex++;

      // ── Urdu ayah ──
      final localUrdu = await _downloadService.getLocalUrduAyahPath(
          _loadedSurah!, ayah, _loadedImamId!);
          
      final urduMediaItem = MediaItem(
        id: 'urdu_${_loadedSurah}_$ayah', 
        title: 'Ayah $ayah (Urdu)', 
        album: 'Surah $_loadedSurah'
      );

      bool addedLocalUrdu = false;
      if (localUrdu != null) {
        final f = File(localUrdu);
        if (f.existsSync() && f.lengthSync() > 1000) {
          sources.add(AudioSource.file(localUrdu, tag: urduMediaItem));
          addedLocalUrdu = true;
        }
      }
      
      if (!addedLocalUrdu) {
        // SENIOR FIX: The Urdu network stream fallback is back
        sources.add(AudioSource.uri(
          Uri.parse('$_everyayahBase/$_urduFolder/$s$a.mp3'),
          tag: urduMediaItem
        ));
      }
      
      _segmentMetadata[currentSegmentIndex] = (ayah, true);
      currentSegmentIndex++;
    }

    await _playlist!.addAll(sources);
    _lastAppendedAyah = end;
  }

  Future<void> play() async {
    try { await _player.play(); } 
    catch (e) { debugPrint('InterleavedAudioService.play: $e'); }
  }

  Future<void> pause() async {
    try { await _player.pause(); } 
    catch (e) { debugPrint('InterleavedAudioService.pause: $e'); }
  }

  Future<void> seek(Duration position) async {
    try { await _player.seek(position); } 
    catch (e) { debugPrint('InterleavedAudioService.seek: $e'); }
  }

  Future<void> setSpeed(double speed) async {
    try { await _player.setSpeed(speed); } 
    catch (e) { debugPrint('InterleavedAudioService.setSpeed: $e'); }
  }

  Future<void> dispose() async {
    _loadedSurah = null;
    _loadedImamId = null;
    _indexSub?.cancel();
    await _player.dispose();
  }
}