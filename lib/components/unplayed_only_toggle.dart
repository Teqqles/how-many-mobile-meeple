import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/components/app_switch.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';

enum UnplayedToggleStyle { compact, card }

class UnplayedOnlyToggle extends StatelessWidget {
  final UnplayedToggleStyle style;

  const UnplayedOnlyToggle({
    super.key,
    this.style = UnplayedToggleStyle.card,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final hasPrimaryPlayer = model.primaryPlayer != null;
        final setting =
            model.settings.setting(Settings.filterShelfOfShameOnly.name);
        final isActive = setting.enabled && setting.getBool();

        void toggle(bool value) {
          setting.value = value;
          setting.enabled = value;
          model.settings.updateSetting(setting);
          model.updateStore();
          model.invalidateCache();
        }

        if (style == UnplayedToggleStyle.compact) {
          return _buildCompact(context, hasPrimaryPlayer, isActive, toggle);
        }
        return _buildCard(context, hasPrimaryPlayer, isActive, toggle);
      },
    );
  }

  Widget _buildCompact(BuildContext context, bool hasPrimaryPlayer,
      bool isActive, ValueChanged<bool> onToggle) {
    return Container(
      height: 35,
      color: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.shelves,
                    size: 16,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Unplayed Only (Shelf of Shame)',
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(
            value: isActive,
            onChanged: hasPrimaryPlayer ? onToggle : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool hasPrimaryPlayer, bool isActive,
      ValueChanged<bool> onToggle) {
    return InkWell(
      onTap: hasPrimaryPlayer ? () => onToggle(!isActive) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withAlpha(80),
          ),
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer.withAlpha(80)
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.shelves,
                size: 20,
                color: hasPrimaryPlayer
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unplayed only',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasPrimaryPlayer
                              ? null
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    hasPrimaryPlayer
                        ? 'Only show games from your shelf of shame'
                        : 'Set a primary player to enable',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            AppSwitch(
              value: isActive,
              onChanged: hasPrimaryPlayer ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}
