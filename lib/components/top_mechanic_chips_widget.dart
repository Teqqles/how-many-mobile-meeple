import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';

/// One-tap chips for the mechanics most common in the user's collection,
/// sourced from analytics. Renders nothing until analytics arrive, so it
/// degrades gracefully while the endpoint is not-ready or unavailable.
class TopMechanicChipsWidget extends StatelessWidget {
  const TopMechanicChipsWidget({
    super.key,
    this.alignment = WrapAlignment.center,
  });

  /// Horizontal alignment of the label and chip row. Centered for the filter
  /// list; [WrapAlignment.start] for the left-aligned guided-flow card.
  final WrapAlignment alignment;

  static const int maxChips = 10;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final mechanics = model.topMechanics.take(maxChips).toList();
        if (mechanics.isEmpty) return const SizedBox.shrink();

        final setting = model.settings.setting(Settings.filterMechanics.name);
        final start = alignment == WrapAlignment.start;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: start
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Popular in your collection',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: alignment,
                spacing: 5,
                runSpacing: 5,
                children: mechanics.map((mechanic) {
                  return AppMechanicChip(
                    label: mechanic.name,
                    selected: setting.value.contains(mechanic.name),
                    onSelected: (bool selected) {
                      if (selected) {
                        setting.value.add(mechanic.name);
                      } else {
                        setting.value.remove(mechanic.name);
                      }
                      // One-tap filtering: keep the mechanics filter live only
                      // while at least one mechanic is chosen.
                      setting.enabled = setting.value.isNotEmpty;
                      model.invalidateCache();
                      model.updateStore();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
