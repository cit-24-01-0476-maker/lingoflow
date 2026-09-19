import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auto_update_service.dart';

class UpdateDialogHelper {
  static void showUpdatePrompt(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.system_update_rounded, color: AppColors.primaryAccent),
            SizedBox(width: 10),
            Text(
              'Update Available!',
              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LingoFlow v${info.versionName} is ready to install (${info.apkSizeMb} MB).',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
            ),
            const SizedBox(height: 14),
            const Text(
              "What's New:",
              style: TextStyle(color: AppColors.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...info.releaseNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.accentCyan)),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later', style: TextStyle(color: AppColors.textMutedDark)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Downloading update in background... Check your notifications!'),
                  duration: Duration(seconds: 4),
                ),
              );
              await AutoUpdateService.triggerUpdate(info.apkUrl);
            },
            child: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
