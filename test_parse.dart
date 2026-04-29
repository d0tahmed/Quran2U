import 'dart:convert';
import 'dart:io';

void main() async {
  final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim.min.json';
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  print("Downloaded ${stringData.length} bytes");
  
  try {
    final Map<String, dynamic> json = jsonDecode(stringData) as Map<String, dynamic>;

    final meta     = json['metadata'] as Map<String, dynamic>;
    final bookName = (meta['name'] as String?) ?? 'Muslim';

    final sectionsRaw = meta['sections']       as Map<String, dynamic>;
    final detailsRaw  = meta['section_details'] as Map<String, dynamic>;

    print("Sections count: ${sectionsRaw.length}");
    
    int sectionCount = 0;
    for (final entry in sectionsRaw.entries) {
      final key  = entry.key;
      final name = (entry.value as String?) ?? '';
      if (name.isEmpty) continue;

      final details = detailsRaw[key] as Map<String, dynamic>?;
      final first   = (details?['hadithnumber_first'] as num?)?.toInt() ?? 0;
      final last    = (details?['hadithnumber_last']  as num?)?.toInt() ?? 0;
      if (first == 0 && last == 0) continue;
      sectionCount++;
    }
    print("Valid sections: $sectionCount");

    final hadithsRaw = json['hadiths'] as List<dynamic>;
    print("Hadiths count: ${hadithsRaw.length}");
    
    int hadithCount = 0;
    for (var i = 0; i < hadithsRaw.length; i++) {
        final e = hadithsRaw[i] as Map<String, dynamic>;
        try {
            final ref = e['reference'] as Map<String, dynamic>? ?? {};
            final hadithNumber = (e['hadithnumber'] as num?)?.toInt() ?? 0;
            final arabicNumber = (e['arabicnumber'] as num?)?.toInt() ?? 0;
            final text         = (e['text']         as String?) ?? '';
            final bookNumber   = (ref['book']       as num?)?.toInt() ?? 0;
            final hadithInBook = (ref['hadith']     as num?)?.toInt() ?? 0;
            hadithCount++;
        } catch (err) {
            print("Error parsing hadith at index $i: $err");
            print("Hadith data: $e");
            break;
        }
    }
    print("Valid hadiths parsed: $hadithCount");
    print("Success!");

  } catch (e, stack) {
    print("Parse error: $e");
    print(stack);
  }
}
