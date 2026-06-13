import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/pwa/pwa_install_service.dart';

class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
    PwaInstallService.onPromptReady(_onPromptReady);
    PwaInstallService.onInstalled(_onInstalled);
  }

  void _onInstalled() {
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _checkVisibility() async {
    if (!PwaInstallService.isWeb) return;
    if (PwaInstallService.isAlreadyInstalled) return;
    final dismissed = await PwaInstallService.wasBannerDismissed();
    if (!dismissed && mounted) {
      setState(() => _visible = true);
    }
  }

  void _onPromptReady() {
    if (mounted && _visible) setState(() {});
  }

  Future<void> _dismiss() async {
    await PwaInstallService.markBannerDismissed();
    if (mounted) setState(() => _visible = false);
  }

  void _install(BuildContext context) {
    if (PwaInstallService.isInstallAvailable) {
      PwaInstallService.triggerInstall(onResult: (accepted) {
        if (mounted) setState(() => _visible = false);
      });
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Install on Home Screen'),
          content: const Text(
            'To install, use your browser\'s install option:\n\n'
            '• Chrome / Edge: tap the install icon (⊕) in the address bar\n'
            '• Safari (iOS): tap Share → Add to Home Screen',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    const bannerColor = Color(0xFFFF8F00); // amber 800
    const textColor = Colors.white;

    return Material(
      color: bannerColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _install(context),
                child: Row(
                  children: [
                    const Icon(Icons.install_mobile,
                        size: 20, color: textColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add to your home screen for quick access',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textColor,
                            ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Install',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _dismiss,
              color: textColor,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
