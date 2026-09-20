import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/native_bridge_service.dart';
import '../../services/auto_update_service.dart';

class UpdateDialogHelper {
  static void showUpdatePrompt(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => LiveUpdateDialog(info: info),
    );
  }
}

class LiveUpdateDialog extends StatefulWidget {
  final AppUpdateInfo info;

  const LiveUpdateDialog({Key? key, required this.info}) : super(key: key);

  @override
  State<LiveUpdateDialog> createState() => _LiveUpdateDialogState();
}

enum UpdateState { prompt, downloading, readyToInstall, error }

class _LiveUpdateDialogState extends State<LiveUpdateDialog> {
  UpdateState _state = UpdateState.prompt;
  double _progress = 0.0;
  double _downloadedMb = 0.0;
  double _totalMb = 0.0;
  String _statusText = 'Preparing download...';
  String? _downloadedFilePath;
  String _errorMessage = '';

  Future<void> _startDownload() async {
    setState(() {
      _state = UpdateState.downloading;
      _progress = 0.0;
      _downloadedMb = 0.0;
      _totalMb = widget.info.apkSizeMb > 0 ? widget.info.apkSizeMb : 50.8;
      _statusText = 'Connecting to download server...';
    });

    try {
      final filePath = await AutoUpdateService.downloadApkWithProgress(
        apkUrl: widget.info.apkUrl,
        onProgress: (progress, downloadedMb, totalMb) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _downloadedMb = downloadedMb;
              _totalMb = totalMb > 0 ? totalMb : widget.info.apkSizeMb;
              _statusText = 'Downloading update package...';
            });
          }
        },
      );

      if (!mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        setState(() {
          _state = UpdateState.readyToInstall;
          _progress = 1.0;
          _downloadedFilePath = filePath;
          _statusText = 'Download complete! Opening installer...';
        });

        // Short delay so user sees 100% completion before installer opens
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          await _launchInstaller(filePath);
        }
      } else {
        // Fallback to background system download if stream failed
        setState(() {
          _statusText = 'Switching to background downloader...';
        });
        await AutoUpdateService.triggerUpdate(widget.info.apkUrl);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloading update in notification tray...'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = UpdateState.error;
          _errorMessage = e.toString();
          _statusText = 'Download interrupted';
        });
      }
    }
  }

  Future<void> _launchInstaller(String filePath) async {
    try {
      final canInstall = await NativeBridgeService.canRequestPackageInstalls();
      if (!canInstall) {
        await NativeBridgeService.openInstallPermissionSettings();
      }
      await AutoUpdateService.installApk(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open installer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    switch (_state) {
      case UpdateState.prompt:
        return Row(
          children: const [
            Icon(Icons.system_update_rounded, color: AppColors.primaryAccent),
            SizedBox(width: 10),
            Text(
              'Update Available!',
              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        );
      case UpdateState.downloading:
        return Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Updating LingoFlow...',
              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        );
      case UpdateState.readyToInstall:
        return Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.statusActive, size: 24),
            SizedBox(width: 10),
            Text(
              'Ready to Install!',
              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        );
      case UpdateState.error:
        return Row(
          children: const [
            Icon(Icons.error_outline_rounded, color: Colors.orangeAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'Update Error',
              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        );
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case UpdateState.prompt:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
              ),
              child: Text(
                'LingoFlow v${widget.info.versionName} • ${widget.info.apkSizeMb.toStringAsFixed(1)} MB',
                style: const TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "What's New in this update:",
              style: TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.info.releaseNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚡ ', style: TextStyle(fontSize: 12)),
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
        );

      case UpdateState.downloading:
        final percent = (_progress * 100).toInt();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${_downloadedMb.toStringAsFixed(1)} MB / ${_totalMb.toStringAsFixed(1)} MB',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 12,
                backgroundColor: AppColors.cardDarkBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusText,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );

      case UpdateState.readyToInstall:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update package is ready! Tap below if the Android installer did not open automatically.',
              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusActive.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusActive.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.security_rounded, color: AppColors.statusActive, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safe & verified APK package from official repository.',
                      style: TextStyle(color: AppColors.statusActive, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case UpdateState.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _statusText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Failed to download update file. Please verify network connection.',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions() {
    switch (_state) {
      case UpdateState.prompt:
        return [
          if (!widget.info.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later', style: TextStyle(color: AppColors.textMutedDark)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _startDownload,
            child: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ];

      case UpdateState.downloading:
        return [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download continuing in background...')),
              );
            },
            child: const Text('Hide', style: TextStyle(color: AppColors.textMutedDark)),
          ),
        ];

      case UpdateState.readyToInstall:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.textMutedDark)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.install_mobile_rounded, color: Colors.white, size: 18),
            label: const Text('Open Installer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusActive,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_downloadedFilePath != null) {
                _launchInstaller(_downloadedFilePath!);
              }
            },
          ),
        ];

      case UpdateState.error:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMutedDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _startDownload,
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ];
    }
  }
}
