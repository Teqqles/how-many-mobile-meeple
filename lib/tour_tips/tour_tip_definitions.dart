import 'tour_tip.dart';

class TourTipDefinitions {
  static const String pageAppBar = 'app_bar';
  static const String pageStep2 = 'step2';
  static const String pageStep3 = 'step3';
  static const String pageStep4 = 'step4';
  static const String pageStep5 = 'step5';

  static const List<TourTip> all = [
    // App bar tips (shown on first homepage visit)
    TourTip(
      id: 'appbar_news',
      title: 'Board Game News',
      description: 'Tap here to read the latest board game news from the web.',
      pageId: pageAppBar,
      order: 0,
    ),
    TourTip(
      id: 'appbar_settings',
      title: 'Settings Drawer',
      description:
          'Open the settings drawer for advanced options like expansions, recommended player counts, and advanced mode.',
      pageId: pageAppBar,
      order: 1,
    ),
    TourTip(
      id: 'appbar_quick_pick',
      title: 'Quick Pick',
      description:
          'Skip the steps and pick a random game fast. Choose players, time, or weight and go.',
      pageId: pageAppBar,
      order: 2,
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
