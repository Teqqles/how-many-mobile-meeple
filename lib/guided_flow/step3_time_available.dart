import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/str_cast.dart';
import 'package:how_many_mobile_meeple/app_common.dart';

/// Step 3: Time Available
/// Allows users to select game duration with quick presets
class Step3TimeAvailable extends StatefulWidget {
  const Step3TimeAvailable({super.key});

  @override
  State<Step3TimeAvailable> createState() => _Step3TimeAvailableState();
}

class _Step3TimeAvailableState extends State<Step3TimeAvailable> {
  // Quick time presets (in minutes)
  final Map<String, int> _timePresets = {
    '30 min': 30,
    '60 min': 60,
    '90 min': 90,
    '2h+': 120,
  };

  String _getSemanticLabel(int minutes) {
    if (minutes <= 30) return 'Quick';
    if (minutes <= 60) return 'Short';
    if (minutes <= 90) return 'Medium';
    if (minutes <= 120) return 'Long';
    return 'Epic';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final minTimeSetting =
            model.settings.setting(Settings.filterMinimumTimeToPlay.name);
        final maxTimeSetting =
            model.settings.setting(Settings.filterMaximumTimeToPlay.name);

        final minTime = StrCast(minTimeSetting.value).castToInt();
        final maxTime = StrCast(maxTimeSetting.value).castToInt();

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
                        Icons.schedule,
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
                            'Time Available',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How long do you want to play?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Time range display
                Center(
                  child: Column(
                    children: [
                      Text(
                        AppCommon.minutesToTime(minTime) +
                            ' - ' +
                            AppCommon.minutesToTime(maxTime),
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getSemanticLabel(maxTime),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Range slider
                RangeSlider(
                  min: 15.0,
                  max: 300.0,
                  divisions: 19,
                  values: RangeValues(minTime.toDouble(), maxTime.toDouble()),
                  labels: RangeLabels(
                    AppCommon.minutesToTime(minTime),
                    AppCommon.minutesToTime(maxTime),
                  ),
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (RangeValues values) {
                    setState(() {
                      minTimeSetting.value = values.start.floor();
                      maxTimeSetting.value = values.end.floor();
                      minTimeSetting.enabled = true;
                      maxTimeSetting.enabled = true;
                      model.settings.updateSetting(minTimeSetting);
                      model.settings.updateSetting(maxTimeSetting);
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
                      'Quick\n(15m)',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      'Epic\n(5h)',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick select chips
                Text(
                  'Quick Select',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timePresets.entries.map((preset) {
                    final targetTime = preset.value;
                    final isSelected =
                        maxTime == targetTime && minTime <= targetTime / 2;

                    return ChoiceChip(
                      label: Text(preset.key),
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        _getTimeIcon(targetTime),
                        size: 18,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            // Set time range around the preset
                            minTimeSetting.value = (targetTime * 0.5).floor();
                            maxTimeSetting.value = targetTime;
                            minTimeSetting.enabled = true;
                            maxTimeSetting.enabled = true;
                            model.settings.updateSetting(minTimeSetting);
                            model.settings.updateSetting(maxTimeSetting);
                            model.updateStore();
                            model.invalidateCache();
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'We\'ll find games that fit within your time budget',
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

  IconData _getTimeIcon(int minutes) {
    if (minutes <= 30) return Icons.flash_on;
    if (minutes <= 60) return Icons.access_time;
    if (minutes <= 90) return Icons.schedule;
    return Icons.event;
  }
}
