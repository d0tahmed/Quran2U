
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String releaseUrl;

  const UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.releaseUrl,
  });
}

class UpdateService {
  final Dio _dio;
  
  UpdateService(this._dio);

  Future<UpdateInfo> checkForUpdate() async {
    String currentVersionStr = 'Unknown';
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      currentVersionStr = pkgInfo.version;
      
      final response = await _dio.get(
        'https://api.github.com/repos/d0tahmed/Quran2U/releases/latest',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String tagName = data['tag_name'] as String;
        
        if (tagName.toLowerCase().startsWith('v')) {
          tagName = tagName.substring(1);
        }

        final currentVersion = Version.parse(currentVersionStr);
        final latestVersion = Version.parse(tagName);

        return UpdateInfo(
          isUpdateAvailable: latestVersion > currentVersion,
          latestVersion: tagName,
          currentVersion: currentVersionStr,
          releaseNotes: data['body'] as String? ?? 'A new version is available.',
          releaseUrl: data['html_url'] as String? ?? 'https://github.com/d0tahmed/Quran2U/releases',
        );
      }
    } catch (e) {
      // Silently fail if unable to check for update.
    }
    
    return UpdateInfo(
      isUpdateAvailable: false,
      latestVersion: '',
      currentVersion: currentVersionStr,
      releaseNotes: '',
      releaseUrl: '',
    );
  }
}
