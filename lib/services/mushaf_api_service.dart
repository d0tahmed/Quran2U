import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MushafApiService {
  final Dio _dio = Dio();

  Future<String> getPageText(int pageNumber, String scriptType) async {
    final cacheKey = 'mushaf_${scriptType}_page_$pageNumber';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
      return prefs.getString(cacheKey)!;
    }

    try {
      final url = 'https://api.quran.com/api/v4/quran/verses/$scriptType?page_number=$pageNumber';
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final verses = response.data['verses'] as List;
        final textKey = 'text_$scriptType';
        
        final pageText = verses.map((v) {
          final text = v[textKey].toString();
          final ayahNum = v['verse_key'].toString().split(':')[1];
          return '$text ﴿${_convertToArabicNumber(ayahNum)}﴾';
        }).join('  ');
        
        await prefs.setString(cacheKey, pageText);
        return pageText;
      }
      return 'Error loading page data.';
    } catch (e) {
      return 'Offline: Please connect to the internet to download this page for the first time.';
    }
  }

  /// Returns raw tajweed-encoded HTML for a mushaf page.
  /// Each entry: { 'verse_key': '1:1', 'text': '<tajweed ...>...</tajweed>' }
  Future<List<Map<String, String>>> getPageTajweedData(int pageNumber) async {
    final cacheKey = 'mushaf_tajweed_raw_page_$pageNumber';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
      final cached = prefs.getString(cacheKey)!;
      final list = (jsonDecode(cached) as List)
          .map((e) => Map<String, String>.from(e))
          .toList();
      return list;
    }

    try {
      final url =
          'https://api.quran.com/api/v4/quran/verses/uthmani_tajweed?page_number=$pageNumber';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final verses = response.data['verses'] as List;
        final result = verses.map<Map<String, String>>((v) {
          return {
            'verse_key': v['verse_key'].toString(),
            'text': v['text_uthmani_tajweed'].toString(),
          };
        }).toList();

        await prefs.setString(cacheKey, jsonEncode(result));
        return result;
      }
      return [];
    } catch (e) {
      throw Exception('Offline: Connect to the internet to load Tajweed page.');
    }
  }

  String _convertToArabicNumber(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}