import json

def generate_dart_file(json_file, output_file):
    with open(json_file, 'r', encoding='utf-8') as f:
        duas = json.load(f)

    dart_content = """import '../models/dua.dart';

class HisnulMuslimDb {
  static const List<Dua> duas = [
"""
    
    for idx, d in enumerate(duas):
        # Escape characters for Dart strings
        arabic = d['arabic'].replace("'", "\\'").replace("$", "\\$")
        translit = d['transliteration'].replace("'", "\\'").replace("$", "\\$")
        eng = d['englishTranslation'].replace("'", "\\'").replace("$", "\\$")
        ref = d['reference'].replace("'", "\\'").replace("$", "\\$")
        title = d['title'].replace("'", "\\'").replace("$", "\\$")
        cat = d['category'].replace("'", "\\'").replace("$", "\\$")
        
        urdu = ''
        
        dart_content += f"""    Dua(
      id: {idx+1},
      category: '{cat}',
      title: '{title}',
      arabic: '{arabic}',
      transliteration: '{translit}',
      englishTranslation: '{eng}',
      urduTranslation: '{urdu}',
      reference: '{ref}',
    ),
"""
    
    dart_content += """  ];
}
"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(dart_content)

if __name__ == "__main__":
    generate_dart_file('parsed_duas.json', 'lib/data/hisnul_muslim_db.dart')
