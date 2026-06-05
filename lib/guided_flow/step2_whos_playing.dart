import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/str_cast.dart';

/// Step 2: Who's Playing?
/// Allows users to select player count with presets
class Step2WhosPlaying extends StatefulWidget {
  const Step2WhosPlaying({super.key});

  @override
  State<Step2WhosPlaying> createState() => _Step2WhosPlayingState();
}

class _Step2WhosPlayingState extends State<Step2WhosPlaying> {
  // Quick presets
  final Map<String, int> _presets = {
    'Solo': 1,
    'Couple': 2,
    'Family': 4,
    'Gamers': 5,
    'Party': 8,
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final playerSetting = model.settings.setting(Settings.filterNumberOfPlayers.name);
        final currentPlayers = StrCast(playerSetting.value).castToInt();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Who\'s Playing?',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select the number of players',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Player count display
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$currentPlayers',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        currentPlayers == 1 ? 'player' : 'players',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Player slider
                Slider.adaptive(
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  value: currentPlayers.toDouble(),
                  label: '$currentPlayers players',
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      playerSetting.value = value.floor();
                      playerSetting.enabled = true;
                      model.settings.updateSetting(playerSetting);
                      model.updateStore();
                      model.invalidateCache();
                    });
                  },
                ),

                const SizedBox(height: 8),

                // Min/Max labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      '10+',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick presets
                Text(
                  'Quick Presets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.entries.map((preset) {
                    final isSelected = currentPlayers == preset.value;
                    return FilterChip(
                      label: Text('${preset.key} (${preset.value})'),
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: isSelected
                          ? Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSecondary,
                            )
                          : null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            playerSetting.value = preset.value;
                            playerSetting.enabled = true;
                            model.settings.updateSetting(playerSetting);
                            model.updateStore();
                            model.invalidateCache();
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'We\'ll find games that work well with this player count',
                          style: Theme.of(context).textTheme.bodySmall,
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
}
