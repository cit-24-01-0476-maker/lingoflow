import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/models.dart';
import 'translation_provider.dart';

class GeminiTranslationProvider implements TranslationProvider {
  final String apiKey;

  GeminiTranslationProvider({required this.apiKey});

  @override
  String get name => 'Gemini AI';

  @override
  Future<bool> isAvailable() async {
    return apiKey.trim().isNotEmpty;
  }

  @override
  Future<TranslationResult> translate({
    required String text,
    required LanguageType detectedLanguage,
    required TranslationMode mode,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API key is not configured');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = '''
You are LingoFlow's high-speed Sri Lankan translator.
Input message: "$text"
Detected Language: ${detectedLanguage.name}
Output strict JSON with format:
{
  "sinhala": "<natural modern Sinhala translation or transliteration if input was Singlish/English>",
  "english": "<accurate English translation>"
}
Do not include markdown or formatting, only valid raw JSON.
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 200,
        }
      }),
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      final rawOutput = candidates?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final cleanJson = rawOutput.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleanJson);

      return TranslationResult(
        sinhala: parsed['sinhala'] ?? '',
        english: parsed['english'] ?? '',
        providerName: name,
      );
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }
}
