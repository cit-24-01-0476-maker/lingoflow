import '../../models/models.dart';

abstract class TranslationProvider {
  String get name;
  Future<bool> isAvailable();

  Future<TranslationResult> translate({
    required String text,
    required LanguageType detectedLanguage,
    required TranslationMode mode,
  });
}

class TranslationResult {
  final String sinhala;
  final String english;
  final String tamil;
  final String providerName;
  final bool isCached;

  TranslationResult({
    required this.sinhala,
    required this.english,
    this.tamil = '',
    required this.providerName,
    this.isCached = false,
  });
}
