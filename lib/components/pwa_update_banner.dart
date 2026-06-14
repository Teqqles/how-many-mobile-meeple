import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/pwa/pwa_update_service.dart';
import 'package:universal_html/js.dart' as js;

class PwaUpdateBanner extends StatefulWidget {
  const PwaUpdateBanner({super.key});

  @override
  State<PwaUpdateBanner> createState() => _PwaUpdateBannerState();
}

class _PwaUpdateBannerState extends State<PwaUpdateBanner> {
  bool _visible = false;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = PwaUpdateService.updateAvailable.listen((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _reload() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ['window.location.reload()']);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    const bannerColor = Color(0xFF1565C0); // blue 800 — matches theme_color
    const textColor = Colors.white;

    return Material(
      color: bannerColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.system_update_alt, size: 20, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'A new version is available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
              ),
            ),
            TextButton(
              onPressed: _reload,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
