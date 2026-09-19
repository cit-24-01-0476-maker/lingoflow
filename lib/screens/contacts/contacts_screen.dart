import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../database/database_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactPreference> _preferences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.instance.getAllContactPreferences();
    if (list.isEmpty) {
      // Pre-seed sample contact preferences
      final sample = [
        const ContactPreference(
          contactName: 'Nimal Silva',
          translationEnabled: true,
          preferredMode: TranslationMode.autoSinhala,
        ),
        const ContactPreference(
          contactName: 'Kasun Bandara',
          translationEnabled: true,
          preferredMode: TranslationMode.autoEnglish,
        ),
        const ContactPreference(
          contactName: 'Sanduni Fernando',
          translationEnabled: true,
          preferredMode: TranslationMode.dual,
        ),
      ];
      for (final p in sample) {
        await DatabaseService.instance.setContactPreference(p);
      }
      setState(() {
        _preferences = sample;
        _isLoading = false;
      });
    } else {
      setState(() {
        _preferences = list;
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog([ContactPreference? existing]) {
    final nameCtrl = TextEditingController(text: existing?.contactName ?? '');
    var mode = existing?.preferredMode ?? TranslationMode.dual;
    var enabled = existing?.translationEnabled ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            existing != null ? 'Edit Contact Rule' : 'New Contact Rule',
            style: const TextStyle(color: AppColors.textPrimaryDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                enabled: existing == null,
                style: const TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'WhatsApp Contact or Group Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Auto-Translation', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14)),
                value: enabled,
                activeColor: AppColors.primaryAccent,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setModalState(() => enabled = val),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TranslationMode>(
                value: mode,
                dropdownColor: AppColors.surfaceDark,
                decoration: InputDecoration(
                  labelText: 'Preferred Target Output',
                  labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: AppColors.textPrimaryDark),
                items: const [
                  DropdownMenuItem(value: TranslationMode.autoSinhala, child: Text('Auto Sinhala')),
                  DropdownMenuItem(value: TranslationMode.autoEnglish, child: Text('Auto English')),
                  DropdownMenuItem(value: TranslationMode.dual, child: Text('Dual Translation')),
                  DropdownMenuItem(value: TranslationMode.smart, child: Text('Smart Auto')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => mode = val);
                },
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
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final pref = ContactPreference(
                  contactName: nameCtrl.text.trim(),
                  translationEnabled: enabled,
                  preferredMode: mode,
                );
                await DatabaseService.instance.setContactPreference(pref);
                Navigator.pop(ctx);
                _loadPreferences();
              },
              child: const Text('Save Rule', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Contact Preferences'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Rule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardDarkBorder),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.tune_rounded, color: AppColors.primaryAccent, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Customize translation behavior for specific people or groups. Unlisted contacts automatically follow global settings.',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _preferences.length,
                      itemBuilder: (context, index) {
                        final item = _preferences[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardDarkBorder),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                              child: Text(
                                item.contactName.isNotEmpty ? item.contactName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              item.contactName,
                              style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item.translationEnabled
                                  ? 'Active • ${item.preferredMode.name.toUpperCase()}'
                                  : 'Translation Paused',
                              style: TextStyle(
                                color: item.translationEnabled ? AppColors.accentGreen : AppColors.accentOrange,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMutedDark, size: 20),
                              onPressed: () async {
                                await DatabaseService.instance.deleteContactPreference(item.contactName);
                                _loadPreferences();
                              },
                            ),
                            onTap: () => _showAddEditDialog(item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
