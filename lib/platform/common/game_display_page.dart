import 'package:how_many_mobile_meeple/model/model.dart';

import '../../app_page.dart';
import '../../network_content_widget.dart';

abstract class GameDisplayPage extends NetworkWidget with AppPage {

  bool hasPageRefreshed(AppModel model) => model.pageRefreshed;

  void updatePageRefreshedStatus(AppModel model) => model.pageRefreshed = false;
}