import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';
import 'package:how_many_mobile_meeple/components/step_header_card.dart';
import 'package:how_many_mobile_meeple/components/info_message_box.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_keys.dart';

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

        final minTime = minTimeSetting.getInt();
        final maxTime = maxTimeSetting.getInt();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                const StepHeaderCard(
                  icon: Icons.schedule,
                  title: 'Time Available',
                  subtitle: 'How long do you want to play?',
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
                        key: TourTipKeys.timeRangeSlider,
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

                    return AppChoiceChip(
                      label: preset.key,
                      selected: isSelected,
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
                            minTimeSetting.value =
                                Settings.inferMinTime(targetTime);
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
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Info box
                const InfoMessageBox.info(
                  message: 'We\'ll find games that fit within your time budget',
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
