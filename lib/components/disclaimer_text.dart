import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DisclaimerText extends StatelessWidget {
  final String data;
  final BuildContext context;

  const DisclaimerText(this.data, this.context, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(data,
        style: TextStyle(color: Theme.of(context).disabledColor));
  }
}

class BGGAttribution extends StatelessWidget {
  static const String bggLogoAsset = 'lib/images/powered_by_bgg.png';
  static const String bggWebsiteUrl = 'https://boardgamegeek.com';

  const BGGAttribution({Key? key}) : super(key: key);

  Future<void> _launchBGGUrl() async {
    final Uri url = Uri.parse(bggWebsiteUrl);
    // On web, open in a new tab. On mobile, open in default browser.
    if (kIsWeb) {
      if (!await launchUrl(url, webOnlyWindowName: '_blank')) {
        throw Exception('Could not launch $bggWebsiteUrl');
      }
    } else {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $bggWebsiteUrl');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launchBGGUrl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Image.asset(
          bggLogoAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Powered by Board Game Geek',
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
