import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

String _recKey(int surah, int imam) => 'dl_rec_${surah}_$imam';
String _urduKey(int surah, int imam) => 'dl_urdu_${surah}_$imam';

class DownloadService {
  final _dio = Dio();
  final Map<String, CancelToken> _tokens = {};

  // SENIOR FIX: Cache the directory so we don't spam the OS and lag the UI!
  Directory? _cachedBaseDir;

  Future<Directory> _baseDir() async {
    _cachedBaseDir ??= await getApplicationDocumentsDirectory();
    return _cachedBaseDir!;
  }

  Future<String> _recitationPath(int surah, int imam) async {
    final base = await _baseDir();
    final dir = Directory('${base.path}/downloads/recitation/$imam');
    if (!dir.existsSync()) await dir.create(recursive: true);
    final padded = surah.toString().padLeft(3, '0');
    return '${dir.path}/$padded.mp3';
  }

  Future<String> _arabicAyahPath(int surah, int ayah, int imam) async {
    final base = await _baseDir();
    final dir = Directory('${base.path}/downloads/arabic/$imam/$surah');
    if (!dir.existsSync()) await dir.create(recursive: true);
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '${dir.path}/$s$a.mp3';
  }

  Future<String> _urduAyahPath(int surah, int ayah) async {
    final base = await _baseDir();
    final dir = Directory('${base.path}/downloads/urdu/$surah');
    if (!dir.existsSync()) await dir.create(recursive: true);
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return '${dir.path}/$s$a.mp3';
  }

