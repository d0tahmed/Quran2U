import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_recitation/models/hadith_model.dart';
import 'package:quran_recitation/services/hadith_service.dart';

/// Global provider for the user's selected Hadith language.
final hadithLanguageProvider = StateProvider<HadithLanguage>((ref) {
  return HadithLanguage.english;
});

// A unique key for requesting sections
typedef HadithSectionsRequest = ({HadithCollection collection, HadithLanguage language});

/// Provider for loading all sections of a specific book
final hadithSectionsProvider = FutureProvider.autoDispose.family<List<HadithSection>, HadithSectionsRequest>((ref, request) async {
  return await HadithService.fetchBookSections(request.collection, request.language);
});

// A unique key for requesting hadiths within a specific section
typedef HadithListRequest = ({HadithCollection collection, int sectionNumber, HadithLanguage language});

/// Provider for loading all hadiths within a specific section
final hadithListProvider = FutureProvider.autoDispose.family<List<HadithEntry>, HadithListRequest>((ref, request) async {
  return await HadithService.fetchHadithsForSection(request.collection, request.sectionNumber, request.language);
});
