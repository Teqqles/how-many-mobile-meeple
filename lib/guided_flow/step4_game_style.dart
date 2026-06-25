import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';
import 'package:how_many_mobile_meeple/components/step_header_card.dart';
import 'package:how_many_mobile_meeple/components/info_message_box.dart';
import 'package:how_many_mobile_meeple/tour_tips/tour_tip_keys.dart';

/// Step 4: Game Style
/// Allows users to select difficulty and mechanics
class Step4GameStyle extends StatefulWidget {
  const Step4GameStyle({super.key});

  @override
  State<Step4GameStyle> createState() => _Step4GameStyleState();
}

class _Step4GameStyleState extends State<Step4GameStyle> {
  // Mechanics grouped by category
  final Map<String, List<String>> _mechanicsCategories = {
    'Core Gameplay': [
      'Hand Management',
      'Set Collection',
      'Tile Placement',
      'Grid Movement',
    ],
    'Player Interaction': [
      'Cooperative Play',
      'Team-Based Game',
      'Simultaneous Action Selection',
    ],
    'Randomness & Input': [
      'Dice Rolling',
      'Card Drafting',
    ],
  };

  String _getDifficultyLabel(double weight) {
    if (weight == 0.0) return 'Any';
    if (weight <= 1.5) return 'Light';
    if (weight <= 2.5) return 'Gateway';
    if (weight <= 3.5) return 'Strategy';
    if (weight <= 4.0) return 'Heavy';
    return 'Expert';
  }

  String _getDifficultyDescription(double weight) {
    if (weight == 0.0) return 'Show games of any complexity';
    if (weight <= 1.5)
      return 'Easy to learn, quick to play (~${weight.toStringAsFixed(1)} weight)';
    if (weight <= 2.5)
      return 'Simple rules, engaging gameplay (~${weight.toStringAsFixed(1)} weight)';
    if (weight <= 3.5)
      return 'Deeper strategy, more complexity (~${weight.toStringAsFixed(1)} weight)';
    if (weight <= 4.0)
      return 'Complex rules, strategic depth (~${weight.toStringAsFixed(1)} weight)';
    return 'Maximum complexity and depth (~${weight.toStringAsFixed(1)} weight)';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final difficultySetting =
            model.settings.setting(Settings.filterComplexity.name);
        final mechanicsSetting =
            model.settings.setting(Settings.filterMechanics.name);

        final difficulty = difficultySetting.getDouble();
        final selectedMechanics = mechanicsSetting.value as List<dynamic>;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                const StepHeaderCard(
                  icon: Icons.style,
                  title: 'Game Style',
                  subtitle: 'Choose difficulty and mechanics',
                ),

                const SizedBox(height: 32),

                // Difficulty section
                Text(
                  'Difficulty',
                  key: TourTipKeys.complexitySlider,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Clickable difficulty panels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDifficultyPanel(
                      context,
                      'Light',
                      0.75,
                      difficulty,
                      (value) =>
                          _updateDifficulty(model, difficultySetting, value),
                    ),
                    _buildDifficultyPanel(
                      context,
                      'Gateway',
                      2.0,
                      difficulty,
                      (value) =>
                          _updateDifficulty(model, difficultySetting, value),
                    ),
                    _buildDifficultyPanel(
                      context,
                      'Strategy',
                      3.0,
                      difficulty,
                      (value) =>
                          _updateDifficulty(model, difficultySetting, value),
                    ),
                    _buildDifficultyPanel(
                      context,
                      'Heavy',
                      3.75,
                      difficulty,
                      (value) =>
                          _updateDifficulty(model, difficultySetting, value),
                    ),
                    _buildDifficultyPanel(
                      context,
                      'Expert',
                      4.5,
                      difficulty,
                      (value) =>
                          _updateDifficulty(model, difficultySetting, value),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Difficulty slider
                Slider.adaptive(
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  value: difficulty,
                  label: _getDifficultyLabel(difficulty),
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) {
                    setState(() {
                      difficultySetting.value = value;
                      difficultySetting.enabled = true;
                      model.settings.updateSetting(difficultySetting);
                      model.updateStore();
                      model.invalidateCache();
                    });
                  },
                ),

                const SizedBox(height: 8),

                // Difficulty description below slider
                InfoMessageBox(
                  message: _getDifficultyDescription(difficulty),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Mechanics section
                Text(
                  'Mechanics (Optional)',
                  key: TourTipKeys.mechanicsSection,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select preferred game mechanics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),

                // Mechanics by category
                ..._mechanicsCategories.entries.map((category) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category.key),
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: category.value.map((mechanic) {
                          final isSelected =
                              selectedMechanics.contains(mechanic);
                          return AppMechanicChip(
                            label: mechanic,
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  mechanicsSetting.value.add(mechanic);
                                } else {
                                  mechanicsSetting.value.remove(mechanic);
                                }
                                mechanicsSetting.enabled =
                                    mechanicsSetting.value.isNotEmpty;
                                model.settings.updateSetting(mechanicsSetting);
                                model.updateStore();
                                model.invalidateCache();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),

                // Info box
                InfoMessageBox(
                  message: selectedMechanics.isEmpty
                      ? 'Skip mechanics to see all game types'
                      : '${selectedMechanics.length} mechanic(s) selected',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Core Gameplay':
        return Icons.extension;
      case 'Player Interaction':
        return Icons.groups;
      case 'Randomness & Input':
        return Icons.casino;
      default:
        return Icons.category;
    }
  }

  /// Builds a clickable difficulty panel
  Widget _buildDifficultyPanel(
    BuildContext context,
    String label,
    double targetValue,
    double currentValue,
    Function(double) onTap,
  ) {
    final isSelected = _isInRange(currentValue, targetValue);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () => onTap(targetValue),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (isSelected) const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Checks if current value is in the range for a given difficulty level
  bool _isInRange(double currentValue, double targetValue) {
    // Define ranges for each difficulty level
    if (targetValue <= 0.75) {
      // Light: 0 - 1.5
      return currentValue <= 1.5;
    } else if (targetValue <= 2.0) {
      // Gateway: 1.5 - 2.5
      return currentValue > 1.5 && currentValue <= 2.5;
    } else if (targetValue <= 3.0) {
      // Strategy: 2.5 - 3.5
      return currentValue > 2.5 && currentValue <= 3.5;
    } else if (targetValue <= 3.75) {
      // Heavy: 3.5 - 4.0
      return currentValue > 3.5 && currentValue <= 4.0;
    } else {
      // Expert: 4.0 - 5.0
      return currentValue > 4.0;
    }
  }

  /// Updates difficulty setting when panel is tapped
  void _updateDifficulty(
      AppModel model, dynamic difficultySetting, double value) {
    setState(() {
      difficultySetting.value = value;
      difficultySetting.enabled = true;
      model.settings.updateSetting(difficultySetting);
      model.updateStore();
      model.invalidateCache();
    });
  }
}
