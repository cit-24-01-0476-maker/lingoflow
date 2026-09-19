class SinglishTransliterationEngine {
  // Common Sri Lankan colloquial phrases & words (Exact overrides)
  static final Map<String, String> _dictionary = {
    // Pronouns & Persons
    'mama': 'මම',
    'mata': 'මට',
    'mage': 'මගේ',
    'mageth': 'මගෙත්',
    'oya': 'ඔයා',
    'oyata': 'ඔයාට',
    'oyage': 'ඔයාගේ',
    'oyala': 'ඔයාලා',
    'oyalata': 'ඔයාලට',
    'api': 'අපි',
    'apita': 'අපිට',
    'apata': 'අපට',
    'ape': 'අපේ',
    'eya': 'එයා',
    'eyata': 'එයාට',
    'eyala': 'එයාලා',
    'eyalata': 'එයාලට',
    'eyaage': 'එයාගේ',
    'kawda': 'කවුද',
    'kauda': 'කවුද',
    'monawada': 'මොනවද',
    'mokakda': 'මොකක්ද',
    'mokada': 'මොකද',
    'moko': 'මොකෝ',
    'koheda': 'කොහෙද',
    'kohomada': 'කොහොමද',
    'keeyada': 'කීයද',
    'kellek': 'කෙල්ලෙක්',
    'kollek': 'කොල්ලෙක්',

    // Time & Adverbs
    'ada': 'අද',
    'heta': 'හෙට',
    'iye': 'ඊයේ',
    'dan': 'දැන්',
    'passe': 'පස්සේ',
    'thawa': 'තව',
    'thawama': 'තවම',
    'kalin': 'කලින්',
    'ikmanata': 'ඉක්මනට',
    'hithala': 'හිතලා',
    'nodhan': 'නොදන්',
    'me': 'මේ',
    'oyaage': 'ඔයාගේ',
    'araka': 'අරක',
    'eka': 'එක',
    'ekata': 'එකට',
    'eken': 'එකෙන්',
    'ehema': 'එහෙම',
    'methana': 'මෙතන',
    'ethana': 'එතන',
    'arhe': 'අරහෙ',
    'kohe': 'කොහේ',

    // Verbs
    'yanawa': 'යනවා',
    'yanne': 'යන්නේ',
    'yanna': 'යන්න',
    'giya': 'ගියා',
    'enawa': 'එනවා',
    'enne': 'එන්නේ',
    'enna': 'එන්න',
    'awa': 'ආවා',
    'karannako': 'කරන්නකෝ',
    'karanna': 'කරන්න',
    'karanawa': 'කරනවා',
    'kala': 'කළා',
    'karala': 'කරලා',
    'ewwada': 'එව්වද',
    'ewanna': 'එවන්න',
    'ewwanam': 'එව්වනම්',
    'thiyenawa': 'තියෙනවා',
    'thiyenawada': 'තියෙනවද',
    'thibba': 'තිබ්බා',
    'danna': 'දන්න',
    'danne': 'දන්නේ',
    'dannam': 'දන්නම්',
    'kiyanna': 'කියන්න',
    'kiyapan': 'කියපන්',
    'kiwwa': 'කිව්වා',
    'ganna': 'ගන්න',
    'gaththe': 'ගත්තේ',
    'dunna': 'දුන්නා',
    'dhenna': 'දෙන්න',
    'balanna': 'බලන්න',
    'balala': 'බලලා',
    'balanawa': 'බලනවා',
    'puluwan': 'පුළුවන්',
    'puluwanda': 'පුළුවන්ද',
    'bari': 'බැරි',
    'ba': 'බෑ',
    'baha': 'බැහැ',
    'oni': 'ඕන',
    'oneda': 'ඕනෙද',
    'epa': 'එපා',
    'hithanawa': 'හිතනවා',
    'dannawa': 'දන්නවා',

    // Negatives & Confirmations
    'hari': 'හරි',
    'ow': 'ඔව්',
    'ne': 'නේ',
    'na': 'නැහැ',
    'naha': 'නැහැ',
    'naa': 'නැහැ',
    'nathuwa': 'නැතුව',
    'aulak': 'අවුලක්',
    'awulak': 'අවුලක්',
    'elakiri': 'එළකිරි',
    'supiri': 'සුපිරි',
    'gedara': 'ගෙදර',
    'office': 'office',
    'class': 'class',
    'assignment': 'assignment',
    'exam': 'exam',
    'lecture': 'lecture',
    'link': 'link',
    'meeting': 'meeting',
    'call': 'call',
    'submit': 'submit',
    'done': 'done',
    'thanks': 'ස්තූතියි',
    'bohoma': 'බොහොම',
    'sthuthi': 'ස්තූතියි',
    'subha': 'සුබ',
    'udasanak': 'උදෑසනක්',
    'rathriyak': 'රාත්‍රියක්',
    'sandawatha': 'සඳවත',
  };

  // English loanwords commonly used in Sri Lankan text that should remain in English
  static final Set<String> _englishLoanWords = {
    'class', 'assignment', 'submit', 'exam', 'lecture', 'link', 'call', 'meeting',
    'office', 'bus', 'train', 'ticket', 'card', 'bank', 'slip', 'pdf', 'zoom',
    'team', 'group', 'number', 'pass', 'code', 'file', 'message', 'msg', 'photo',
    'video', 'notes', 'project', 'presentation', 'drive', 'ok', 'okay', 'yes', 'no'
  };

  // Phonetic rule mappings for consonants and vowels
  static final Map<String, String> _consonants = {
    'thth': 'ත්ත',
    'ndh': 'ඳ',
    'mbh': 'ඹ',
    'nch': 'ඤ',
    'nsh': 'න්ෂ්',
    'ch': 'ච',
    'sh': 'ශ',
    'th': 'ත',
    'dh': 'ද',
    'kh': 'ඛ',
    'gh': 'ඝ',
    'jh': 'ඣ',
    'ph': 'ඵ',
    'bh': 'භ',
    'gn': 'ඥ',
    'kn': 'ක්න්',
    'k': 'ක',
    'g': 'ග',
    't': 'ට',
    'd': 'ඩ',
    'p': 'ප',
    'b': 'බ',
    'm': 'ම',
    'y': 'ය',
    'r': 'ර',
    'l': 'ල',
    'w': 'ව',
    'v': 'ව',
    's': 'ස',
    'h': 'හ',
    'j': 'ජ',
    'n': 'න',
  };

  static final Map<String, String> _vowelSigns = {
    'aa': 'ා',
    'a': '',
    'ae': 'ැ',
    'aae': 'ෑ',
    'ii': 'ී',
    'ee': 'ී',
    'i': 'ි',
    'uu': 'ූ',
    'oo': 'ූ',
    'u': 'ු',
    'ea': 'ේ',
    'ei': 'ෙයි',
    'e': 'ෙ',
    'o': 'ො',
    'oe': 'ෝ',
    'ai': 'ෛ',
    'au': 'ෞ',
  };

  static final Map<String, String> _initialVowels = {
    'aa': 'ආ',
    'a': 'අ',
    'ae': 'ඇ',
    'aae': 'ඈ',
    'ii': 'ඊ',
    'ee': 'ඊ',
    'i': 'ඉ',
    'uu': 'ඌ',
    'oo': 'ඌ',
    'u': 'උ',
    'e': 'එ',
    'ea': 'ඒ',
    'o': 'ඔ',
    'oe': 'ඕ',
    'ai': 'ඓ',
    'au': 'ඖ',
  };

  /// Transliterates text from Singlish into natural Sinhala Unicode
  static String transliterate(String input) {
    if (input.trim().isEmpty) return '';

    final words = input.split(RegExp(r'(\s+|[.,!?:;])'));
    final tokens = _tokenizeWithSeparators(input);

    final StringBuffer buffer = StringBuffer();
    for (final token in tokens) {
      if (RegExp(r'^\s+$').hasMatch(token) || RegExp(r'^[.,!?:;]+$').hasMatch(token)) {
        buffer.write(token);
        continue;
      }

      final lower = token.toLowerCase();
      // 1. Direct dictionary match
      if (_dictionary.containsKey(lower)) {
        buffer.write(_dictionary[lower]);
        continue;
      }

      // 2. English loanword retention
      if (_englishLoanWords.contains(lower)) {
        buffer.write(token);
        continue;
      }

      // 3. Suffix check (e.g. "class-ekata" -> "class එකට")
      if (lower.endsWith('ekata')) {
        final prefix = lower.substring(0, lower.length - 5);
        if (_englishLoanWords.contains(prefix)) {
          buffer.write('$prefix එකට');
          continue;
        }
      } else if (lower.endsWith('eka')) {
        final prefix = lower.substring(0, lower.length - 3);
        if (_englishLoanWords.contains(prefix)) {
          buffer.write('$prefix එක');
          continue;
        }
      } else if (lower.endsWith('eken')) {
        final prefix = lower.substring(0, lower.length - 4);
        if (_englishLoanWords.contains(prefix)) {
          buffer.write('$prefix එකෙන්');
          continue;
        }
      }

      // 4. Phonetic transliteration fallback
      buffer.write(_transliterateWord(lower));
    }

    var result = buffer.toString();
    // Punctuation clean-up if ended naturally
    if (!result.endsWith('.') && !result.endsWith('?') && !result.endsWith('!')) {
      if (input.trim().endsWith('?') || lowerHasQuestionMarker(input)) {
        result += '?';
      } else {
        result += '.';
      }
    }
    return result;
  }

  static bool lowerHasQuestionMarker(String input) {
    final lower = input.toLowerCase();
    return lower.endsWith('da') || lower.endsWith('dha') || lower.endsWith('mokakda') ||
           lower.endsWith('koheda') || lower.endsWith('kohomada');
  }

  static List<String> _tokenizeWithSeparators(String input) {
    final regex = RegExp(r'([A-Za-z0-9]+|[^\s\w]+|\s+)');
    return regex.allMatches(input).map((m) => m.group(0)!).toList();
  }

  static String _transliterateWord(String word) {
    final sb = StringBuffer();
    int i = 0;

    while (i < word.length) {
      // Check if starting with vowel
      if (i == 0 || (i > 0 && isVowel(word[i - 1]) && isVowel(word[i]))) {
        String? matchedVowel;
        int matchLen = 0;
        for (int len = 3; len >= 1; len--) {
          if (i + len <= word.length) {
            final sub = word.substring(i, i + len);
            if (_initialVowels.containsKey(sub)) {
              matchedVowel = _initialVowels[sub];
              matchLen = len;
              break;
            }
          }
        }
        if (matchedVowel != null) {
          sb.write(matchedVowel);
          i += matchLen;
          continue;
        }
      }

      // Check consonants
      String? matchedConsonant;
      int cLen = 0;
      for (int len = 4; len >= 1; len--) {
        if (i + len <= word.length) {
          final sub = word.substring(i, i + len);
          if (_consonants.containsKey(sub)) {
            matchedConsonant = _consonants[sub];
            cLen = len;
            break;
          }
        }
      }

      if (matchedConsonant != null) {
        i += cLen;
        // Check following vowel sign
        String? matchedSign;
        int vLen = 0;
        for (int len = 3; len >= 1; len--) {
          if (i + len <= word.length) {
            final sub = word.substring(i, i + len);
            if (_vowelSigns.containsKey(sub)) {
              matchedSign = _vowelSigns[sub];
              vLen = len;
              break;
            }
          }
        }

        if (matchedSign != null) {
          sb.write(matchedConsonant);
          sb.write(matchedSign);
          i += vLen;
        } else {
          // Hal (virama) character if followed by consonant or end of word
          if (i >= word.length || !isVowel(word[i])) {
            sb.write(matchedConsonant);
            sb.write('්');
          } else {
            sb.write(matchedConsonant);
          }
        }
      } else {
        // Unknown character, passthrough
        sb.write(word[i]);
        i++;
      }
    }

    return sb.toString();
  }

  static bool isVowel(String ch) {
    return 'aeiou'.contains(ch.toLowerCase());
  }
}
