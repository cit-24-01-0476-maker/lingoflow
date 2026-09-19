import '../../models/models.dart';
import '../engine/language_detector.dart';
import 'translation_provider.dart';
import 'singlish_local_provider.dart';
import 'gemini_translation_provider.dart';

class TranslationCoordinator {
  final SinglishLocalProvider _localProvider = SinglishLocalProvider();
  final Map<String, TranslationResult> _cache = {};

  Future<TranslationResult> processMessage({
    required String text,
    required TranslationMode mode,
    String? geminiApiKey,
  }) async {
    final cacheKey = '$mode|${text.trim()}';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      return TranslationResult(
        sinhala: cached.sinhala,
        english: cached.english,
        providerName: cached.providerName,
        isCached: true,
      );
    }

    final detection = LanguageDetector.detect(text);

    // If Gemini API is configured, prioritize cloud translation
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      try {
        final gemini = GeminiTranslationProvider(apiKey: geminiApiKey);
        final result = await gemini.translate(
          text: text,
          detectedLanguage: detection.type,
          mode: mode,
        );
        _cache[cacheKey] = result;
        return result;
      } catch (e) {
        // Fallback gracefully to offline engine
      }
    }

    // Default fast local provider (<15ms)
    final localResult = await _localProvider.translate(
      text: text,
      detectedLanguage: detection.type,
      mode: mode,
    );

    _cache[cacheKey] = localResult;
    return localResult;
  }
}
