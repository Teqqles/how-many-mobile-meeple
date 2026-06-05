import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:how_many_mobile_meeple/save_dialog.dart';

/// Step 5: Final Actions
/// Shows main actions and mode toggle
class Step5FinalActions extends StatelessWidget {
  final VoidCallback onSwitchToAdvanced;

  const Step5FinalActions({
    super.key,
    required this.onSwitchToAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 48,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Ready to Find Games!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Choose how you\'d like to explore',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Primary action - Random Game
                FilledButton.icon(
                  onPressed: () {
                    final randomPageSettings = r.Router.generateRouteSettings(
                      r.Router.randomRoute,
                      model,
                    );
                    _navigateToPage(context, randomPageSettings);
                  },
                  icon: const Icon(Icons.casino, size: 24),
                  label: const Text(
                    'Random Game',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary action - View List
                OutlinedButton.icon(
                  onPressed: () {
                    final listPageSettings = r.Router.generateRouteSettings(
                      r.Router.listRoute,
                      model,
                    );
                    _navigateToPage(context, listPageSettings);
                  },
                  icon: const Icon(Icons.list, size: 24),
                  label: const Text(
                    'View List',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  ),
                ),

                const SizedBox(height: 12),

                // Tertiary action - Review Settings
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(r.Router.settingsRoute);
                  },
                  icon: const Icon(Icons.settings_outlined, size: 24),
                  label: const Text(
                    'Review My Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  ),
                ),

                const SizedBox(height: 12),

                // Quaternary action - Save Settings
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SaveDialog(model: model),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save These Settings'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Advanced mode toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.settings,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Need more control?',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Switch to Advanced Mode for full control over all filters and settings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onSwitchToAdvanced,
                          icon: const Icon(Icons.tune),
                          label: const Text('Switch to Advanced Mode'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
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
      },
    );
  }

  void _navigateToPage(BuildContext context, RouteSettings pageSettings) {
    final model = AppModel.of(context, listen: false);
    model.pageRefreshed = true;
    Navigator.of(context).pushReplacementNamed(
      pageSettings.name!,
      arguments: pageSettings.arguments,
    );
  }
}
