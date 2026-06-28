import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/components/empty_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:how_many_mobile_meeple/about_page.dart';

/// Settings Summary Page
/// Shows current settings in both friendly terms and raw values
class SettingsSummaryPage extends StatelessWidget with AppPage {
  static final String route = "Settings-summary-page";

  SettingsSummaryPage({super.key});

  String _getDifficultyLabel(double weight) {
    if (weight <= 1.5) return 'Light';
    if (weight <= 2.5) return 'Gateway';
    if (weight <= 3.5) return 'Strategy';
    if (weight <= 4.0) return 'Heavy';
    return 'Expert';
  }

  String _getTimeLabel(int min, int max) {
    if (max <= 30) return 'Quick';
    if (max <= 60) return 'Short';
    if (max <= 90) return 'Medium';
    if (max <= 120) return 'Long';
    return 'Epic';
  }

  @override
  Widget build(BuildContext context) {
    final model = AppModel.of(context, listen: false);

    return Scaffold(
      appBar: HowManyMeepleAppBar(
        'My Settings',
        hasSaveDialog: false,
        isHomePage: false,
        model: model,
        context: context,
      ),
      drawer: const FeatureDrawer(),
      endDrawer: pageDrawer(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Game Preferences',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here\'s what you\'re looking for',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sources
              _buildSourcesSection(context, model),

              const SizedBox(height: 16),

              // Players
              _buildPlayersSection(context, model),

              const SizedBox(height: 16),

              // Time
              _buildTimeSection(context, model),

              const SizedBox(height: 16),

              // Difficulty
              _buildDifficultySection(context, model),

              const SizedBox(height: 16),

              // Rating
              _buildRatingSection(context, model),

              const SizedBox(height: 16),

              // Mechanics
              _buildMechanicsSection(context, model),

              const SizedBox(height: 16),

              // Other Filters
              _buildOtherFiltersSection(context, model),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Navigate to game results
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.casino),
                      label: const Text('Find Games'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _buildSourcesSection(BuildContext context, AppModel model) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.source,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Game Sources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (model.items.itemList.isEmpty)
              Text(
                'No sources selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...model.items.itemList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          item.itemType.toString().contains('collection')
                              ? Icons.person
                              : Icons.list,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Chip(
                          label: Text(
                            item.itemType.toString().contains('collection')
                                ? 'Collection'
                                : 'Geeklist',
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersSection(BuildContext context, AppModel model) {
    final playerSetting =
        model.settings.setting(Settings.filterNumberOfPlayers.name);
    final players = playerSetting.getInt();

    return _buildSettingCard(
      context,
      icon: Icons.people,
      title: 'Player Count',
      friendlyValue: '$players ${players == 1 ? 'player' : 'players'}',
      technicalValue: 'Filter: minplayers ≤ $players ≤ maxplayers',
      isEnabled: playerSetting.enabled,
    );
  }

  Widget _buildTimeSection(BuildContext context, AppModel model) {
    final minSetting =
        model.settings.setting(Settings.filterMinimumTimeToPlay.name);
    final maxSetting =
        model.settings.setting(Settings.filterMaximumTimeToPlay.name);
    final min = minSetting.getInt();
    final max = maxSetting.getInt();

    return _buildSettingCard(
      context,
      icon: Icons.schedule,
      title: 'Play Time',
      friendlyValue:
          '${_getTimeLabel(min, max)} (${AppCommon.minutesToTime(min)} - ${AppCommon.minutesToTime(max)})',
      technicalValue: 'Filter: $min ≤ maxplaytime ≤ $max minutes',
      isEnabled: minSetting.enabled,
    );
  }

  Widget _buildDifficultySection(BuildContext context, AppModel model) {
    final setting = model.settings.setting(Settings.filterComplexity.name);
    final complexity = setting.getDouble();

    return _buildSettingCard(
      context,
      icon: Icons.style,
      title: 'Difficulty',
      friendlyValue:
          '${_getDifficultyLabel(complexity)} (≤ ${complexity.toStringAsFixed(2)})',
      technicalValue: 'Filter: averageweight ≤ $complexity',
      isEnabled: setting.enabled,
    );
  }

  Widget _buildRatingSection(BuildContext context, AppModel model) {
    final setting = model.settings.setting(Settings.filterMinRating.name);
    final rating = setting.getDouble();

    return _buildSettingCard(
      context,
      icon: Icons.star,
      title: 'Minimum Rating',
      friendlyValue: '${rating.toStringAsFixed(1)} / 10',
      technicalValue: 'Filter: average ≥ $rating',
      isEnabled: setting.enabled,
    );
  }

  Widget _buildMechanicsSection(BuildContext context, AppModel model) {
    final setting = model.settings.setting(Settings.filterMechanics.name);
    final mechanics = setting.value as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Game Mechanics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (!setting.enabled)
                  Chip(
                    label:
                        const Text('Disabled', style: TextStyle(fontSize: 10)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (mechanics.isEmpty)
              Text(
                'No mechanics selected - showing all types',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mechanics.map((mechanic) {
                  return Chip(
                    label: Text(mechanic.toString()),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  );
                }).toList(),
              ),
            if (mechanics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Technical: ${mechanics.length} mechanics selected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOtherFiltersSection(BuildContext context, AppModel model) {
    final expansions =
        model.settings.setting(Settings.filterIncludesExpansions.name);
    final recommended =
        model.settings.setting(Settings.filterUsingUserRecommendations.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Additional Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBooleanSetting(
              context,
              'Include Expansions',
              expansions.getBool(),
              expansions.enabled,
            ),
            const SizedBox(height: 8),
            _buildBooleanSetting(
              context,
              'Use Recommended Player Counts',
              recommended.getBool(),
              recommended.enabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String friendlyValue,
    required String technicalValue,
    required bool isEnabled,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (!isEnabled)
                  Chip(
                    label:
                        const Text('Disabled', style: TextStyle(fontSize: 10)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              friendlyValue,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.code,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      technicalValue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooleanSetting(
    BuildContext context,
    String label,
    bool value,
    bool isEnabled,
  ) {
    return Row(
      children: [
        Icon(
          value ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: value ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: !isEnabled ? TextDecoration.lineThrough : null,
                ),
          ),
        ),
        Text(
          value ? 'Yes' : 'No',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      height: 60,
      color: Theme.of(context).highlightColor,
      child: FutureBuilder<Widget>(
        future: _footerDisplay(context),
        builder: (context, snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          return EmptyWidget();
        },
      ),
    );
  }

  Future<Widget> _footerDisplay(BuildContext context) async {
    var version = await _getAppVersion();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          height: double.infinity,
          child: BGGAttribution(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DisclaimerText("(v:$version)", context),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
