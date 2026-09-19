import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/native_bridge_service.dart';
import '../../services/translation_service.dart';
import '../home/home_screen.dart';

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    setState(() => _isChecking = true);
    final isGranted = await NativeBridgeService.isNotificationListenerEnabled();
    if (mounted) {
      setState(() => _isChecking = false);
      if (isGranted) {
        // Automatically progress once enabled
        _navigateToDashboard();
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationContainer()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissionAsync = ref.watch(permissionStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Icon Header
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primaryAccent,
                    size: 34,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Notification Access',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'LingoFlow needs notification access to detect incoming WhatsApp messages and provide instant translations without opening WhatsApp.',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Security & Privacy Guarantee Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardDarkBorder),
                ),
                child: Column(
                  children: [
                    _buildPrivacyItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Zero WhatsApp Account Access',
                      subtitle: 'We never request or touch your login, chats, or passwords.',
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyItem(
                      icon: Icons.visibility_off_outlined,
                      title: 'WhatsApp Notifications Only',
                      subtitle: 'LingoFlow filters specifically for supported messaging apps.',
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyItem(
                      icon: Icons.memory_rounded,
                      title: 'Local On-Device Engine',
                      subtitle: 'Singlish messages are parsed locally on your phone.',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Status Indicator
              permissionAsync.when(
                data: (isGranted) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isGranted ? AppColors.accentGreen.withOpacity(0.12) : AppColors.accentOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isGranted ? AppColors.accentGreen.withOpacity(0.3) : AppColors.accentOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: isGranted ? AppColors.accentGreen : AppColors.accentOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isGranted ? 'Notification Access is Enabled' : 'Notification Access: Disabled',
                        style: TextStyle(
                          color: isGranted ? AppColors.accentGreen : AppColors.accentOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await NativeBridgeService.openNotificationListenerSettings();
                  },
                  child: const Text(
                    'Enable Notification Access',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => _navigateToDashboard(),
                  child: const Text(
                    'Skip for Now',
                    style: TextStyle(color: AppColors.textMutedDark, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyItem({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
