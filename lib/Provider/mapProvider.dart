import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doeat/Model/pinDataModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapProvider with ChangeNotifier {
  MapProvider();

  bool _showWindow = false;
  Map<String, Marker> _markers = {};
  PinDataModel _dataModel = PinDataModel(
    foodCount: "0",
    data: "Default Data",
    isAvailable: false,
    userId: "user: 0000",
    contactNumber: "0000000000",
    userName: "displayName",
    addressDetails: "nathi kabar",
    uploadTime: DateTime.now().millisecondsSinceEpoch.toString(),
  );

  void setDataModel(PinDataModel dataModel) {
    _dataModel = dataModel;
    notifyListeners();
  }

  PinDataModel get getDataModel => _dataModel;

  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(0, 0), zoom: 10.0);
  TextEditingController _foodDetailsController = TextEditingController();
  TextEditingController _foodCountController = TextEditingController();
  TextEditingController _userNameController = TextEditingController();
  TextEditingController _addressDetailsController = TextEditingController();
  List<DocumentSnapshot> _userData;
  Completer<GoogleMapController> _completer = Completer();
  FirebaseUser user;

  void setFireBaseUser(FirebaseUser firebaseUser) {
    user = firebaseUser;
    notifyListeners();
  }

  FirebaseUser get getFireBaseUser => user;

  void setGoogleMapController(GoogleMapController completer) {
    _completer.complete(completer);
    notifyListeners();
  }

  Completer<GoogleMapController> get getGoogleMapController => _completer;

  void setShowWindow(bool isShown) {
    _showWindow = isShown;
    print("showWindow : $_showWindow");
    notifyListeners();
  }

  bool get getShowWindow => _showWindow;

  void setAddMarkers(String id, Marker marker) {
    _markers[id] = marker;
    notifyListeners();
  }

  void clearMarkers() {
    _markers = {};
  }

  void setRemoveMarkers(String id) {
    _markers.remove(id);
    notifyListeners();
  }

  Map<String, Marker> get getAddMarkers => _markers;

  void setCameraPosition(CameraPosition position) {
    _cameraPosition = position;
    notifyListeners();
  }

  CameraPosition get getCameraPosition => _cameraPosition;

  void setFoodDetailController(TextEditingController controller) {
    _foodDetailsController = controller;
    notifyListeners();
  }

  void setFoodCountController(TextEditingController controller) {
    _foodCountController = controller;
    notifyListeners();
  }

  void setUserNameController(TextEditingController controller) {
    _userNameController = controller;
    notifyListeners();
  }

  void setAddressDetailsController(TextEditingController controller) {
    _addressDetailsController = controller;
    notifyListeners();
  }

  void disposeTextController() {
    _userNameController.dispose();
    _foodDetailsController.dispose();
    _foodCountController.dispose();
    _addressDetailsController.dispose();
    notifyListeners();
  }

  TextEditingController get getFoodDetailsController => _foodDetailsController;

  TextEditingController get getFoodCountController => _foodCountController;

  TextEditingController get getUserNameController => _userNameController;

  TextEditingController get getAddressDetailsController =>
      _addressDetailsController;

  void setUserData(List<DocumentSnapshot> data) {
    _userData = data;
    notifyListeners();
  }

  void clearUserData() {
    _userData = [];
  }

  List<DocumentSnapshot> get getUserData => _userData;
}
