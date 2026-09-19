import '../../models/models.dart';
import '../engine/singlish_transliteration_engine.dart';
import 'translation_provider.dart';

class SinglishLocalProvider implements TranslationProvider {
  @override
  String get name => 'Offline Singlish Engine';

  @override
  Future<bool> isAvailable() async => true;

  // Curated common conversational phrases mapping Singlish/Sinhala -> English
  static final Map<String, String> _phraseToEnglish = {
    'mama ada class ekata enne na': "I am not coming to class today.",
    'mama ada class ekata enne naha': "I am not coming to class today.",
    'can you send me the assignment today?': "Can you send me the assignment today?",
    'can you send me the assignment today': "Can you send me the assignment today?",
    'assignment eka ada submit karanna oni': "The assignment needs to be submitted today.",
    'oyata kohomada': "How are you?",
    'mama gedara yanawa': "I am going home.",
    'ada class thiyenawada': "Is there class today?",
    'eka mata ewwada': "Did you send that to me?",
    'mama heta ennam': "I will come tomorrow.",
    'mama heta meeting ekata ennam': "I will come to the meeting tomorrow.",
    'hari mama ennam': "Okay, I will come.",
    'mokakda karanne': "What are you doing?",
    'koheda yanne': "Where are you going?",
    'dan enne puluwanda': "Can you come now?",
    'ikmanata enna': "Come quickly.",
    'elakiri kollo': "Awesome bro!",
    'mata udawwak karanna puluwanda': "Can you do me a favor?",
    'subha udasanak': "Good morning.",
    'subha rathriyak': "Good night.",
    'bohoma sthuthi': "Thank you very much.",
    'sthuthi': "Thank you.",
  };

  static final Map<String, String> _englishToSinhala = {
    'can you send me the assignment today?': "අද assignment එක මට එවන්න පුළුවන්ද?",
    'can you send me the assignment today': "අද assignment එක මට එවන්න පුළුවන්ද?",
    'how are you?': "ඔයාට කොහොමද?",
    'how are you': "ඔයාට කොහොමද?",
    'where are you going?': "ඔයා කොහෙද යන්නේ?",
    'where are you going': "ඔයා කොහෙද යන්නේ?",
    'i will come tomorrow': "මම හෙට එන්නම්.",
    'i am going home': "මම ගෙදර යනවා.",
    'is there class today?': "අද class තියෙනවද?",
    'good morning': "සුබ උදෑසනක්.",
    'good night': "සුබ රාත්‍රියක්.",
    'thank you': "ස්තූතියි.",
    'thank you very much': "බොහොම ස්තූතියි.",
    'i am not coming to class today': "මම අද class එකට එන්නේ නැහැ.",
  };

  @override
  Future<TranslationResult> translate({
    required String text,
    required LanguageType detectedLanguage,
    required TranslationMode mode,
  }) async {
    final lowerTrimmed = text.trim().toLowerCase().replaceAll(RegExp(r'[.!?]+$'), '');
    String sinhalaResult = '';
    String englishResult = '';

    // 1. Direct phrase check
    if (_phraseToEnglish.containsKey(lowerTrimmed)) {
      englishResult = _phraseToEnglish[lowerTrimmed]!;
    }
    if (_englishToSinhala.containsKey(lowerTrimmed)) {
      sinhalaResult = _englishToSinhala[lowerTrimmed]!;
    }

    // 2. Perform transliteration if Sinhala result is not yet resolved
    if (sinhalaResult.isEmpty) {
      if (detectedLanguage == LanguageType.sinhala) {
        sinhalaResult = text;
      } else {
        sinhalaResult = SinglishTransliterationEngine.transliterate(text);
      }
    }

    // 3. Fallback for English translation if not in dictionary
    if (englishResult.isEmpty) {
      if (detectedLanguage == LanguageType.english) {
        englishResult = text;
      } else {
        // Approximate meaningful conversion for common patterns
        englishResult = _approximateEnglishFromSinglish(lowerTrimmed);
      }
    }

    return TranslationResult(
      sinhala: sinhalaResult,
      english: englishResult,
      providerName: name,
    );
  }

  String _approximateEnglishFromSinglish(String input) {
    if (input.contains('enne na') || input.contains('enne naha')) {
      return "Not coming.";
    }
    if (input.contains('yanawa')) {
      return "Going.";
    }
    if (input.contains('enawa') || input.contains('ennam')) {
      return "Will come.";
    }
    if (input.contains('kohomada')) {
      return "How are things?";
    }
    if (input.contains('puluwanda')) {
      return "Is it possible?";
    }
    if (input.contains('ewwada')) {
      return "Sent?";
    }
    return "Translated text";
  }
}
