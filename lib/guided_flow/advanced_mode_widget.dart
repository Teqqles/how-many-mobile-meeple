import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/homepage.dart';

/// Advanced Mode Widget
/// Wraps the existing full-control homepage UI in an expandable panel
class AdvancedModeWidget extends StatelessWidget {
  const AdvancedModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the existing HomePage widget content
    // We'll create an instance and extract its UI components
    final homePage = HomePage();
    final textFieldWidth = MediaQuery.of(context).size.width * 0.65;

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
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Username/Geeklist input
                homePage.buildBoardGameItemTextField(textFieldWidth),
                const SizedBox(height: 8),

                // Board Game Geek Item Display
                homePage.buildBoardGameGeekItemDisplay(),
                const SizedBox(height: 8),

                // Time slider
                homePage.buildGameDurationSliderDisplay(context),
                const SizedBox(height: 8),

                // Player count slider
                homePage.buildPlayerSliderDisplay(),
                const SizedBox(height: 8),

                // Complexity slider
                homePage.buildComplexitySliderDisplay(),
                const SizedBox(height: 8),

                // Rating slider
                homePage.buildRatingSliderDisplay(),
                const SizedBox(height: 8),

                // Mechanics filter
                homePage.buildMechanicFilterDisplay(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
