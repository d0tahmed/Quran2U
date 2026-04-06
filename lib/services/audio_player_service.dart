import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'; // REQUIRED!
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/services/download_service.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _downloadService = DownloadService();

  String? _loadedUrl;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  AudioPlayer get player => _audioPlayer;
  String? get currentUrl => _loadedUrl;

  Future<void> loadAndPlay(String audioUrl,
      {int? surahNumber, int? imamId}) async {
    if (audioUrl.isEmpty) return;

    try {
      String? localPath;
      if (surahNumber != null && imamId != null) {
        localPath = await _downloadService.getLocalRecitationPath(surahNumber, imamId);
      }

      // SENIOR FIX: The background isolate will native crash if this is missing.
      final mediaItem = MediaItem(
        id: audioUrl,
        title: surahNumber != null ? 'Surah $surahNumber' : 'Quran Recitation',
        album: 'Quran2U',
      );

      final source = localPath != null
          ? AudioSource.file(localPath, tag: mediaItem)
          : AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem);

      if (_loadedUrl != audioUrl) {
        await _audioPlayer.setAudioSource(source, preload: false);
        _loadedUrl = audioUrl;
      }
      await play();
    } catch (e) {
      debugPrint('AudioPlayerService.loadAndPlay error: $e');
      _loadedUrl = null; 
    }
  }

  Future<void> play() async {
    try { await _audioPlayer.play(); }
    catch (e) { debugPrint('AudioPlayerService.play: $e'); }
  }

  Future<void> pause() async {
    try { await _audioPlayer.pause(); }
    catch (e) { debugPrint('AudioPlayerService.pause: $e'); }
  }

  Future<void> seek(Duration position) async {
    try { await _audioPlayer.seek(position); }
    catch (e) { debugPrint('AudioPlayerService.seek: $e'); }
  }

  Future<void> skipForward5Seconds() async =>
      seek(_audioPlayer.position + const Duration(seconds: 5));

  Future<void> skipBackward5Seconds() async {
    final p = _audioPlayer.position - const Duration(seconds: 5);
    await seek(p.isNegative ? Duration.zero : p);
  }

  Future<void> setPlaybackRate(double rate) async {
    try { await _audioPlayer.setSpeed(rate); }
    catch (e) { debugPrint('AudioPlayerService.setSpeed: $e'); }
  }

  Future<void> setLoopMode(bool loop) async {
    try {
      await _audioPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    } catch (e) {
      debugPrint('AudioPlayerService.setLoopMode: $e');
    }
  }

  PlaybackState getCurrentState(int currentSurahNumber) => PlaybackState(
    isPlaying: _audioPlayer.playing,
    currentPosition: _audioPlayer.position,
    totalDuration: _audioPlayer.duration ?? Duration.zero,
    playbackRate: _audioPlayer.speed,
    currentSurahNumber: currentSurahNumber,
    currentAyahNumber: null,
  );

  Future<void> dispose() async {
    _loadedUrl = null;
    await _audioPlayer.dispose();
  }
}