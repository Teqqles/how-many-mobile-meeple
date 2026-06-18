import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/api/prefetch_service.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BoardGameItemInputWidget(),
        const SizedBox(height: 8),
        _buildTrendingButton(context),
        const SizedBox(height: 8),
        const BoardGameItemListWidget(),
        const SizedBox(height: 8),
        const TimeFilterWidget(),
        const SizedBox(height: 8),
        const PlayerFilterWidget(),
        const SizedBox(height: 8),
        const ComplexityFilterWidget(),
        const SizedBox(height: 8),
        const RatingFilterWidget(),
        const SizedBox(height: 8),
        const MechanicFilterWidget(),
      ],
    );
  }

  Widget _buildTrendingButton(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) {
        final hasHot = model.items.itemList
            .any((item) => item.itemType == ItemType.hotList);
        final atMax = model.items.itemList.length >= AppCommon.maxItemsFromBgg;

        if (hasHot) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: atMax
                ? null
                : () {
                    final item = Item('trending', itemType: ItemType.hotList);
                    model.addItem(item);
                    PrefetchService.warmCache(item);
                  },
            icon: const Icon(Icons.local_fire_department, size: 18),
            label: const Text('Add Trending Games'),
          ),
        );
      },
    );
  }
}
