import 'package:flutter/material.dart';
import '../../services/auto_update_service.dart';
import '../../widgets/update_dialog_helper.dart';

class AutoUpdateListener extends StatefulWidget {
  final Widget child;

  const AutoUpdateListener({Key? key, required this.child}) : super(key: key);

  @override
  State<AutoUpdateListener> createState() => _AutoUpdateListenerState();
}

class _AutoUpdateListenerState extends State<AutoUpdateListener> {
  @override
  void initState() {
    super.initState();
    // Check for updates shortly after the app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSilentUpdate();
    });
  }

  Future<void> _checkSilentUpdate() async {
    // Wait 2 seconds so splash/home renders cleanly
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final updateInfo = await AutoUpdateService.checkForUpdate();
      if (updateInfo != null && mounted) {
        UpdateDialogHelper.showUpdatePrompt(context, updateInfo);
      }
    } catch (_) {
      // Silent catch so it never crashes or disturbs the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
