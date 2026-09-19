import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/services/native_bridge_service.dart';

class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String apkUrl;
  final double apkSizeMb;
  final bool forceUpdate;
  final List<String> releaseNotes;

  AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.apkUrl,
    required this.apkSizeMb,
    required this.forceUpdate,
    required this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      versionCode: json['version_code'] as int? ?? 1,
      versionName: json['version_name'] as String? ?? '1.0.0',
      apkUrl: json['apk_url'] as String? ?? '',
      apkSizeMb: (json['apk_size_mb'] as num?)?.toDouble() ?? 0.0,
      forceUpdate: json['force_update'] as bool? ?? false,
      releaseNotes: (json['release_notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class AutoUpdateService {
  // Replace with your actual GitHub Raw or Firebase/Vercel URL for version.json
  static const String updateCheckUrl = 'https://raw.githubusercontent.com/cit-24-01-0476-maker/lingoflow/main/web/version.json';

  /// Checks if a newer version is available on the web server
  static Future<AppUpdateInfo?> checkForUpdate({String? customUrl}) async {
    try {
      final url = Uri.parse(customUrl ?? updateCheckUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updateInfo = AppUpdateInfo.fromJson(data);

        final currentCode = await NativeBridgeService.getAppVersionCode();
        if (updateInfo.versionCode > currentCode && updateInfo.apkUrl.isNotEmpty) {
          return updateInfo;
        }
      }
    } catch (e) {
      // Network offline or custom URL unconfigured
    }
    return null;
  }

  /// Initiates download and invokes Android Package Installer
  static Future<void> triggerUpdate(String apkUrl) async {
    await NativeBridgeService.downloadAndInstallApk(apkUrl);
  }
}
