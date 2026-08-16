// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

class DisclaimerText extends StatelessWidget {
  final String data;
  final BuildContext context;

  const DisclaimerText(this.data, this.context, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(data, style: TextStyle(color: Theme.of(context).disabledColor));
  }
}

/// The shared page footer: BGG attribution on the left, app version and an
/// About link on the right, matching the home page. Required by the BGG API
/// usage guidelines.
class AppFooter extends StatelessWidget {
  const AppFooter({Key? key}) : super(key: key);

  Future<String> _appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).highlightColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: double.infinity, child: BGGAttribution()),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<String>(
                  future: _appVersion(),
                  builder: (context, snapshot) => DisclaimerText(
                    snapshot.hasData ? '(v:${snapshot.data})' : '',
                    context,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'About',
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(r.Router.aboutRoute),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
