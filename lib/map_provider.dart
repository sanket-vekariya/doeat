import 'package:flutter/foundation.dart';

class MapProvider with ChangeNotifier {
  MapProvider();

  bool showWindow = false;

  void setShowWindow(bool isShown) {
    showWindow = isShown;
    print("showWindow : $showWindow");
    notifyListeners();
  }

  bool get getShowWindow => showWindow;
}
