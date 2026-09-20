import 'dart:convert';
import 'dart:io';
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
  static const String updateCheckUrl = 'https://raw.githubusercontent.com/cit-24-01-0476-maker/lingoflow/main/docs/version.json';

  /// Checks if a newer version is available on the web server
  static Future<AppUpdateInfo?> checkForUpdate({String? customUrl}) async {
    try {
      final url = Uri.parse(customUrl ?? updateCheckUrl);
      final response = await http.get(url).timeout(const Duration(seconds: 5));

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

  /// Downloads APK with live progress callback (bytes received, total, ratio)
  static Future<String?> downloadApkWithProgress({
    required String apkUrl,
    required void Function(double progress, double downloadedMb, double totalMb) onProgress,
  }) async {
    try {
      final cacheDir = await NativeBridgeService.getAppCacheDir();
      if (cacheDir.isEmpty) return null;
      final targetFile = File('$cacheDir/singlishgo_update.apk');
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(apkUrl));
      final streamedResponse = await client.send(request);

      final totalBytes = streamedResponse.contentLength ?? (51 * 1024 * 1024);
      int receivedBytes = 0;

      final sink = targetFile.openWrite();
      await streamedResponse.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
        final downloadedMb = receivedBytes / (1024 * 1024);
        final totalMb = totalBytes / (1024 * 1024);
        onProgress(progress, downloadedMb, totalMb);
      });

      await sink.flush();
      await sink.close();
      client.close();

      return targetFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Launches native installer for the downloaded file
  static Future<void> installApk(String filePath) async {
    await NativeBridgeService.installApkFile(filePath);
  }

  /// Fallback background download via DownloadManager
  static Future<void> triggerUpdate(String apkUrl) async {
    await NativeBridgeService.downloadAndInstallApk(apkUrl);
  }
}
