import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../core/theme/app_theme.dart';

class TranslationCard extends StatelessWidget {
  final TranslationMessage message;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const TranslationCard({
    Key? key,
    required this.message,
    this.onFavoriteToggle,
    this.onDelete,
  }) : super(key: key);

  Color _getBadgeColor(LanguageType type) {
    switch (type) {
      case LanguageType.english:
        return AppColors.accentCyan;
      case LanguageType.sinhala:
        return AppColors.accentOrange;
      case LanguageType.singlish:
        return AppColors.primaryAccent;
      case LanguageType.mixed:
        return AppColors.accentPurple;
      case LanguageType.unknown:
        return AppColors.textMutedDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardDarkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Avatar, Sender, App Tag, Time
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                  child: Text(
                    message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              message.senderName,
                              style: const TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.whatsAppGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: AppColors.whatsAppGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Language badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(message.detectedLanguage).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getBadgeColor(message.detectedLanguage).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    message.detectedLanguage.name.toUpperCase(),
                    style: TextStyle(
                      color: _getBadgeColor(message.detectedLanguage),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Original Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORIGINAL',
                    style: TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.originalText,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Sinhala Translation
            if (message.translatedSinhala.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'සිංහල',
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.translatedSinhala,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // English Translation
            if (message.translatedEnglish.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN',
                      style: TextStyle(
                        color: AppColors.accentCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.translatedEnglish,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            const SizedBox(height: 8),

            // Actions: Copy, Share, Favorite, Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Copy Translation',
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondaryDark),
                  onPressed: () {
                    final textToCopy = '${message.translatedSinhala}\n${message.translatedEnglish}';
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Translation copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.textSecondaryDark),
                  onPressed: () {
                    Share.share(
                      'Original: ${message.originalText}\nSinhala: ${message.translatedSinhala}\nEnglish: ${message.translatedEnglish}',
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Favorite',
                  icon: Icon(
                    message.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: message.isFavorite ? AppColors.accentOrange : AppColors.textSecondaryDark,
                  ),
                  onPressed: onFavoriteToggle,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textMutedDark),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
