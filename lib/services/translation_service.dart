import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../database/database_service.dart';
import '../translation/engine/language_detector.dart';
import '../translation/providers/translation_coordinator.dart';
import '../core/services/native_bridge_service.dart';

// User Settings Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier() : super(const UserSettings());

  void toggleAutoTranslation(bool value) {
    state = state.copyWith(autoTranslationEnabled: value);
  }

  void setTranslationMode(TranslationMode mode) {
    state = state.copyWith(defaultMode: mode);
  }

  void toggleShowOriginal(bool value) {
    state = state.copyWith(showOriginalMessage: value);
  }

  void toggleSaveHistory(bool value) {
    state = state.copyWith(saveHistory: value);
  }

  void setAutoDeletePeriod(String period) {
    state = state.copyWith(autoDeletePeriod: period);
    DatabaseService.instance.autoPurgeOldTranslations(period);
  }

  void toggleTranslatedNotifications(bool value) {
    state = state.copyWith(translatedNotifications: value);
  }

  void toggleTheme(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }

  void setGeminiApiKey(String key) {
    state = state.copyWith(geminiApiKey: key);
  }

  Future<void> toggleFloatingBubble(bool enabled) async {
    if (enabled) {
      final hasPerm = await NativeBridgeService.isOverlayPermissionGranted();
      if (!hasPerm) {
        await NativeBridgeService.requestOverlayPermission();
      }
      await NativeBridgeService.startFloatingBubble();
    } else {
      await NativeBridgeService.stopFloatingBubble();
    }
    state = state.copyWith(isFloatingBubbleEnabled: enabled);
  }

  Future<void> setTargetLanguage(String language) async {
    state = state.copyWith(targetLanguage: language);
    await NativeBridgeService.setFloatingBubbleLanguage(language);
  }
}

// Stats Provider
final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await DatabaseService.instance.getStats();
});

// Permission Provider
final permissionStatusProvider = FutureProvider<bool>((ref) async {
  return await NativeBridgeService.isNotificationListenerEnabled();
});

// Floating Bubble Permission Provider
final overlayPermissionProvider = FutureProvider<bool>((ref) async {
  return await NativeBridgeService.isOverlayPermissionGranted();
});

// Translation Feed & Pipeline Provider
final translationFeedProvider = StateNotifierProvider<TranslationFeedNotifier, List<TranslationMessage>>((ref) {
  final settings = ref.watch(settingsProvider);
  return TranslationFeedNotifier(settings);
});

class TranslationFeedNotifier extends StateNotifier<List<TranslationMessage>> {
  final UserSettings settings;
  final TranslationCoordinator _coordinator = TranslationCoordinator();
  StreamSubscription? _subscription;

  TranslationFeedNotifier(this.settings) : super([]) {
    _loadInitialHistory();
    _startListening();
  }

  Future<void> _loadInitialHistory() async {
    final list = await DatabaseService.instance.getAllTranslations(limit: 50);
    if (list.isEmpty) {
      final seed = [
        TranslationMessage(
          id: const Uuid().v4(),
          senderName: 'Kasun Bandara',
          originalText: 'mama ada class ekata enne na bro',
          detectedLanguage: LanguageType.singlish,
          translatedSinhala: 'මම අද class එකට එන්නේ නැහැ.',
          translatedEnglish: 'I am not coming to class today.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        TranslationMessage(
          id: const Uuid().v4(),
          senderName: 'Dr. Nimal Perera',
          originalText: 'Can you send me the assignment today?',
          detectedLanguage: LanguageType.english,
          translatedSinhala: 'අද assignment එක මට එවන්න පුළුවන්ද?',
          translatedEnglish: 'Can you send me the assignment today?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 4)),
        ),
        TranslationMessage(
          id: const Uuid().v4(),
          senderName: 'Sanduni',
          originalText: 'assignment eka ada submit karanna oni',
          detectedLanguage: LanguageType.singlish,
          translatedSinhala: 'assignment එක අද submit කරන්න ඕන.',
          translatedEnglish: 'The assignment needs to be submitted today.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];
      for (final m in seed) {
        await DatabaseService.instance.insertTranslation(m);
      }
      state = seed;
    } else {
      state = list;
    }
  }

  void _startListening() {
    try {
      _subscription = NativeBridgeService.incomingNotifications.listen((payload) {
        final sender = payload['sender'] as String? ?? 'WhatsApp Contact';
        final message = payload['message'] as String? ?? '';
        processIncomingMessage(sender: sender, message: message);
      });
    } catch (e) {
      // Ignored
    }
  }

  Future<void> processIncomingMessage({
    required String sender,
    required String message,
  }) async {
    if (!settings.autoTranslationEnabled) return;

    final contactPref = await DatabaseService.instance.getContactPreference(sender);
    if (contactPref != null && !contactPref.translationEnabled) {
      return;
    }

    final mode = contactPref?.preferredMode ?? settings.defaultMode;
    final detection = LanguageDetector.detect(message);

    final translation = await _coordinator.processMessage(
      text: message,
      mode: mode,
      geminiApiKey: settings.geminiApiKey,
    );

    final item = TranslationMessage(
      id: const Uuid().v4(),
      senderName: sender,
      originalText: message,
      detectedLanguage: detection.type,
      translatedSinhala: translation.sinhala,
      translatedEnglish: translation.english,
      timestamp: DateTime.now(),
    );

    if (settings.saveHistory) {
      await DatabaseService.instance.insertTranslation(item);
    }

    state = [item, ...state];

    // Show native translated Android notification
    if (settings.translatedNotifications) {
      final primary = settings.targetLanguage == 'tamil'
          ? (translation.tamil.isNotEmpty ? translation.tamil : item.translatedSinhala)
          : (mode == TranslationMode.autoEnglish ? item.translatedEnglish : item.translatedSinhala);
      final secondary = mode == TranslationMode.dual ? item.translatedEnglish : null;

      await NativeBridgeService.showTranslatedNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        sender: sender,
        primaryTranslation: primary,
        originalText: message,
        secondaryTranslation: secondary,
      );
    }

    // Trigger Floating Bubble / Assistive Touch overlay if enabled
    if (settings.isFloatingBubbleEnabled) {
      final floatingTranslation = settings.targetLanguage == 'english'
          ? (item.translatedEnglish.isNotEmpty ? item.translatedEnglish : item.translatedSinhala)
          : (settings.targetLanguage == 'tamil'
              ? (translation.tamil.isNotEmpty ? translation.tamil : item.translatedSinhala)
              : (settings.targetLanguage == 'dual'
                  ? '${item.translatedSinhala}\n(${item.translatedEnglish})'
                  : (item.translatedSinhala.isNotEmpty ? item.translatedSinhala : item.translatedEnglish)));

      await NativeBridgeService.showFloatingMessage(
        sender: sender,
        translation: floatingTranslation,
        original: message,
      );
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = state.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(isFavorite: !state[index].isFavorite);
      state = [
        for (final m in state) m.id == id ? updated : m,
      ];
      await DatabaseService.instance.toggleFavorite(id, updated.isFavorite);
    }
  }

  Future<void> deleteMessage(String id) async {
    state = state.where((m) => m.id != id).toList();
    await DatabaseService.instance.deleteTranslation(id);
  }

  Future<void> clearAll() async {
    state = [];
    await DatabaseService.instance.clearAllTranslations();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
