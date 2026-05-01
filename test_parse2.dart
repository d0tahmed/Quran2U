// ignore_for_file: avoid_print, prefer_const_declarations, unused_local_variable, unused_import
import 'dart:convert';
import 'dart:io';

void main() async {
  final url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-muslim.min.json';
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  
  final Map<String, dynamic> json = jsonDecode(stringData) as Map<String, dynamic>;
  final hadithsRaw = json['hadiths'] as List<dynamic>;
  
  for (var i = 0; i < hadithsRaw.length; i++) {
        final e = hadithsRaw[i] as Map<String, dynamic>;
        final ref = e['reference'] as Map<String, dynamic>? ?? {};
        
        try { e['hadithnumber'] as num?; } catch(err) { print("Index $i hadithnumber error: ${e['hadithnumber']} is ${e['hadithnumber'].runtimeType}"); }
        try { e['arabicnumber'] as num?; } catch(err) { print("Index $i arabicnumber error: ${e['arabicnumber']} is ${e['arabicnumber'].runtimeType}"); }
        try { e['text'] as String?; } catch(err) { print("Index $i text error: ${e['text']} is ${e['text'].runtimeType}"); }
        try { ref['book'] as num?; } catch(err) { print("Index $i book error: ${ref['book']} is ${ref['book'].runtimeType}"); }
        try { ref['hadith'] as num?; } catch(err) { print("Index $i hadith error: ${ref['hadith']} is ${ref['hadith'].runtimeType}"); }
        
        if (i == 95) break;
  }
}
