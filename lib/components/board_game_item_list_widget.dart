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
        leading: item.itemType == ItemType.hotList
            ? Icon(Icons.local_fire_department,
                size: AppCommon.standardIconSize,
                color: Theme.of(context).colorScheme.secondary)
            : null,
        title: Text(item.itemType == ItemType.hotList
            ? 'Trending Games'
            : _limitTitleLength(item.name)),
        trailing: item.itemType == ItemType.hotList
            ? IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.delete,
                  size: AppCommon.standardIconSize,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  model.deleteItem(item);
                },
              )
            : SizedBox(
                width: 144,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.person,
                            size: AppCommon.standardIconSize,
                            color:
                                _colorItem(context, item, ItemType.collection)),
                        onPressed: () {
                          item.itemType = ItemType.collection;
                          model.invalidateCache();
                          model.updateStore();
                        }),
                    IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.format_list_bulleted,
                            size: AppCommon.standardIconSize,
                            color:
                                _colorItem(context, item, ItemType.geekList)),
                        onPressed: () {
                          item.itemType = ItemType.geekList;
                          model.invalidateCache();
                          model.updateStore();
                        }),
                    IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.delete,
                        size: AppCommon.standardIconSize,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () {
                        model.deleteItem(item);
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _limitTitleLength(String text) {
    if (text.length > 20) {
      text = "${text.substring(0, 18)}...";
    }
    return text;
  }

  Color _colorItem(BuildContext context, Item item, ItemType expectedType) =>
      expectedType == item.itemType
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).disabledColor;
}
