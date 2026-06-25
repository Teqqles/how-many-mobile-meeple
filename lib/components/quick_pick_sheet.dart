import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

class QuickPickSheet extends StatefulWidget {
  const QuickPickSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const QuickPickSheet(),
    );
  }

  @override
  State<QuickPickSheet> createState() => _QuickPickSheetState();
}

class _QuickPickSheetState extends State<QuickPickSheet> {
  int? _selectedPlayers;
  int? _selectedMaxTime;
  double? _selectedWeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restoreFromModel();
  }

  void _restoreFromModel() {
    final model = AppModel.of(context, listen: false);

    final playerSetting =
        model.settings.setting(Settings.filterNumberOfPlayers.name);
    if (playerSetting.enabled &&
        _playerOptions.containsValue(playerSetting.value)) {
      _selectedPlayers = playerSetting.value as int;
    }

    final maxTimeSetting =
        model.settings.setting(Settings.filterMaximumTimeToPlay.name);
    if (maxTimeSetting.enabled &&
        _timeOptions.containsValue(maxTimeSetting.value)) {
      _selectedMaxTime = maxTimeSetting.value as int;
    }

    final complexitySetting =
        model.settings.setting(Settings.filterComplexity.name);
    if (complexitySetting.enabled &&
        _weightOptions.containsValue(complexitySetting.value)) {
      _selectedWeight = complexitySetting.value as double;
    }
  }

  static const Map<String, int> _playerOptions = {
    '2': 2,
    '3-4': 4,
    '5+': 5,
  };

  static const Map<String, int> _timeOptions = {
    '< 30 min': 30,
    '30-60 min': 60,
    '~60 min': 90,
    '90+ min': 120,
  };

  static const Map<String, double> _weightOptions = {
    'Light': 2.0,
    'Medium': 3.0,
    'Heavy': 5.0,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Quick Pick',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Pick what matters, skip what doesn\'t',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildChipRow(
            icon: Icons.people,
            label: 'Players',
            options: _playerOptions,
            selected: _selectedPlayers,
            onChanged: (value) => setState(() => _selectedPlayers = value),
          ),
          const SizedBox(height: 16),
          _buildChipRow(
            icon: Icons.schedule,
            label: 'Time',
            options: _timeOptions,
            selected: _selectedMaxTime,
            onChanged: (value) => setState(() => _selectedMaxTime = value),
          ),
          const SizedBox(height: 16),
          _buildChipRow(
            icon: Icons.fitness_center,
            label: 'Weight',
            options: _weightOptions,
            selected: _selectedWeight,
            onChanged: (value) => setState(() => _selectedWeight = value),
          ),
          const SizedBox(height: 28),
          Consumer<AppModel>(
            builder: (context, model, child) {
              final hasSource = model.items.itemList.isNotEmpty;
              return FilledButton.icon(
                onPressed: hasSource ? () => _applyAndGo(context) : null,
                icon: const Icon(Icons.casino, size: 24),
                label: Text(
                  hasSource ? 'Go!' : 'Add a source first',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow<T>({
    required IconData icon,
    required String label,
    required Map<String, T> options,
    required T? selected,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.entries.map((entry) {
            return AppChoiceChip(
              label: entry.key,
              selected: selected == entry.value,
              onSelected: (isSelected) {
                onChanged(isSelected ? entry.value : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyAndGo(BuildContext context) {
    final model = AppModel.of(context, listen: false);

    if (_selectedPlayers != null) {
      final playerSetting =
          model.settings.setting(Settings.filterNumberOfPlayers.name);
      playerSetting.value = _selectedPlayers;
      playerSetting.enabled = true;
      model.settings.updateSetting(playerSetting);
    }

    if (_selectedMaxTime != null) {
      final minTimeSetting =
          model.settings.setting(Settings.filterMinimumTimeToPlay.name);
      final maxTimeSetting =
          model.settings.setting(Settings.filterMaximumTimeToPlay.name);
      minTimeSetting.value = (_selectedMaxTime! * 0.5).floor();
      maxTimeSetting.value = _selectedMaxTime;
      minTimeSetting.enabled = true;
      maxTimeSetting.enabled = true;
      model.settings.updateSetting(minTimeSetting);
      model.settings.updateSetting(maxTimeSetting);
    }

    if (_selectedWeight != null) {
      final complexitySetting =
          model.settings.setting(Settings.filterComplexity.name);
      complexitySetting.value = _selectedWeight;
      complexitySetting.enabled = true;
      model.settings.updateSetting(complexitySetting);
    }

    model.invalidateCache();
    model.updateStore();

    Navigator.of(context).pop();

    final randomPageSettings = r.Router.generateRouteSettings(
      r.Router.randomRoute,
      model,
    );
    model.pageRefreshed = true;
    Navigator.of(context).pushReplacementNamed(
      randomPageSettings.name!,
      arguments: randomPageSettings.arguments,
    );
  }
}
