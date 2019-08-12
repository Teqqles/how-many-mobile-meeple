import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history.dart';

import 'model/app_preferences.dart';
import 'model/model.dart';

class SaveDialog extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  final PreferencesHistory history = PreferencesHistory();

  final String title = 'Save Preferences';
  final AppModel model;

  SaveDialog({this.model});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(40),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  Widget dialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min, // To make the card compact
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.only(top: 8),
              decoration: new BoxDecoration(
                color: Theme.of(context).accentColor,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(top: 4, bottom: 4),
                    margin: EdgeInsets.zero,
                    decoration: new BoxDecoration(
                      color: Theme.of(context).accentColor,
                      shape: BoxShape.rectangle,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).selectedRowColor,
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.zero,
              decoration: new BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  SizedBox(height: 16.0),
                  TextFormField(
                    decoration:
                        InputDecoration(hintText: "Name your preferences"),
                    controller: controller,
                  ),
                  SizedBox(height: 24.0),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: RaisedButton.icon(
                        onPressed: () {
                          model.title = controller.text;
                          history
                              .storePreference(AppPreferences.fromModel(model));
                          model.refreshState();
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.save),
                        label: Text("Save")),
                  ),
                ],
              ),
            ),
          ],
        ),
        //...top circlular image part,
      ],
    );
  }
}
