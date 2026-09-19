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

  /// Trigger OTA APK download and silent/system package installer trigger
  static Future<void> downloadAndInstallApk(String apkUrl) async {
    try {
      await _methodChannel.invokeMethod('downloadAndInstallApk', {
        'apkUrl': apkUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch current running app versionCode
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
