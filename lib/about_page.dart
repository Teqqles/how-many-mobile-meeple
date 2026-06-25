import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<Map<String, dynamic>> _loadAboutData() async {
    final jsonStr = await rootBundle.loadString('lib/assets/about_data.json');
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_loadAboutData(), _getAppVersion()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data![0] as Map<String, dynamic>;
          final version = snapshot.data![1] as String;
          final recentChanges = data['recent_changes'] as List<dynamic>;
          final upcoming = data['upcoming'] as List<dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context, version),
              const SizedBox(height: 24),
              _buildDescription(context),
              const SizedBox(height: 24),
              _buildRecentChanges(
                  context, data['since_version'], recentChanges),
              const SizedBox(height: 24),
              _buildUpcoming(context, upcoming),
              const SizedBox(height: 24),
              _buildContributors(context),
              const SizedBox(height: 24),
              _buildLinks(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String version) {
    return Column(
      children: [
        Image.asset('lib/images/launcher_icon.png', width: 72, height: 72),
        const SizedBox(height: 12),
        Text(
          'How Many Meeple?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'v$version',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How Many Meeple? helps you pick the perfect board game for your '
              'group. Enter your BoardGameGeek collection or a geeklist, set your '
              'player count, time, and preferences, and get tailored recommendations.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChanges(
      BuildContext context, String sinceVersion, List<dynamic> changes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's New (since $sinceVersion)",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (changes.isEmpty)
              Text(
                'No changes recorded for this release.',
                style: TextStyle(color: Theme.of(context).disabledColor),
              )
            else
              ...changes.map((change) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          change['type'] == 'feat'
                              ? Icons.auto_awesome
                              : Icons.build,
                          size: 16,
                          color: change['type'] == 'feat'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(change['description'] as String),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcoming(BuildContext context, List<dynamic> issues) {
    final bugs =
        issues.where((i) => (i['labels'] as List).contains('bug')).toList();
    final features =
        issues.where((i) => !(i['labels'] as List).contains('bug')).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (features.isNotEmpty) ...[
              Text(
                'Features',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              ...features.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(issue['title'] as String),
                        ),
                      ],
                    ),
                  )),
            ],
            if (bugs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Bug Fixes',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 4),
              ...bugs.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bug_report_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(issue['title'] as String),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributors(BuildContext context) {
    const contributors = [
      {'name': 'David Long', 'url': 'https://github.com/Teqqles'},
      {'name': 'DragonC', 'url': 'https://boardgamegeek.com/profile/DragonC'},
      {'name': 'Steve Whalley', 'url': 'https://github.com/oldstevekenobi'},
      {'name': 'tjforryan', 'url': 'https://github.com/tjforryan'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contributors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...contributors.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => _launchUrl(c['url']!),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          c['name']!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLinks(BuildContext context) {
    const links = [
      {
        'label': 'Frontend (Flutter)',
        'url': 'https://github.com/Teqqles/how-many-mobile-meeple',
        'icon': Icons.phone_android,
      },
      {
        'label': 'Backend API',
        'url': 'https://github.com/how-many-meeple/bgg-game-selector-api',
        'icon': Icons.cloud_outlined,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Source Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...links.map((link) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => _launchUrl(link['url'] as String),
                    child: Row(
                      children: [
                        Icon(link['icon'] as IconData,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          link['label'] as String,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
