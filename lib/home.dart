import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doeat/AlertDialog/Alert.dart';
import 'package:doeat/AlertDialog/alert_style.dart';
import 'package:doeat/AlertDialog/constants.dart';
import 'package:doeat/AlertDialog/dialog_button.dart';
import 'package:doeat/firestore_repo.dart';
import 'package:doeat/map_provider.dart';
import 'package:doeat/phone_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final FirebaseUser user;

  HomePage({Key key, @required this.user})
      : assert(user != null),
        super(key: key);

  @override
  _HomePageState createState() => _HomePageState(user);
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  _HomePageState(this.user);

  final _formKey = GlobalKey<FormState>();
  Completer<GoogleMapController> _controller = Completer();
  LocationData locationData;
  LocationResult result;
  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(0, 0), zoom: 10.0);
  FirebaseUser user;
  static GlobalKey<_HomePageState> _scaffoldKey = GlobalKey<_HomePageState>();
  List<DocumentSnapshot> userData;
  Map<String, Marker> _markers = {};
  TextEditingController foodDetailsController;
  TextEditingController foodCountController;
  TextEditingController userNameController;
  TextEditingController addressDetailsController;
  Position position;
  final FocusNode countFocusNode = FocusNode();
  final FocusNode addressFocusNode = FocusNode();
  final FocusNode userNameFocusNode = FocusNode();

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.ensureVisualUpdate();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getUserLocation();
    _add();
  }

  Future<void> _getUserLocation() async {
    user = await FirebaseAuth.instance.currentUser();
    if (await Geolocator().isLocationServiceEnabled()) {
      if (await Permission.locationAlways.request().isGranted) {
        Position initialLocation = await Geolocator().getCurrentPosition();
        if (mounted) {
          setState(() {
            _cameraPosition = CameraPosition(
              target: LatLng(
                initialLocation.latitude,
                initialLocation.longitude,
              ),
              zoom: 8.0,
            );
          });
        }
      } else {
        await [
          Permission.locationAlways,
          Permission.location,
        ].request();
        _getUserLocation();
      }
    } else {
      _getUserLocation();
    }
  }

  removeMarker() {
    setState(() {
      _markers.remove(user.uid);
    });
  }

  addMarker(String data, dynamic locationData, BuildContext context) {
    final Marker marker = Marker(
        markerId: MarkerId(user.uid),
        position: LatLng(
          locationData.latitude,
          locationData.longitude,
        ),
        consumeTapEvents: false,
        infoWindow: InfoWindow(
          title: data ?? 'No UserName',
        ),
        onTap: () {
          print("market tapped");
          context.read<MapProvider>().setShowWindow(true);
        });

    setState(() {
      _markers[user.uid] = marker;
    });
  }

  _add() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var controller = await _controller.future;
    position = await Geolocator().getCurrentPosition();
    GeolocationStatus geolocationStatus =
        await Geolocator().checkGeolocationPermissionStatus();
    buildShowDialog(context);
    setState(() {
      foodDetailsController =
          TextEditingController(text: prefs.getString("data"));
      foodCountController =
          TextEditingController(text: prefs.getString("foodCount"));
      userNameController =
          TextEditingController(text: prefs.getString("userName"));
      addressDetailsController =
          TextEditingController(text: prefs.getString("addressDetails"));

      userData = [];
      _markers = {};
    });
    userData = await getData();
    userData.forEach((uData) {
      final Marker marker = Marker(
          markerId: MarkerId(uData.data['userId']),
          position: LatLng(
            uData.data['latitude'],
            uData.data['longitude'],
          ),
          consumeTapEvents: false,
          infoWindow: InfoWindow(
            title: uData.data['data'] ?? 'No UserName',
          ),
          onTap: () {
            print("market tapped");
            context.read<MapProvider>().setShowWindow(true);
          });

      setState(() {
        _markers[uData.data['userId']] = marker;
        if (geolocationStatus != GeolocationStatus.granted) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              _cameraPosition,
            ),
          );
        } else if (geolocationStatus == GeolocationStatus.granted) {
          _cameraPosition = CameraPosition(
            target: LatLng(
              position.latitude,
              position.longitude,
            ),
            zoom: 8.0,
          );
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              _cameraPosition,
            ),
          );
        }
      });
    });
    buildHideDialog(context);
  }

  void _showSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: const Radius.circular(25.0),
              topRight: const Radius.circular(25.0),
            ),
          ),
          child: foodForm(),
        );
      },
    );
  }

  Widget foodForm() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              padding: const EdgeInsets.only(top: 10, right: 20),
              icon: const Icon(
                Icons.clear,
                size: 35,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: const Text(
            "Add Food Details",
            style: const TextStyle(fontSize: 20),
          ),
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: TextFormField(
                          maxLines: 10,
                          minLines: 1,
                          controller: foodDetailsController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                              hintText: "Food Details",
                              contentPadding:
                                  const EdgeInsets.only(left: 15, right: 15)),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please Add Food Details!';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: TextFormField(
                          maxLines: 1,
                          minLines: 1,
                          focusNode: countFocusNode,
                          onFieldSubmitted: (_) {
                            countFocusNode.unfocus();
                            userNameFocusNode.requestFocus();
                          },
                          controller: foodCountController,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                          ],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              hintText: "How many can eat this food?",
                              contentPadding:
                                  const EdgeInsets.only(left: 15, right: 15)),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please Enter Count!';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: TextFormField(
                          maxLines: 1,
                          minLines: 1,
                          focusNode: userNameFocusNode,
                          onFieldSubmitted: (_) {
                            userNameFocusNode.unfocus();
                            addressFocusNode.requestFocus();
                          },
                          controller: userNameController,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                              hintText: "Your Name",
                              contentPadding:
                                  const EdgeInsets.only(left: 15, right: 15)),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please Enter Your Name!';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: TextFormField(
                          maxLines: 10,
                          minLines: 1,
                          focusNode: addressFocusNode,
                          controller: addressDetailsController,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                              hintText: "Address Details",
                              contentPadding:
                                  const EdgeInsets.only(left: 15, right: 15)),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please Enter Your Address!';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: MaterialButton(
                          child: const Text(
                            "Set Pickup Location",
                          ),
                          minWidth: double.minPositive,
                          onPressed: () async {
                            result = await showLocationPicker(context,
                                "AIzaSyDV2_xy58r15K6TskZy4KWMuhUDVq67jqM");
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            RaisedButton(
                                child: const Text("add"),
                                onPressed: () async {
                                  if (_formKey.currentState.validate() &&
                                      result == null) {
                                    Fluttertoast.showToast(
                                        msg: "Please Set Pickup Location!",
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIos: 2,
                                        backgroundColor: Colors.red,
                                        textColor: Colors.white,
                                        fontSize: 16.0);
                                  }
                                  if (_formKey.currentState.validate() &&
                                      result != null) {
                                    insertData(
                                      user: user,
                                      data: foodDetailsController.text,
                                      foodCount: foodCountController.text,
                                      addressDetails:
                                          addressDetailsController.text,
                                      userName: userNameController.text,
                                      isAvailable: true,
                                      locationData: result.latLng,
                                    );
                                    addMarker(foodDetailsController.text,
                                        result.latLng, context);
                                    Fluttertoast.showToast(
                                        msg: "Data Updated Successfully",
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.BOTTOM,
                                        timeInSecForIos: 2,
                                        backgroundColor: Colors.green,
                                        textColor: Colors.white,
                                        fontSize: 16.0);
                                  }
                                }),
                            RaisedButton(
                                child: const Text("delete"),
                                onPressed: () {
                                  deleteData(user: user);
                                  removeMarker();
                                  Fluttertoast.showToast(
                                      msg: result != null
                                          ? "Data Deleted!"
                                          : "No Data Available",
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIos: 2,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                  result = null;
                                }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            shrinkWrap: true,
          ),
        ),
      ],
    );
  }

  buildShowDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Image.asset(
              "assets/images/globe.gif",
              height: 50,
              width: 50,
            ),
          );
        });
  }

  buildHideDialog(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return Consumer<MapProvider>(
      builder: (context, myModel, child) => SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
          floatingActionButton: FloatingActionButton.extended(
              label: const Text(
                "Add Food",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(
                Icons.fastfood,
                color: Colors.white,
              ),
              backgroundColor: Theme.of(context).primaryColor,
              heroTag: "add",
              onPressed: () {
                _showSheet();
              }),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          appBar: AppBar(
            title: const Text("Home"),
            centerTitle: true,
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: choiceAction,
                captureInheritedThemes: true,
                elevation: 1,
                itemBuilder: (BuildContext context) {
                  return Constants.choices.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              )
            ],
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onTap: (latLng) {
                  myModel.setShowWindow(false);
                },
                markers: _markers.values.toSet(),
                initialCameraPosition: CameraPosition(
                  target: const LatLng(0, 0),
                ),
                mapType: MapType.normal,
                myLocationEnabled: true,
                tiltGesturesEnabled: false,
                compassEnabled: false,
                indoorViewEnabled: false,
                buildingsEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: true,
                trafficEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
              myModel.getShowWindow
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              color: Colors.red,
                              child: const Text("hello"),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  void choiceAction(String choice) {
    if (choice == Constants.Refresh) {
      _add();
    } else if (choice == Constants.SignOut) {
      logoutDialog(context);
    }
  }

  Future<Null> logoutDialog(BuildContext context) async {
    await Alert(
      style: AlertStyle(
        isCloseButton: false,
        animationType: AnimationType.shrink,
        animationDuration: Duration(
          milliseconds: 200,
        ),
        isOverlayTapDismiss: false,
      ),
      type: AlertType.error,
      context: context,
      title: "Really Sign-Out?",
      buttons: [
        DialogButton(
          child: Text(
            "Yes",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => handleSignOut(),
          color: Color.fromRGBO(0, 179, 134, 1.0),
        ),
        DialogButton(
          child: Text(
            "No",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(116, 116, 191, 1.0),
              Color.fromRGBO(52, 138, 199, 1.0),
            ],
          ),
        )
      ],
    ).show();
  }

  void handleSignOut() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => PhoneLogin()),
        (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class Constants {
  static const String Refresh = 'Refresh';
  static const String SignOut = 'Sign out';

  static const List<String> choices = <String>[Refresh, SignOut];
}
