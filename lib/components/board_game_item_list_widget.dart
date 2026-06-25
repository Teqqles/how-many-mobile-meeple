import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';

/// Reusable board game item list widget (displays selected usernames/geeklists)
/// Extracted from HomePage.buildBoardGameGeekItemDisplay()
class BoardGameItemListWidget extends StatelessWidget {
  const BoardGameItemListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, model, child) => Column(
        children: <Widget>[
          Container(
              height: 35,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: AppDefaultPadding(
                child: Row(children: [
                  Text(
                    "Usernames/Geeklists Selected",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                ]),
              )),
          Column(
            children: ListTile.divideTiles(
                    context: context, tiles: _itemsSelected(context, model))
                .toList(),
          ),
        ],
      ),
    );
  }

  Iterable<Widget> _itemsSelected(BuildContext context, AppModel model) {
    if (model.items.isEmpty) {
      return [
        ListTile(
            title: Text(
          "No Items Selected",
          style:
              TextStyle(fontSize: 13, color: Theme.of(context).disabledColor),
        ))
      ];
    }
    return model.items.itemList.map(
      (item) => ListTile(
        leading: Icon(
          _iconForItemType(item.itemType),
          size: AppCommon.standardIconSize,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(item.itemType == ItemType.hotList
            ? 'Trending Games'
            : _limitTitleLength(item.name)),
        trailing: IconButton(
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          tooltip: 'Remove',
          icon: Icon(
            Icons.delete,
            size: AppCommon.standardIconSize,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            model.deleteItem(item);
          },
        ),
      ),
    );
  }

  IconData _iconForItemType(ItemType type) {
    if (type == ItemType.hotList) return Icons.local_fire_department;
    if (type == ItemType.geekList) return Icons.format_list_bulleted;
    return Icons.person;
  }

  String _limitTitleLength(String text) {
    if (text.length > 20) {
      text = "${text.substring(0, 18)}...";
    }
    return text;
  }
}
