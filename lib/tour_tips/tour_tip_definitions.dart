import 'tour_tip.dart';

class TourTipDefinitions {
  static const String pageAppBar = 'app_bar';
  static const String pageStep2 = 'step2';
  static const String pageStep3 = 'step3';
  static const String pageStep4 = 'step4';
  static const String pageStep5 = 'step5';

  static const List<TourTip> all = [
    // App bar tip (shown on first homepage visit)
    TourTip(
      id: 'appbar_actions',
      title: 'Your Top Bar',
      description: '📰 News: latest board game news\n'
          '⚡ Quick Pick: skip steps, pick a random game fast\n'
          '❤️ Favourites: your saved games\n'
          '⚙️ Settings: advanced options and filters',
      pageId: pageAppBar,
      order: 0,
    ),

    // Step 2 tips
    TourTip(
      id: 'step2_player_slider',
      title: 'Player Slider',
      description:
          'Drag this slider to set how many people will be playing. You can also use the quick presets below.',
      pageId: pageStep2,
      order: 0,
    ),

    // Step 3 tips
    TourTip(
      id: 'step3_time_range',
      title: 'Time Slider',
      description:
          'Drag the handles to set your minimum and maximum play time. Quick presets below offer common durations.',
      pageId: pageStep3,
      order: 0,
    ),

    // Step 4 tips
    TourTip(
      id: 'step4_complexity',
      title: 'Difficulty Slider',
      description:
          'Drag to set game weight from Light to Expert. You can also tap the panels above. Set to 0 for any difficulty.',
      pageId: pageStep4,
      order: 0,
    ),
    TourTip(
      id: 'step4_mechanics',
      title: 'Mechanics Filter',
      description:
          'Tap chips to select preferred mechanics. Leave all unselected to see every game type.',
      pageId: pageStep4,
      order: 1,
    ),

    // Step 5 tips
    TourTip(
      id: 'step5_random_button',
      title: 'Random Game',
      description:
          'Pick a single random game from your filtered results - great for decision paralysis!',
      pageId: pageStep5,
      order: 0,
    ),
    TourTip(
      id: 'step5_list_button',
      title: 'View Full List',
      description:
          'See all matching games in a sortable list with thumbnails and ratings.',
      pageId: pageStep5,
      order: 1,
    ),
    TourTip(
      id: 'step5_save_button',
      title: 'Save Settings',
      description:
          'Save your current filter settings so you can quickly reload them later.',
      pageId: pageStep5,
      order: 2,
    ),
  ];

  static List<TourTip> forPage(String pageId) =>
      all.where((t) => t.pageId == pageId).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
}
