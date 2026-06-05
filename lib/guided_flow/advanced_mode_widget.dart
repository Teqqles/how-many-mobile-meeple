import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/board_game_item_input_widget.dart';
import 'package:how_many_mobile_meeple/components/board_game_item_list_widget.dart';
import 'package:how_many_mobile_meeple/components/complexity_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/mechanic_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/player_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/rating_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/time_filter_widget.dart';

/// Advanced Mode Widget
/// Wraps the existing full-control homepage UI in an expandable panel
class AdvancedModeWidget extends StatelessWidget {
  const AdvancedModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.tune,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Full control over all filters'),
        ),
        initiallyExpanded: true,
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Username/Geeklist input
                BoardGameItemInputWidget(),
                SizedBox(height: 8),

                // Board Game Geek Item Display
                BoardGameItemListWidget(),
                SizedBox(height: 8),

                // Time slider
                TimeFilterWidget(),
                SizedBox(height: 8),

                // Player count slider
                PlayerFilterWidget(),
                SizedBox(height: 8),

                // Complexity slider
                ComplexityFilterWidget(),
                SizedBox(height: 8),

                // Rating slider
                RatingFilterWidget(),
                SizedBox(height: 8),

                // Mechanics filter
                MechanicFilterWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
