import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/translation_service.dart';
import '../../widgets/translation_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'all'; // all, sinhala, english, singlish, today, week

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationFeedProvider);
    final feedNotifier = ref.read(translationFeedProvider.notifier);
    final query = _searchCtrl.text.trim().toLowerCase();

    // Filter by search text and tag
    final filtered = translations.where((msg) {
      final matchesQuery = query.isEmpty ||
          msg.senderName.toLowerCase().contains(query) ||
          msg.originalText.toLowerCase().contains(query) ||
          msg.translatedSinhala.toLowerCase().contains(query) ||
          msg.translatedEnglish.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      final now = DateTime.now();
      switch (_selectedFilter) {
        case 'sinhala':
          return msg.detectedLanguage == LanguageType.sinhala;
        case 'english':
          return msg.detectedLanguage == LanguageType.english;
        case 'singlish':
          return msg.detectedLanguage == LanguageType.singlish || msg.detectedLanguage == LanguageType.mixed;
        case 'today':
          return msg.timestamp.isAfter(DateTime(now.year, now.month, now.day));
        case 'week':
          return msg.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Translation History'),
        actions: [
          IconButton(
            tooltip: 'Clear History',
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondaryDark),
            onPressed: () => _confirmClearAll(context, feedNotifier),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'Search sender, message, or translation...',
                hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondaryDark, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMutedDark),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardDarkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardDarkBorder),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  _buildFilterChip('Singlish', 'singlish'),
                  _buildFilterChip('Sinhala', 'sinhala'),
                  _buildFilterChip('English', 'english'),
                  _buildFilterChip('Today', 'today'),
                  _buildFilterChip('This Week', 'week'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List of translated cards
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMutedDark),
                          SizedBox(height: 12),
                          Text(
                            'No matching translations found',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return TranslationCard(
                          message: item,
                          onFavoriteToggle: () => feedNotifier.toggleFavorite(item.id),
                          onDelete: () => feedNotifier.deleteMessage(item.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryBlue,
        backgroundColor: AppColors.cardDark,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondaryDark,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppColors.primaryAccent : AppColors.cardDarkBorder,
          ),
        ),
        onSelected: (_) => setState(() => _selectedFilter = key),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, TranslationFeedNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Clear Translation History?', style: TextStyle(color: AppColors.textPrimaryDark)),
        content: const Text(
          'This will delete all saved translation records from local storage. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMutedDark)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.clearAll();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
