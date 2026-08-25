// lib/services/hifz_audio.dart
//
// Ayah-level playback with a repeat count, for drilling.
//
// WHY THIS DOES NOT REUSE InterleavedAudioService
// -----------------------------------------------
// That service exists to play a whole surah, in order, with a translation
// woven between the ayat and a lock-screen session attached to it. Every one
// of those is wrong here. A drill plays ONE ayah, several times, and stops —
// and it must be able to do that without disturbing whatever the main player
// was in the middle of.
//
// Bending the surah player into that shape would mean a mode flag threaded
// through its playlist building, its index subscription and its background
// session. A second, small, self-contained player is less code and cannot
// break the first one.
//
// TWO PLAYERS, ONE SPEAKER
// ------------------------
// Nothing in the audio stack stops two AudioPlayers sounding at once, so the
// caller is responsible for pausing the main player before a session starts.
// [HifzAudio.begin] does that, rather than leaving it to every screen to
// remember.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// EveryAyah reciter folders, keyed by the app's imam id.
///
/// Deliberately a copy of the map in InterleavedAudioService rather than a
/// shared constant: these are two independent consumers of a third-party
/// layout, and coupling them means a change made for one silently alters the
/// other. The fallback below covers every imam not listed.
const Map<int, String> _folders = <int, String>{
  1: 'Abdurrahmaan_As-Sudais_192kbps',
  2: 'Alafasy_128kbps',
  3: 'Yasser_Ad-Dussary_128kbps',
  4: 'MaherAlMuaiqly128kbps',
  5: 'Saood_ash-Shuraym_128kbps',
  8: 'Ali_Jaber_64kbps',
  9: 'Muhammad_Ayyoub_128kbps',
  10: 'Nasser_Alqatami_128kbps',
};

const String _fallbackFolder = 'Alafasy_128kbps';
const String _base = 'https://www.everyayah.com/data';

/// What the drill is doing right now.
enum HifzPlayState { idle, loading, playing, error }

class HifzAudio {
  HifzAudio();

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _stateSub;
  bool _disposed = false;

  /// Which ayah is loaded, so a repeat does not re-fetch.
  int? _surah;
  int? _ayah;
  int? _imamId;

  int _target = 1;
  int _done = 0;

  final ValueNotifier<HifzPlayState> state =
      ValueNotifier<HifzPlayState>(HifzPlayState.idle);

  /// How many repetitions have finished, for the "2 of 5" readout.
  final ValueNotifier<int> repetition = ValueNotifier<int>(0);

  /// Fires once the requested number of repetitions is complete.
  VoidCallback? onFinished;

  static String urlFor(int surah, int ayah, int imamId) {
    final folder = _folders[imamId] ?? _fallbackFolder;
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '$_base/$folder/$s$a.mp3';
  }

  /// Plays [surah]:[ayah] [times] times.
  ///
  /// Calling it again replaces whatever was running, so a fast tap through
  /// several ayat cannot leave two drills overlapping.
  Future<void> play({
    required int surah,
    required int ayah,
    required int imamId,
    required int times,
  }) async {
    if (_disposed) return;

    await stop();
    if (_disposed) return;

    _target = times.clamp(1, 10);
    _done = 0;
    repetition.value = 0;
    state.value = HifzPlayState.loading;

    try {
      final sameSource =
          _surah == surah && _ayah == ayah && _imamId == imamId;

      if (!sameSource) {
        await _player.setUrl(urlFor(surah, ayah, imamId));
        _surah = surah;
        _ayah = ayah;
        _imamId = imamId;
      } else {
        await _player.seek(Duration.zero);
      }

      if (_disposed) return;
      _listen();
      state.value = HifzPlayState.playing;
      await _player.play();
    } catch (e) {
      debugPrint('[Hifz] playback failed: $e');
      // A failed source must not be remembered as loaded, or the next attempt
      // would take the seek path and silently play nothing.
      _surah = null;
      _ayah = null;
      _imamId = null;
      if (!_disposed) state.value = HifzPlayState.error;
    }
  }

  void _listen() {
    _stateSub?.cancel();
    _stateSub = _player.playerStateStream.listen((s) {
      if (_disposed) return;
      if (s.processingState != ProcessingState.completed) return;

      _done++;
      repetition.value = _done;

      if (_done >= _target) {
        _stateSub?.cancel();
        _stateSub = null;
        state.value = HifzPlayState.idle;
        // Rewound so the next tap starts from the beginning rather than from
        // the end of the last repetition.
        _player.seek(Duration.zero);
        _player.pause();
        onFinished?.call();
        return;
      }

      // just_audio holds `completed` until the position moves, so seek first
      // and only then ask it to play again.
      _player.seek(Duration.zero).then((_) {
        if (!_disposed && state.value == HifzPlayState.playing) _player.play();
      });
    });
  }

  Future<void> stop() async {
    await _stateSub?.cancel();
    _stateSub = null;
    if (_disposed) return;
    try {
      await _player.pause();
      await _player.seek(Duration.zero);
    } catch (_) {
      // Pausing a player that never started is not an error.
    }
    if (!_disposed) {
      state.value = HifzPlayState.idle;
      repetition.value = 0;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _stateSub?.cancel();
    _stateSub = null;
    await _player.dispose();
    state.dispose();
    repetition.dispose();
  }
}
