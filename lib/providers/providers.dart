import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/services/quran_api_service.dart';
import 'package:quran_recitation/services/audio_player_service.dart';
import 'package:quran_recitation/services/interleaved_audio_service.dart';
import 'package:quran_recitation/services/download_service.dart';
import 'package:quran_recitation/services/mushaf_api_service.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';

// ── Core services ─────────────────────────────────────────────────────────────
final quranApiServiceProvider = Provider((ref) => QuranApiService());

final audioPlayerServiceProvider = Provider((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final interleavedAudioServiceProvider = Provider((ref) {
  final service = InterleavedAudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final downloadServiceProvider = Provider((ref) => DownloadService());

// ── Playback mode ─────────────────────────────────────────────────────────────
final tarjumahModeProvider = StateProvider<bool>((ref) => false);

// Checks if Tarjumah is allowed. Returns false ONLY for Baleelah (6) and Badr Al-Turki (7).
final isTarjumahSupportedProvider = Provider<bool>((ref) {
  final imam = ref.watch(selectedImamProvider);
  return imam?.id != 6 && imam?.id != 7; 
});

final loopProvider = StateProvider<bool>((ref) => false);

// ── Ayah tracking (interleaved tarjumah) ──────────────────────────────────────
final currentAyahNumberProvider = StreamProvider<int?>((ref) async* {
  final svc = ref.watch(interleavedAudioServiceProvider);
  yield* svc.currentAyahStream;
});

final isUrduSegmentProvider = StreamProvider<bool>((ref) async* {
  final svc = ref.watch(interleavedAudioServiceProvider);
  yield* svc.isUrduSegmentStream;
});

// ── Surah list ────────────────────────────────────────────────────────────────
final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final quranApi = ref.watch(quranApiServiceProvider);
  return quranApi.fetchAllSurahs();
});

// ── Translation ───────────────────────────────────────────────────────────────
final selectedTranslationProvider = StateProvider<int>((ref) => 0);

final surahAyahsProvider =
    FutureProvider.family<List<Ayah>, (int, int)>((ref, params) async {
  final (surahNumber, translationId) = params;
  final apiService = ref.watch(quranApiServiceProvider);
  final data = await apiService.fetchSurahWithAyahs(surahNumber,
      translationId: translationId);
  return data['ayahs'] ?? [];
});

// Updated Imams list with the exact server URL spelling for Ayyoub
final imamsProvider = Provider<List<Imam>>((ref) {
  return const [
    Imam(id: 1, name: 'Sheikh Abdul Rahman As-Sudais', identifier: 'https://server11.mp3quran.net/sds', country: 'Saudi Arabia'),
    Imam(id: 3, name: 'Sheikh Yasser Ad-Dusari', identifier: 'https://server11.mp3quran.net/yasser', country: 'Saudi Arabia'),
    Imam(id: 4, name: 'Sheikh Mahir Al-Muaqily', identifier: 'https://server12.mp3quran.net/maher', country: 'Saudi Arabia'),
    Imam(id: 5, name: 'Sheikh Saud As-Shuraim', identifier: 'https://server7.mp3quran.net/shur', country: 'Saudi Arabia'),
    Imam(id: 8, name: 'Sheikh Ali Jabir', identifier: 'https://server11.mp3quran.net/a_jbr', country: 'Saudi Arabia'),
    Imam(id: 2, name: 'Sheikh Mishary Rashid Alafasy', identifier: 'https://server8.mp3quran.net/afs', country: 'Kuwait'),
    Imam(id: 6, name: 'Sheikh Bandar Al-Balilah', identifier: 'https://server6.mp3quran.net/balilah', country: 'Saudi Arabia'),
    
    // ── NEW RECITERS ──
    Imam(id: 10, name: 'Sheikh Nasser Al-Qatami', identifier: 'https://server6.mp3quran.net/qtm', country: 'Saudi Arabia'),
    // FIX: Changed /ayu to /ayyub
    Imam(id: 9, name: 'Sheikh Muhammad Ayyoub', identifier: 'https://server8.mp3quran.net/ayyub', country: 'Saudi Arabia'),
    // Badr Al-Turki (No Tarjumah support)
    Imam(id: 7, name: 'Sheikh Badr Al-Turki', identifier: 'https://server10.mp3quran.net/bader/Rewayat-Hafs-A-n-Assem', country: 'Saudi Arabia'),
  ];
});

final selectedImamProvider = StateProvider<Imam?>((ref) {
  final imams = ref.watch(imamsProvider);
  return imams.isNotEmpty ? imams.first : null;
});

// ── Audio URL builder ─────────────────────────────────────────────────────────
final audioUrlProvider = Provider.family<String, (int, int)>((ref, params) {
  final (surahNumber, imamId) = params;
  final imams = ref.watch(imamsProvider);
  final selectedImam = imams.firstWhere(
    (imam) => imam.id == imamId,
    orElse: () => imams.isNotEmpty
        ? imams[0]
        : const Imam(id: 1, name: 'Default', identifier: 'https://server11.mp3quran.net/sds', country: ''),
  );
  final paddedSurah = surahNumber.toString().padLeft(3, '0');
  return '${selectedImam.identifier}/$paddedSurah.mp3';
});

// ── Current surah ─────────────────────────────────────────────────────────────
final currentSurahProvider = StateProvider<int?>((ref) => null);

final playbackStateProvider = StreamProvider<PlaybackState?>((ref) async* {
  final audioPlayer   = ref.watch(audioPlayerServiceProvider);
  final selectedSurah = ref.watch(currentSurahProvider);
  yield* audioPlayer.playerStateStream.asyncMap((_) {
    return Future.value(audioPlayer.getCurrentState(selectedSurah ?? 1));
  });
});

final currentPlayerStateProvider = StreamProvider<PlayerState>((ref) async* {
  final tarjumahMode = ref.watch(tarjumahModeProvider);
  if (tarjumahMode) {
    yield* ref.watch(interleavedAudioServiceProvider).playerStateStream;
  } else {
    yield* ref.watch(audioPlayerServiceProvider).playerStateStream;
  }
});

// ── Position / Duration streams ───────────────────────────────────────────────
final positionProvider = StreamProvider<Duration>((ref) async* {
  final tarjumahMode = ref.watch(tarjumahModeProvider);
  if (tarjumahMode) {
    yield* ref.watch(interleavedAudioServiceProvider).positionStream;
  } else {
    yield* ref.watch(audioPlayerServiceProvider).positionStream;
  }
});

final durationProvider = StreamProvider<Duration?>((ref) async* {
  final tarjumahMode = ref.watch(tarjumahModeProvider);
  if (tarjumahMode) {
    yield* ref.watch(interleavedAudioServiceProvider).durationStream;
  } else {
    yield* ref.watch(audioPlayerServiceProvider).durationStream;
  }
});

// ── Bookmarks ────────────────────────────────────────────────────────────────
class BookmarksNotifier extends StateNotifier<List<Bookmark>> {
  static const _key = 'bookmarks_v1';

  BookmarksNotifier() : super([]) { _load(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        state = list.map((e) => Bookmark.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }

  void updateBookmarks(List<Bookmark> newList) {
    state = newList;
    _save();
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<Bookmark>>((ref) => BookmarksNotifier());

// ── Downloads ─────────────────────────────────────────────────────────────────
final downloadedSurahsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(downloadServiceProvider).getDownloadedSurahs();
});

class BulkDownloadState {
  final bool isDownloading;
  final double progress;
  final double overallProgress;
  final int currentSurah;
  final String status;
  final int? _imamId;
  final bool _withTarjumah;

  const BulkDownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.overallProgress = 0.0,
    this.currentSurah = 0,
    this.status = '',
    int? imamId,
    bool withTarjumah = false,
  })  : _imamId = imamId, _withTarjumah = withTarjumah;

  BulkDownloadState copyWith({
    bool? isDownloading, double? progress, double? overallProgress,
    int? currentSurah, String? status, int? imamId, bool? withTarjumah,
  }) {
    return BulkDownloadState(
      isDownloading:   isDownloading   ?? this.isDownloading,
      progress:        progress        ?? this.progress,
      overallProgress: overallProgress ?? this.overallProgress,
      currentSurah:    currentSurah    ?? this.currentSurah,
      status:          status          ?? this.status,
      imamId:          imamId          ?? _imamId,
      withTarjumah:    withTarjumah    ?? _withTarjumah,
    );
  }
}

class BulkDownloadNotifier extends StateNotifier<BulkDownloadState> {
  final Ref _ref;
  BulkDownloadNotifier(this._ref) : super(const BulkDownloadState());

  Future<void> start({required int imamId, required String imamIdentifier, required bool withTarjumah}) async {
    if (state.isDownloading) return;
    state = BulkDownloadState(isDownloading: true, status: 'Starting download…', currentSurah: 1, imamId: imamId, withTarjumah: withTarjumah);
    await _ref.read(downloadServiceProvider).downloadEntireQuran(
      imamId: imamId, imamIdentifier: imamIdentifier, withTarjumah: withTarjumah,
      onProgress: (surah, totalSurahs, surahProgress, status) {
        if (!mounted) return;
        state = state.copyWith(currentSurah: surah, overallProgress: (surah - 1 + surahProgress) / 114, progress: surahProgress, status: status);
      },
      onError: (e) {
        if (!mounted) return;
        state = const BulkDownloadState();
      },
      onComplete: () {
        if (!mounted) return;
        state = const BulkDownloadState();
        _ref.invalidate(downloadedSurahsProvider);
      },
    );
  }

  void cancel() {
    final imamId = state._imamId;
    final withTarjumah = state._withTarjumah;
    if (imamId != null) {
      _ref.read(downloadServiceProvider).cancelBulkDownload(imamId, withTarjumah);
    }
    state = const BulkDownloadState();
  }
}

final bulkDownloadProvider = StateNotifierProvider<BulkDownloadNotifier, BulkDownloadState>((ref) => BulkDownloadNotifier(ref));

// ── Namaz & Qibla ─────────────────────────────────────────────
final locationProvider = FutureProvider<Coordinates>((ref) async {
  final fallback = Coordinates(24.8607, 67.0011); 
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return fallback;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return fallback;
    }
    if (perm == LocationPermission.deniedForever) return fallback;
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    return Coordinates(pos.latitude, pos.longitude);
  } catch (_) {
    return fallback;
  }
});

final prayerTimesProvider = FutureProvider<PrayerTimes>((ref) async {
  final coords = await ref.watch(locationProvider.future);
  final params = CalculationMethod.karachi.getParameters()..madhab = Madhab.hanafi;
  return PrayerTimes.today(coords, params);
});

// ── Mushaf ─────────────────────────────────────────────────────
final mushafApiServiceProvider = Provider((ref) => MushafApiService());

final mushafPageProvider = FutureProvider.family<String, (int, String)>((ref, params) async {
  final (page, script) = params;
  return ref.watch(mushafApiServiceProvider).getPageText(page, script);
});

final tajweedPageProvider = FutureProvider.family<List<Map<String, String>>, int>((ref, page) async {
  return ref.watch(mushafApiServiceProvider).getPageTajweedData(page);
});