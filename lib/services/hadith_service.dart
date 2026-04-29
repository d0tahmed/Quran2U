import 'package:quran_recitation/models/hadith_model.dart';
import 'package:quran_recitation/services/database_helper.dart';

class HadithService {
  /// Fetches all sections for a specific book/collection in the given language.
  static Future<List<HadithSection>> fetchBookSections(HadithCollection collection, HadithLanguage language) async {
    final db = await DatabaseHelper.database;
    final bookId = collection.name; // enum name matches the id in DB

    final List<Map<String, dynamic>> rows = await db.query(
      'sections',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'section_number ASC',
    );

    return rows.map((row) => HadithSection.fromDb(row, language)).toList();
  }

  /// Fetches all hadiths for a specific section within a book.
  static Future<List<HadithEntry>> fetchHadithsForSection(
    HadithCollection collection,
    int sectionNumber,
    HadithLanguage language,
  ) async {
    final db = await DatabaseHelper.database;
    final bookId = collection.name;

    final List<Map<String, dynamic>> rows = await db.query(
      'hadiths',
      where: 'book_id = ? AND section_number = ?',
      whereArgs: [bookId, sectionNumber],
      orderBy: 'hadith_number ASC',
    );

    return rows.map((row) => HadithEntry.fromDb(row, language)).toList();
  }
}
