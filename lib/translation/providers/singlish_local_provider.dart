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

  static final Map<String, String> _phraseToTamil = {
    'mama ada class ekata enne na': "நான் இன்று வகுப்புக்கு வரவில்லை.",
    'mama ada class ekata enne naha': "நான் இன்று வகுப்புக்கு வரவில்லை.",
    'oyata kohomada': "நீங்கள் எப்படி இருக்கிறீர்கள்?",
    'how are you': "நீங்கள் எப்படி இருக்கிறீர்கள்?",
    'how are you?': "நீங்கள் எப்படி இருக்கிறீர்கள்?",
    'mama gedara yanawa': "நான் வீட்டிற்கு போகிறேன்.",
    'i am going home': "நான் வீட்டிற்கு போகிறேன்.",
    'ada class thiyenawada': "இன்று வகுப்பு உள்ளதா?",
    'mama heta ennam': "நான் நாளை வருகிறேன்.",
    'i will come tomorrow': "நான் நாளை வருகிறேன்.",
    'hari mama ennam': "சரி, நான் வருகிறேன்.",
    'mokakda karanne': "என்ன செய்கிறீர்கள்?",
    'what are you doing': "என்ன செய்கிறீர்கள்?",
    'koheda yanne': "எங்கே போகிறீர்கள்?",
    'where are you going': "எங்கே போகிறீர்கள்?",
    'ikmanata enna': "சீக்கிரம் வாருங்கள்.",
    'come quickly': "சீக்கிரம் வாருங்கள்.",
    'subha udasanak': "காலை வணக்கம்.",
    'good morning': "காலை வணக்கம்.",
    'subha rathriyak': "இனிய இரவு.",
    'good night': "இனிய இரவு.",
    'bohoma sthuthi': "மிக்க நன்றி.",
    'sthuthi': "நன்றி.",
    'thank you': "நன்றி.",
    'thank you very much': "மிக்க நன்றி.",
    'elakiri kollo': "சூப்பர் நண்பா!",
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
    String tamilResult = '';

    // 1. Direct phrase check
    if (_phraseToEnglish.containsKey(lowerTrimmed)) {
      englishResult = _phraseToEnglish[lowerTrimmed]!;
    }
    if (_englishToSinhala.containsKey(lowerTrimmed)) {
      sinhalaResult = _englishToSinhala[lowerTrimmed]!;
    }
    if (_phraseToTamil.containsKey(lowerTrimmed)) {
      tamilResult = _phraseToTamil[lowerTrimmed]!;
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
        englishResult = _approximateEnglishFromSinglish(lowerTrimmed);
      }
    }

    // 4. Fallback for Tamil translation
    if (tamilResult.isEmpty) {
      if (lowerTrimmed.contains('kohomada')) {
        tamilResult = "எப்படி இருக்கிறீர்கள்?";
      } else if (lowerTrimmed.contains('yanawa')) {
        tamilResult = "போகிறேன்.";
      } else if (lowerTrimmed.contains('ennam') || lowerTrimmed.contains('enawa')) {
        tamilResult = "வருகிறேன்.";
      } else if (lowerTrimmed.contains('enne na') || lowerTrimmed.contains('enne naha')) {
        tamilResult = "வரமாட்டேன்.";
      } else if (lowerTrimmed.contains('sthuthi')) {
        tamilResult = "நன்றி.";
      } else {
        tamilResult = englishResult; // Graceful fallback
      }
    }

    return TranslationResult(
      sinhala: sinhalaResult,
      english: englishResult,
      tamil: tamilResult,
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