  Future<bool> isRecitationDownloaded(int surah, int imam) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_recKey(surah, imam)) != true) return false;
    final path = await _recitationPath(surah, imam);
    return File(path).existsSync();
  }

  Future<bool> isTarjumahDownloaded(int surah, int imam) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_urduKey(surah, imam)) == true;
  }

  Future<String?> getLocalRecitationPath(int surah, int imam) async {
    if (!await isRecitationDownloaded(surah, imam)) return null;
    return _recitationPath(surah, imam);
  }

  Future<String?> getLocalArabicAyahPath(int surah, int ayah, int imam) async {
    final path = await _arabicAyahPath(surah, ayah, imam);
    return File(path).existsSync() ? path : null;
  }

  Future<String?> getLocalUrduAyahPath(int surah, int ayah, int imam) async {
    final path = await _urduAyahPath(surah, ayah);
    return File(path).existsSync() ? path : null;
  }

  bool isDownloading(int surah, int imam) => _tokens.containsKey('${surah}_$imam');

  Future<void> downloadRecitation({
    required int surahNumber,
    required int imamId,
    required String imamIdentifier,
    required void Function(double progress) onProgress,
    required void Function(String error) onError,
    required void Function() onComplete,
  }) async {
    final key = '${surahNumber}_$imamId';
    if (_tokens.containsKey(key)) return;

    final token = CancelToken();
    _tokens[key] = token;

    try {
      final padded = surahNumber.toString().padLeft(3, '0');
      final url = '$imamIdentifier/$padded.mp3';
      final path = await _recitationPath(surahNumber, imamId);

      await _dio.download(
        url, path,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_recKey(surahNumber, imamId), true);
      onComplete();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      onError(e.message ?? 'Download failed');
      try {
        final path = await _recitationPath(surahNumber, imamId);
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    } catch (e) {
      onError(e.toString());
    } finally {
      _tokens.remove(key);
    }
  }

  Future<void> downloadWithTarjumah({
    required int surahNumber,
    required int imamId,
    required int ayahCount,
    required void Function(double progress, String status) onProgress,
    required void Function(String error) onError,
    required void Function() onComplete,
  }) async {
    final key = '${surahNumber}_$imamId';
    if (_tokens.containsKey(key)) return;

    final token = CancelToken();
    _tokens[key] = token;

    final arabicFolder = _everyayahFolders[imamId] ?? _arabicFallbackFolder;
    final totalFiles = ayahCount * 2;
    int downloaded = 0;

    try {
      for (int ayah = 1; ayah <= ayahCount; ayah++) {
        if (token.isCancelled) return;

        final s = surahNumber.toString().padLeft(3, '0');
        final a = ayah.toString().padLeft(3, '0');

        final arabicUrl = '$_everyayahBase/$arabicFolder/$s$a.mp3';
        final arabicPath = await _arabicAyahPath(surahNumber, ayah, imamId);
        if (!File(arabicPath).existsSync()) {
          await _dio.download(arabicUrl, arabicPath, cancelToken: token);
        }
        downloaded++;
        onProgress(downloaded / totalFiles, 'Arabic $ayah/$ayahCount');

        if (token.isCancelled) return;

        final urduUrl = '$_everyayahBase/$_urduFolder/$s$a.mp3';
        final urduPath = await _urduAyahPath(surahNumber, ayah);
        if (!File(urduPath).existsSync()) {
          await _dio.download(urduUrl, urduPath, cancelToken: token);
        }
        downloaded++;
        onProgress(downloaded / totalFiles, 'Urdu $ayah/$ayahCount');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_urduKey(surahNumber, imamId), true);
      onComplete();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      onError(e.message ?? 'Download failed');
    } catch (e) {
      onError(e.toString());
    } finally {
      _tokens.remove(key);
    }
  }

  void cancelDownload(int surah, int imam) {
    final key = '${surah}_$imam';
    _tokens[key]?.cancel('User cancelled');
    _tokens.remove(key);
  }

  Future<void> deleteDownload(int surah, int imam) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final path = await _recitationPath(surah, imam);
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}

    try {
      final base = await _baseDir();
      final arabicDir = Directory('${base.path}/downloads/arabic/$imam/$surah');
      if (arabicDir.existsSync()) arabicDir.deleteSync(recursive: true);
      final urduDir = Directory('${base.path}/downloads/urdu/$surah');
      if (urduDir.existsSync()) urduDir.deleteSync(recursive: true);
    } catch (_) {}

    await prefs.remove(_recKey(surah, imam));
    await prefs.remove(_urduKey(surah, imam));
  }

  Future<List<Map<String, dynamic>>> getDownloadedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final results = <Map<String, dynamic>>[];

    final recKeys = keys.where((k) => k.startsWith('dl_rec_'));
    for (final k in recKeys) {
      if (prefs.getBool(k) != true) continue;
      final parts = k.replaceFirst('dl_rec_', '').split('_');
      if (parts.length != 2) continue;
      final surah = int.tryParse(parts[0]);
      final imam = int.tryParse(parts[1]);
      if (surah == null || imam == null) continue;
      final hasUrdu = prefs.getBool(_urduKey(surah, imam)) == true;
      results.add({'surahNumber': surah, 'imamId': imam, 'hasUrdu': hasUrdu});
    }

    final urduKeys = keys.where((k) => k.startsWith('dl_urdu_'));
    for (final k in urduKeys) {
      if (prefs.getBool(k) != true) continue;
      final parts = k.replaceFirst('dl_urdu_', '').split('_');
      if (parts.length != 2) continue;
      final surah = int.tryParse(parts[0]);
      final imam = int.tryParse(parts[1]);
      if (surah == null || imam == null) continue;
      if (!results.any((r) => r['surahNumber'] == surah && r['imamId'] == imam)) {
        results.add({'surahNumber': surah, 'imamId': imam, 'hasUrdu': true});
      }
    }

    results.sort((a, b) => (a['surahNumber'] as int).compareTo(b['surahNumber'] as int));
    return results;
  }

  Future<int> getDownloadSizeBytes(int surah, int imam) async {
    int total = 0;
    try {
      final base = await _baseDir();
      final recPath = await _recitationPath(surah, imam);
      final recFile = File(recPath);
      if (recFile.existsSync()) total += recFile.lengthSync();

      final arabicDir = Directory('${base.path}/downloads/arabic/$imam/$surah');
      if (arabicDir.existsSync()) {
        for (final f in arabicDir.listSync()) {
          if (f is File) total += f.lengthSync();
        }
      }
      final urduDir = Directory('${base.path}/downloads/urdu/$surah');
      if (urduDir.existsSync()) {
        for (final f in urduDir.listSync()) {
          if (f is File) total += f.lengthSync();
        }
      }
    } catch (_) {}
    return total;
  }


  // ─── Surah ayah counts — hardcoded so bulk download needs no API call ─────
  static const _ayahCounts = <int, int>{
    1:7,2:286,3:200,4:176,5:120,6:165,7:206,8:75,9:129,10:109,
    11:123,12:111,13:43,14:52,15:99,16:128,17:111,18:110,19:98,20:135,
    21:112,22:78,23:118,24:64,25:77,26:227,27:93,28:88,29:69,30:60,
    31:34,32:30,33:73,34:54,35:45,36:83,37:182,38:88,39:75,40:85,
    41:54,42:53,43:89,44:59,45:37,46:35,47:38,48:29,49:18,50:45,
    51:60,52:49,53:62,54:55,55:78,56:96,57:29,58:22,59:24,60:13,
    61:14,62:11,63:11,64:18,65:12,66:12,67:30,68:52,69:52,70:44,
    71:28,72:28,73:20,74:56,75:40,76:31,77:50,78:40,79:46,80:42,
    81:29,82:19,83:36,84:25,85:22,86:17,87:19,88:26,89:30,90:20,
    91:15,92:21,93:11,94:8,95:8,96:19,97:5,98:8,99:8,100:11,
    101:11,102:8,103:3,104:9,105:5,106:4,107:7,108:3,109:6,110:3,
    111:5,112:4,113:5,114:6,
  };

  static const _bulkKey = 'bulk_dl';

  // ─── Bulk download entire Quran ────────────────────────────────────────────
  Future<void> downloadEntireQuran({
    required int imamId,
    required String imamIdentifier,
    required bool withTarjumah,
    required void Function(int surah, int totalSurahs, double surahProgress, String status) onProgress,
    required void Function(String error) onError,
    required void Function() onComplete,
  }) async {
    final bulkKey = '${_bulkKey}_${imamId}_${withTarjumah ? 'tarjumah' : 'rec'}';
    if (_tokens.containsKey(bulkKey)) return;

    final token = CancelToken();
    _tokens[bulkKey] = token;

    try {
      for (int surah = 1; surah <= 114; surah++) {
        if (token.isCancelled) return;

        final ayahCount = _ayahCounts[surah] ?? 7;

        if (withTarjumah) {
          // Skip if already downloaded
          final alreadyDone = await isTarjumahDownloaded(surah, imamId);
          if (!alreadyDone) {
            final arabicFolder = _everyayahFolders[imamId] ?? _arabicFallbackFolder;
            final totalFiles = ayahCount * 2;
            int dlCount = 0;

            for (int ayah = 1; ayah <= ayahCount; ayah++) {
              if (token.isCancelled) return;
              final s = surah.toString().padLeft(3, '0');
              final a = ayah.toString().padLeft(3, '0');

              final arabicPath = await _arabicAyahPath(surah, ayah, imamId);
              if (!File(arabicPath).existsSync()) {
                await _dio.download('$_everyayahBase/$arabicFolder/$s$a.mp3', arabicPath, cancelToken: token);
              }
              dlCount++;
              onProgress(surah, 114, dlCount / totalFiles, 'Surah $surah — Arabic $ayah/$ayahCount');

              if (token.isCancelled) return;

              final urduPath = await _urduAyahPath(surah, ayah);
              if (!File(urduPath).existsSync()) {
                await _dio.download('$_everyayahBase/$_urduFolder/$s$a.mp3', urduPath, cancelToken: token);
              }
              dlCount++;
              onProgress(surah, 114, dlCount / totalFiles, 'Surah $surah — Urdu $ayah/$ayahCount');
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_recKey(surah, imamId), true);
            await prefs.setBool(_urduKey(surah, imamId), true);
          } else {
            onProgress(surah, 114, 1.0, 'Surah $surah — Already downloaded');
          }
        } else {
          // Recitation only
          final alreadyDone = await isRecitationDownloaded(surah, imamId);
          if (!alreadyDone) {
            final padded = surah.toString().padLeft(3, '0');
            final path = await _recitationPath(surah, imamId);
            await _dio.download(
              '$imamIdentifier/$padded.mp3', path,
              cancelToken: token,
              onReceiveProgress: (r, t) {
                if (t > 0) onProgress(surah, 114, r / t, 'Surah $surah');
              },
            );
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_recKey(surah, imamId), true);
          } else {
            onProgress(surah, 114, 1.0, 'Surah $surah — Already downloaded');
          }
        }
      }
      onComplete();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      onError(e.message ?? 'Download failed');
    } catch (e) {
      onError(e.toString());
    } finally {
      _tokens.remove(bulkKey);
    }
  }

  bool isBulkDownloading(int imamId, bool withTarjumah) {
    final key = '${_bulkKey}_${imamId}_${withTarjumah ? 'tarjumah' : 'rec'}';
    return _tokens.containsKey(key);
  }

  void cancelBulkDownload(int imamId, bool withTarjumah) {
    final key = '${_bulkKey}_${imamId}_${withTarjumah ? 'tarjumah' : 'rec'}';
    _tokens[key]?.cancel('User cancelled');
    _tokens.remove(key);
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}