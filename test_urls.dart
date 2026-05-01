// ignore_for_file: avoid_print, prefer_const_declarations, unused_local_variable, unused_import
import 'dart:io';

const _everyayahFolders = <int, String>{
  1: 'Abdurrahmaan_As-Sudais_192kbps',
  2: 'Alafasy_128kbps',
  3: 'Yasser_Ad-Dussary_128kbps',
  4: 'MaherAlMuaiqly128kbps',
  5: 'Saood_ash-Shuraym_128kbps',
};

const _urduFolder = 'translations/urdu_shamshad_ali_khan_46kbps';
const _everyayahBase = 'https://everyayah.com/data';

Future<void> main() async {
  final client = HttpClient();
  
  // Test Sudais (id 1) Surah 1 Ayah 1
  final s = '1'.padLeft(3, '0');
  final a = '1'.padLeft(3, '0');
  final sudaisUrl = '$_everyayahBase/${_everyayahFolders[1]}/$s$a.mp3';
  
  print('Testing: $sudaisUrl');
  try {
    final req = await client.headUrl(Uri.parse(sudaisUrl));
    final res = await req.close();
    print('  Status: ${res.statusCode}');
  } catch (e) {
    print('  Error: $e');
  }

  // Test Shuraim (id 5)
  final shuraimUrl = '$_everyayahBase/${_everyayahFolders[5]}/$s$a.mp3';
  print('Testing: $shuraimUrl');
  try {
    final req = await client.headUrl(Uri.parse(shuraimUrl));
    final res = await req.close();
    print('  Status: ${res.statusCode}');
  } catch (e) {
    print('  Error: $e');
  }
  
  // Test Shamshad Ali Khan
  final urduUrl = '$_everyayahBase/$_urduFolder/$s$a.mp3';
  print('Testing: $urduUrl');
  try {
    final req = await client.headUrl(Uri.parse(urduUrl));
    final res = await req.close();
    print('  Status: ${res.statusCode}');
  } catch (e) {
    print('  Error: $e');
  }
  
  client.close();
}
