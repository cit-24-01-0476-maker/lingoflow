enum LanguageType {
  english,
  sinhala,
  singlish,
  mixed,
  unknown
}

enum TranslationMode {
  autoSinhala, // Translate into Sinhala
  autoEnglish, // Translate into English
  dual,        // Display Original + Sinhala + English
  smart        // Intelligently decide best target
}

class TranslationMessage {
  final String id;
  final String senderName;
  final String originalText;
  final LanguageType detectedLanguage;
  final String translatedSinhala;
  final String translatedEnglish;
  final DateTime timestamp;
  final String sourceApp;
  final bool isFavorite;

  const TranslationMessage({
    required this.id,
    required this.senderName,
    required this.originalText,
    required this.detectedLanguage,
    required this.translatedSinhala,
    required this.translatedEnglish,
    required this.timestamp,
    this.sourceApp = 'WhatsApp',
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_name': senderName,
      'original_text': originalText,
      'detected_language': detectedLanguage.name,
      'translated_sinhala': translatedSinhala,
      'translated_english': translatedEnglish,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'source_app': sourceApp,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory TranslationMessage.fromMap(Map<String, dynamic> map) {
    return TranslationMessage(
      id: map['id'] as String,
      senderName: map['sender_name'] as String,
      originalText: map['original_text'] as String,
      detectedLanguage: LanguageType.values.firstWhere(
        (e) => e.name == map['detected_language'],
        orElse: () => LanguageType.singlish,
      ),
      translatedSinhala: map['translated_sinhala'] as String? ?? '',
      translatedEnglish: map['translated_english'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      sourceApp: map['source_app'] as String? ?? 'WhatsApp',
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }

  TranslationMessage copyWith({
    String? id,
    String? senderName,
    String? originalText,
    LanguageType? detectedLanguage,
    String? translatedSinhala,
    String? translatedEnglish,
    DateTime? timestamp,
    String? sourceApp,
    bool? isFavorite,
  }) {
    return TranslationMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      originalText: originalText ?? this.originalText,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      translatedSinhala: translatedSinhala ?? this.translatedSinhala,
      translatedEnglish: translatedEnglish ?? this.translatedEnglish,
      timestamp: timestamp ?? this.timestamp,
      sourceApp: sourceApp ?? this.sourceApp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class ContactPreference {
  final String contactName;
  final bool translationEnabled;
  final TranslationMode preferredMode;

  const ContactPreference({
    required this.contactName,
    this.translationEnabled = true,
    this.preferredMode = TranslationMode.dual,
  });

  Map<String, dynamic> toMap() {
    return {
      'contact_name': contactName,
      'translation_enabled': translationEnabled ? 1 : 0,
      'preferred_mode': preferredMode.name,
    };
  }

  factory ContactPreference.fromMap(Map<String, dynamic> map) {
    return ContactPreference(
      contactName: map['contact_name'] as String,
      translationEnabled: (map['translation_enabled'] as int? ?? 1) == 1,
      preferredMode: TranslationMode.values.firstWhere(
        (e) => e.name == map['preferred_mode'],
        orElse: () => TranslationMode.dual,
      ),
    );
  }
}

class UserSettings {
  final bool autoTranslationEnabled;
  final TranslationMode defaultMode;
  final bool showOriginalMessage;
  final bool saveHistory;
  final String autoDeletePeriod; // 'never', '24h', '7d', '30d'
  final bool translatedNotifications;
  final bool isDarkMode;
  final String appLanguage; // 'en', 'si'
  final String geminiApiKey;

  const UserSettings({
    this.autoTranslationEnabled = true,
    this.defaultMode = TranslationMode.dual,
    this.showOriginalMessage = true,
    this.saveHistory = true,
    this.autoDeletePeriod = 'never',
    this.translatedNotifications = true,
    this.isDarkMode = true,
    this.appLanguage = 'en',
    this.geminiApiKey = '',
  });

  UserSettings copyWith({
    bool? autoTranslationEnabled,
    TranslationMode? defaultMode,
    bool? showOriginalMessage,
    bool? saveHistory,
    String? autoDeletePeriod,
    bool? translatedNotifications,
    bool? isDarkMode,
    String? appLanguage,
    String? geminiApiKey,
  }) {
    return UserSettings(
      autoTranslationEnabled: autoTranslationEnabled ?? this.autoTranslationEnabled,
      defaultMode: defaultMode ?? this.defaultMode,
      showOriginalMessage: showOriginalMessage ?? this.showOriginalMessage,
      saveHistory: saveHistory ?? this.saveHistory,
      autoDeletePeriod: autoDeletePeriod ?? this.autoDeletePeriod,
      translatedNotifications: translatedNotifications ?? this.translatedNotifications,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      appLanguage: appLanguage ?? this.appLanguage,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
}
