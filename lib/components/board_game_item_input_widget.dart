import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/app_common.dart';
import 'package:how_many_mobile_meeple/components/app_default_padding.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';

/// Reusable board game item input widget (username/geeklist entry)
/// Extracted from HomePage.buildBoardGameItemTextField()
class BoardGameItemInputWidget extends StatefulWidget {
  const BoardGameItemInputWidget({super.key});

  @override
  State<BoardGameItemInputWidget> createState() =>
      _BoardGameItemInputWidgetState();
}

class _BoardGameItemInputWidgetState extends State<BoardGameItemInputWidget> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var textFieldWidth = MediaQuery.of(context).size.width * 0.65;

    return Align(
        alignment: Alignment.centerLeft,
        child: AppDefaultPadding(
          child: Row(
            children: <Widget>[
              Container(
                height: 35,
                width: textFieldWidth,
                child: Consumer<AppModel>(
                  builder: (context, model, child) => TextFormField(
                    enabled:
                        model.items.itemList.length < AppCommon.maxItemsFromBgg,
                    controller: controller,
                    decoration: InputDecoration(
                      hintText:
                          model.items.itemList.length < AppCommon.maxItemsFromBgg
                              ? AppCommon.itemHintTextMessage
                              : AppCommon.maxItemsMessage,
                    ),
                  ),
                ),
              ),
              Consumer<AppModel>(
                builder: (context, model, child) => AppDefaultPadding(
                  child: ElevatedButton(
                    child: const Text('Add'),
                    onPressed: () {
                      if (controller.text.isEmpty) return;
                      Item item = Item(controller.text.trim());
                      model.addItem(item);
                      controller.text = '';
                      model.updateStore();
                    },
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
