import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/translation_service.dart';
import '../../core/services/native_bridge_service.dart';
import '../../widgets/translation_card.dart';
import '../history/history_screen.dart';
import '../contacts/contacts_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({Key? key}) : super(key: key);

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentTab = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.cardDarkBorder, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (idx) => setState(() => _currentTab = idx),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showSimulationDialog(BuildContext context, WidgetRef ref) {
    final senderCtrl = TextEditingController(text: 'Nimal Silva');
    final messageCtrl = TextEditingController(text: 'mama heta meeting ekata ennam');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.bolt_rounded, color: AppColors.primaryAccent),
                SizedBox(width: 8),
                Text(
                  'Simulate WhatsApp Notification',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Test real-time Singlish, Sinhala, and English detection pipeline instantly.',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: senderCtrl,
              decoration: InputDecoration(
                labelText: 'Sender Name',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              decoration: InputDecoration(
                labelText: 'Message Text',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            // Quick preset chips
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Singlish Class', style: TextStyle(fontSize: 11)),
                  onPressed: () => messageCtrl.text = "mama ada class ekata enne na",
                ),
                ActionChip(
                  label: const Text('English Assign', style: TextStyle(fontSize: 11)),
                  onPressed: () => messageCtrl.text = "Can you send me the assignment today?",
                ),
                ActionChip(
                  label: const Text('Sinhala Uni', style: TextStyle(fontSize: 11)),
                  onPressed: () => messageCtrl.text = "ඔයා කොහෙද යන්නේ?",
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(translationFeedProvider.notifier).processIncomingMessage(
                    sender: senderCtrl.text.trim(),
                    message: messageCtrl.text.trim(),
                  );
                },
                child: const Text('Simulate Incoming WhatsApp Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final translations = ref.watch(translationFeedProvider);
    final feedNotifier = ref.read(translationFeedProvider.notifier);
    final statsAsync = ref.watch(statsProvider);
    final permissionAsync = ref.watch(permissionStatusProvider);

    final recentItems = translations.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryAccent],
                ),
              ),
              child: const Icon(Icons.translate_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('LingoFlow'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simulate Message',
            icon: const Icon(Icons.add_alert_rounded, color: AppColors.primaryAccent),
            onPressed: () => _showSimulationDialog(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card (Listening / Paused)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.autoTranslationEnabled ? AppColors.accentGreen.withOpacity(0.3) : AppColors.cardDarkBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: settings.autoTranslationEnabled ? AppColors.accentGreen : AppColors.textMutedDark,
                      boxShadow: settings.autoTranslationEnabled
                          ? [BoxShadow(color: AppColors.accentGreen.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.autoTranslationEnabled
                              ? 'LingoFlow is active & listening'
                              : 'Auto-Translation Paused',
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.autoTranslationEnabled
                              ? 'WhatsApp notifications are being translated'
                              : 'Incoming messages will not be converted',
                          style: const TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.autoTranslationEnabled,
                    activeColor: AppColors.primaryAccent,
                    onChanged: (val) => settingsNotifier.toggleAutoTranslation(val),
                  ),
                ],
              ),
            ),

            // Notification Access Disabled Alert (if not granted)
            permissionAsync.maybeWhen(
              data: (granted) => !granted
                  ? Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.accentOrange, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Notification access is disabled. Translations will not trigger automatically.',
                              style: TextStyle(color: AppColors.accentOrange, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: () => NativeBridgeService.openNotificationListenerSettings(),
                            child: const Text('Fix', style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),

            // Translation Mode Selector
            const Text(
              'Translation Mode',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildModeChip(
                    label: 'Auto Sinhala',
                    mode: TranslationMode.autoSinhala,
                    current: settings.defaultMode,
                    onTap: () => settingsNotifier.setTranslationMode(TranslationMode.autoSinhala),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(
                    label: 'Auto English',
                    mode: TranslationMode.autoEnglish,
                    current: settings.defaultMode,
                    onTap: () => settingsNotifier.setTranslationMode(TranslationMode.autoEnglish),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(
                    label: 'Dual Translation',
                    mode: TranslationMode.dual,
                    current: settings.defaultMode,
                    onTap: () => settingsNotifier.setTranslationMode(TranslationMode.dual),
                  ),
                  const SizedBox(width: 8),
                  _buildModeChip(
                    label: 'Smart Auto',
                    mode: TranslationMode.smart,
                    current: settings.defaultMode,
                    onTap: () => settingsNotifier.setTranslationMode(TranslationMode.smart),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Row
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  _buildStatCard('Today', '${stats['today'] ?? 0}', Icons.today_rounded, AppColors.primaryAccent),
                  const SizedBox(width: 12),
                  _buildStatCard('Sinhala', '${stats['sinhala'] ?? 0}', Icons.translate_rounded, AppColors.accentOrange),
                  const SizedBox(width: 12),
                  _buildStatCard('English', '${stats['english'] ?? 0}', Icons.language_rounded, AppColors.accentCyan),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 28),

            // Recent Translations Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Translations',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${recentItems.length} messages',
                  style: const TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Feed Items
            if (recentItems.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.mark_chat_unread_outlined, size: 48, color: AppColors.textMutedDark),
                    SizedBox(height: 12),
                    Text(
                      'No WhatsApp translations yet',
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Messages will appear here as soon as they arrive.',
                      style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ...recentItems.map(
                (item) => TranslationCard(
                  message: item,
                  onFavoriteToggle: () => feedNotifier.toggleFavorite(item.id),
                  onDelete: () => feedNotifier.deleteMessage(item.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required TranslationMode mode,
    required TranslationMode current,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.cardDarkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardDarkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
