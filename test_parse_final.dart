import 'dart:convert';
import 'dart:io';

void main() async {
  final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim.min.json';
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  
  final Map<String, dynamic> json = jsonDecode(stringData) as Map<String, dynamic>;
  final hadithsRaw = json['hadiths'] as List<dynamic>;
  
  int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return double.tryParse(val)?.toInt() ?? 0;
      return 0;
  }
  
  int count = 0;
  for (var i = 0; i < hadithsRaw.length; i++) {
        final e = hadithsRaw[i] as Map<String, dynamic>;
        final ref = e['reference'] as Map<String, dynamic>? ?? {};
        
        try {
            parseInt(e['hadithnumber']);
            parseInt(e['arabicnumber']);
            parseInt(ref['book']);
            parseInt(ref['hadith']);
            count++;
        } catch(err) {
            print("Error at index $i: $err");
            break;
        }
  }
  print("Parsed $count / ${hadithsRaw.length} hadiths successfully.");
}
