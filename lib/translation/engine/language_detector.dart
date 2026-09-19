import '../models/models.dart';

class LanguageDetector {
  // Regex for Sinhala Unicode block: U+0D80 to U+0DFF
  static final RegExp _sinhalaRegex = RegExp(r'[\u0D80-\u0DFF]');

  // Common English function words
  static final Set<String> _englishStopWords = {
    'the', 'is', 'are', 'was', 'were', 'have', 'has', 'had', 'do', 'does', 'did',
    'can', 'could', 'should', 'would', 'will', 'shall', 'may', 'might', 'must',
    'you', 'your', 'yours', 'they', 'them', 'their', 'we', 'us', 'our', 'what',
    'when', 'where', 'why', 'how', 'who', 'which', 'this', 'that', 'these', 'those',
    'send', 'please', 'today', 'tomorrow', 'meeting', 'class', 'assignment', 'submit',
    'hello', 'hi', 'thanks', 'thank', 'welcome', 'good', 'morning', 'night'
  };

  // Distinctive Sri Lankan Singlish tokens
  static final Set<String> _singlishKeywords = {
    'mama', 'oya', 'oyata', 'mata', 'api', 'apita', 'eyala', 'eyata',
    'ada', 'heta', 'iye', 'dan', 'passe', 'thawa', 'thiyenawa', 'thiyenawada',
    'gedara', 'enne', 'yanne', 'enawa', 'yanawa', 'karanawa', 'karanna', 'karalada',
    'hari', 'mokakda', 'koheda', 'kohomada', 'moko', 'aulk', 'awulak', 'onna',
    'menna', 'eka', 'ekata', 'ow', 'ne', 'na', 'naha', 'nathuwa', 'kiyapan', 'kiyanna',
    'ewwada', 'ewanna', 'danna', 'danne', 'puluwanda', 'oni', 'oneda', 'epa'
  };

  /// Detects the language of the text with classification and confidence
  static LanguageDetectionResult detect(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return LanguageDetectionResult(LanguageType.unknown, 0.0);
    }

    // 1. Check Sinhala Unicode coverage
    int sinhalaCharCount = 0;
    for (int i = 0; i < trimmed.length; i++) {
      if (_sinhalaRegex.hasMatch(trimmed[i])) {
        sinhalaCharCount++;
      }
    }

    final double sinhalaRatio = sinhalaCharCount / trimmed.length;
    if (sinhalaRatio > 0.35) {
      return LanguageDetectionResult(LanguageType.sinhala, sinhalaRatio);
    }

    // 2. Tokenize for Romanized text (English vs Singlish vs Mixed)
    final words = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return LanguageDetectionResult(LanguageType.unknown, 0.0);
    }

    int singlishHits = 0;
    int englishHits = 0;

    for (final word in words) {
      if (_singlishKeywords.contains(word)) {
        singlishHits++;
      } else if (_isSinglishMorphology(word)) {
        singlishHits++;
      } else if (_englishStopWords.contains(word)) {
        englishHits++;
      }
    }

    final int totalRecognized = singlishHits + englishHits;
    if (totalRecognized == 0) {
      // Default to Singlish heuristic for informal chat style, otherwise English
      return _looksLikeSinglishPhonetics(trimmed)
          ? LanguageDetectionResult(LanguageType.singlish, 0.6)
          : LanguageDetectionResult(LanguageType.english, 0.6);
    }

    if (singlishHits > 0 && englishHits > 0) {
      return LanguageDetectionResult(LanguageType.mixed, 0.85);
    }

    if (singlishHits > englishHits) {
      final confidence = (singlishHits / words.length).clamp(0.5, 1.0);
      return LanguageDetectionResult(LanguageType.singlish, confidence);
    } else {
      final confidence = (englishHits / words.length).clamp(0.5, 1.0);
      return LanguageDetectionResult(LanguageType.english, confidence);
    }
  }

  static bool _isSinglishMorphology(String word) {
    // Suffixes typical in Singlish: -da (question), -la (plural), -ta (dative), -wa, -ge
    if (word.endsWith('da') || word.endsWith('thiyenawa') || word.endsWith('nawa') ||
        word.endsWith('anna') || word.endsWith('enne') || word.endsWith('ekata') ||
        word.endsWith('eken') || word.endsWith('thama') || word.endsWith('thami')) {
      return true;
    }
    return false;
  }

  static bool _looksLikeSinglishPhonetics(String text) {
    final lower = text.toLowerCase();
    return lower.contains('th') || lower.contains('dh') || lower.contains('nd') ||
           lower.contains('mb') || lower.contains('oo') || lower.contains('ee');
  }
}

class LanguageDetectionResult {
  final LanguageType type;
  final double confidence;

  LanguageDetectionResult(this.type, this.confidence);
}
