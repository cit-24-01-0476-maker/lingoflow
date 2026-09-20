import 'package:flutter/services.dart';

class NativeBridgeService {
  static const MethodChannel _methodChannel = MethodChannel('com.lingoflow.app/methods');
  static const EventChannel _eventChannel = EventChannel('com.lingoflow.app/notifications');

  static Stream<Map<String, dynamic>>? _notificationStream;

  static Future<bool> isNotificationListenerEnabled() async {
    try {
      final bool? isEnabled = await _methodChannel.invokeMethod<bool>('isNotificationListenerEnabled');
      return isEnabled ?? false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openNotificationListenerSettings() async {
    try {
      await _methodChannel.invokeMethod('openNotificationListenerSettings');
    } catch (e) {}
  }

  // Floating Bubble / Assistive Touch overlay methods
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      final bool? granted = await _methodChannel.invokeMethod<bool>('isOverlayPermissionGranted');
      return granted ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _methodChannel.invokeMethod('requestOverlayPermission');
    } catch (e) {}
  }

  static Future<void> startFloatingBubble() async {
    try {
      await _methodChannel.invokeMethod('startFloatingBubble');
    } catch (e) {}
  }

  static Future<void> stopFloatingBubble() async {
    try {
      await _methodChannel.invokeMethod('stopFloatingBubble');
    } catch (e) {}
  }

  static Future<bool> isFloatingBubbleRunning() async {
    try {
      final bool? running = await _methodChannel.invokeMethod<bool>('isFloatingBubbleRunning');
      return running ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setFloatingBubbleLanguage(String language) async {
    try {
      await _methodChannel.invokeMethod('setFloatingBubbleLanguage', {'language': language});
    } catch (e) {}
  }

  static Future<void> showFloatingMessage({
    required String sender,
    required String translation,
    required String original,
  }) async {
    try {
      await _methodChannel.invokeMethod('showFloatingMessage', {
        'sender': sender,
        'translation': translation,
        'original': original,
      });
    } catch (e) {}
  }

  static Future<void> showTranslatedNotification({
    required int id,
    required String sender,
    required String primaryTranslation,
    required String originalText,
    String? secondaryTranslation,
  }) async {
    try {
      await _methodChannel.invokeMethod('showTranslatedNotification', {
        'id': id,
        'sender': sender,
        'primaryTranslation': primaryTranslation,
        'originalText': originalText,
        'secondaryTranslation': secondaryTranslation,
      });
    } catch (e) {}
  }

  static Future<void> simulateNotification({
    required String sender,
    required String message,
  }) async {
    try {
      await _methodChannel.invokeMethod('simulateNotification', {
        'sender': sender,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'package': 'com.whatsapp',
      });
    } catch (e) {}
  }

  static Future<String> getAppCacheDir() async {
    try {
      final String? path = await _methodChannel.invokeMethod<String>('getAppCacheDir');
      return path ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<void> installApkFile(String filePath) async {
    try {
      await _methodChannel.invokeMethod('installApkFile', {
        'filePath': filePath,
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> canRequestPackageInstalls() async {
    try {
      final bool? canInstall = await _methodChannel.invokeMethod<bool>('canRequestPackageInstalls');
      return canInstall ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> openInstallPermissionSettings() async {
    try {
      await _methodChannel.invokeMethod('openInstallPermissionSettings');
    } catch (e) {}
  }

  static Future<void> downloadAndInstallApk(String apkUrl) async {
    try {
      await _methodChannel.invokeMethod('downloadAndInstallApk', {
        'apkUrl': apkUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<int> getAppVersionCode() async {
    try {
      final int? code = await _methodChannel.invokeMethod<int>('getAppVersionCode');
      return code ?? 1;
    } catch (e) {
      return 1;
    }
  }

  static Stream<Map<String, dynamic>> get incomingNotifications {
    _notificationStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => Map<String, dynamic>.from(event as Map));
    return _notificationStream!;
  }
}
