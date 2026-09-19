import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/translation_service.dart';
import '../../core/services/native_bridge_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showApiKeyDialog(BuildContext context, WidgetRef ref, String currentKey) {
    final ctrl = TextEditingController(text: currentKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Gemini API Key', style: TextStyle(color: AppColors.textPrimaryDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optional: Add your Google Gemini API key for conversational nuances. If left empty, LingoFlow will use the fast built-in offline engine.',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: AppColors.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMutedDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              ref.read(settingsProvider.notifier).setGeminiApiKey(ctrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gemini configuration saved')),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSectionHeader('Assistive Touch & In-Chat Overlay'),
          _buildCard([
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                radius: 18,
                child: Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
              ),
              title: const Text(
                'Floating Bubble / Assistive Touch',
                style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Show floating bubble over WhatsApp with instant popup translation',
                style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
              ),
              trailing: Switch(
                value: settings.isFloatingBubbleEnabled,
                activeColor: AppColors.primaryAccent,
                onChanged: (val) async {
                  await notifier.toggleFloatingBubble(val);
                  if (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Floating Assistive Bubble activated!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            ListTile(
              title: const Text('Target Translation Language', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: Text(
                settings.targetLanguage == 'sinhala'
                    ? 'සිංහල (Sinhala Only)'
                    : (settings.targetLanguage == 'english' ? 'English Only' : 'Dual (Sinhala + English)'),
                style: const TextStyle(color: AppColors.primaryAccent, fontSize: 12),
              ),
              trailing: DropdownButton<String>(
                value: settings.targetLanguage,
                dropdownColor: AppColors.surfaceDark,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'sinhala', child: Text('සිංහල (Sinhala)')),
                  DropdownMenuItem(value: 'english', child: Text('English')),
                  DropdownMenuItem(value: 'dual', child: Text('Dual (සිංහල + EN)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    notifier.setTargetLanguage(val);
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Translation Preferences'),
          _buildCard([
            ListTile(
              title: const Text('Auto-Translation Engine', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: const Text('Detect and process WhatsApp notifications automatically', style: TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              trailing: Switch(
                value: settings.autoTranslationEnabled,
                activeColor: AppColors.primaryAccent,
                onChanged: (val) => notifier.toggleAutoTranslation(val),
              ),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            ListTile(
              title: const Text('Default Target Mode', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: Text('Current: ${settings.defaultMode.name.toUpperCase()}', style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              trailing: DropdownButton<TranslationMode>(
                value: settings.defaultMode,
                dropdownColor: AppColors.surfaceDark,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: TranslationMode.autoSinhala, child: Text('Sinhala')),
                  DropdownMenuItem(value: TranslationMode.autoEnglish, child: Text('English')),
                  DropdownMenuItem(value: TranslationMode.dual, child: Text('Dual')),
                  DropdownMenuItem(value: TranslationMode.smart, child: Text('Smart')),
                ],
                onChanged: (val) {
                  if (val != null) notifier.setTranslationMode(val);
                },
              ),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            ListTile(
              title: const Text('Cloud AI Provider', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: Text(
                settings.geminiApiKey.isEmpty ? 'Offline Singlish Engine (Active)' : 'Google Gemini AI (Configured)',
                style: const TextStyle(color: AppColors.accentCyan, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark),
              onTap: () => _showApiKeyDialog(context, ref, settings.geminiApiKey),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Notification Behavior'),
          _buildCard([
            ListTile(
              title: const Text('Show Translated Notifications', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: const Text('Create an instant translated alert with quick copy actions', style: TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              trailing: Switch(
                value: settings.translatedNotifications,
                activeColor: AppColors.primaryAccent,
                onChanged: (val) => notifier.toggleTranslatedNotifications(val),
              ),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            ListTile(
              title: const Text('Re-check Notification Access', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: const Text('Open Android system Notification Listener settings', style: TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondaryDark, size: 20),
              onTap: () => NativeBridgeService.openNotificationListenerSettings(),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Privacy & Data Retention'),
          _buildCard([
            ListTile(
              title: const Text('Save Local History', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: const Text('Store translated messages securely in your local SQLite db', style: TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              trailing: Switch(
                value: settings.saveHistory,
                activeColor: AppColors.primaryAccent,
                onChanged: (val) => notifier.toggleSaveHistory(val),
              ),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            ListTile(
              title: const Text('Auto-Delete Old History', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: Text('Retention: ${settings.autoDeletePeriod.toUpperCase()}', style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
              trailing: DropdownButton<String>(
                value: settings.autoDeletePeriod,
                dropdownColor: AppColors.surfaceDark,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'never', child: Text('Never')),
                  DropdownMenuItem(value: '24h', child: Text('24 Hours')),
                  DropdownMenuItem(value: '7d', child: Text('7 Days')),
                  DropdownMenuItem(value: '30d', child: Text('30 Days')),
                ],
                onChanged: (val) {
                  if (val != null) notifier.setAutoDeletePeriod(val);
                },
              ),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
              title: const Text('Delete All Translation History', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                await ref.read(translationFeedProvider.notifier).clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All translation history cleared.')),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('About LingoFlow'),
          _buildCard([
            const ListTile(
              title: Text('Version', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              trailing: Text('1.0.1 (Floating Bubble Build)', style: TextStyle(color: AppColors.textMutedDark)),
            ),
            const Divider(color: AppColors.cardDarkBorder, height: 1),
            const ListTile(
              title: Text('Privacy Statement', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Your conversations belong to you. LingoFlow processes only the message content required for translation.',
                style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
              ),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMutedDark,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardDarkBorder),
      ),
      child: Column(children: children),
    );
  }
}
