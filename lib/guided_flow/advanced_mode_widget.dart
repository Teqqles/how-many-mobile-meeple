import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/components/board_game_item_input_widget.dart';
import 'package:how_many_mobile_meeple/components/board_game_item_list_widget.dart';
import 'package:how_many_mobile_meeple/components/complexity_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/mechanic_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/player_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/rating_filter_widget.dart';
import 'package:how_many_mobile_meeple/components/time_filter_widget.dart';

class AdvancedModeWidget extends StatelessWidget {
  const AdvancedModeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoardGameItemInputWidget(),
        SizedBox(height: 8),
        BoardGameItemListWidget(),
        SizedBox(height: 8),
        TimeFilterWidget(),
        SizedBox(height: 8),
        PlayerFilterWidget(),
        SizedBox(height: 8),
        ComplexityFilterWidget(),
        SizedBox(height: 8),
        RatingFilterWidget(),
        SizedBox(height: 8),
        MechanicFilterWidget(),
      ],
    );
  }
}
