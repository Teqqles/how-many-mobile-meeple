import 'package:flutter/material.dart';
import 'tour_tip_definitions.dart';

class TourTipKeys {
  // App bar
  static final GlobalKey appBarNewsButton =
      GlobalKey(debugLabel: 'appbar_news');
  static final GlobalKey appBarSettingsButton =
      GlobalKey(debugLabel: 'appbar_settings');
  static final GlobalKey appBarQuickPick =
      GlobalKey(debugLabel: 'appbar_quick_pick');
  static final GlobalKey appBarFavourites =
      GlobalKey(debugLabel: 'appbar_favourites');

  // Step 2
  static final GlobalKey playerSlider =
      GlobalKey(debugLabel: 'step2_player_slider');

  // Step 3
  static final GlobalKey timeRangeSlider =
      GlobalKey(debugLabel: 'step3_time_range');

  // Step 4
  static final GlobalKey complexitySlider =
      GlobalKey(debugLabel: 'step4_complexity');
  static final GlobalKey mechanicsSection =
      GlobalKey(debugLabel: 'step4_mechanics');

  // Step 5
  static final GlobalKey randomButton =
      GlobalKey(debugLabel: 'step5_random_button');
  static final GlobalKey listButton =
      GlobalKey(debugLabel: 'step5_list_button');
  static final GlobalKey saveButton =
      GlobalKey(debugLabel: 'step5_save_button');

  static Map<String, GlobalKey> forPage(String pageId) {
    switch (pageId) {
      case TourTipDefinitions.pageAppBar:
        return {
          'appbar_news': appBarNewsButton,
          'appbar_settings': appBarSettingsButton,
          'appbar_quick_pick': appBarQuickPick,
          'appbar_favourites': appBarFavourites,
        };
      case TourTipDefinitions.pageStep2:
        return {
          'step2_player_slider': playerSlider,
        };
      case TourTipDefinitions.pageStep3:
        return {
          'step3_time_range': timeRangeSlider,
        };
      case TourTipDefinitions.pageStep4:
        return {
          'step4_complexity': complexitySlider,
          'step4_mechanics': mechanicsSection,
        };
      case TourTipDefinitions.pageStep5:
        return {
          'step5_random_button': randomButton,
          'step5_list_button': listButton,
          'step5_save_button': saveButton,
        };
      default:
        return {};
    }
  }
}
