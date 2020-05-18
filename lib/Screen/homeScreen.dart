import 'dart:async';

import 'package:doeat/Model/pinDataModel.dart';
import 'package:doeat/Provider/mapProvider.dart';
import 'package:doeat/Repository/fireStoreRepository.dart';
import 'package:doeat/Screen/phoneAuthScreen.dart';
import 'package:doeat/Utils/AlertDialog/alert.dart';
import 'package:doeat/Utils/AlertDialog/alert_style.dart';
import 'package:doeat/Utils/AlertDialog/constants.dart';
import 'package:doeat/Utils/AlertDialog/dialog_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseUser user;

  HomeScreen({Key key, @required this.user})
      : assert(user != null),
        super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState(user);
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  _HomeScreenState(this._user);

  Future<void> _launched;
  final _formKey = GlobalKey<FormState>();
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
  LocationResult _result;

  FirebaseUser _user;
  static GlobalKey<_HomeScreenState> _scaffoldKey = GlobalKey<_HomeScreenState>();

  final FocusNode _countFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _userNameFocusNode = FocusNode();

  void _setStyle(GoogleMapController controller) async {
    String value = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json');

    controller.setMapStyle(value);
  }

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.ensureVisualUpdate();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getPermission();
    _addMarkersAndData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _getPermission();
    }
  }

  Future<void> _getPermission() async {
    PermissionStatus permission = await Permission.location.request();
    if (permission == PermissionStatus.denied) {
      await Permission.locationAlways.request();
    }
    GeolocationStatus geolocationStatus =
        await Geolocator().checkGeolocationPermissionStatus();

    switch (geolocationStatus) {
      case GeolocationStatus.denied:
        break;
      case GeolocationStatus.disabled:
        break;
      case GeolocationStatus.restricted:
        break;
      case GeolocationStatus.unknown:
        break;
      case GeolocationStatus.granted:
        _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    _user = await FirebaseAuth.instance.currentUser();
    Position initialLocation = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      context.read<MapProvider>().setCameraPosition(CameraPosition(
            target: LatLng(
              initialLocation.latitude,
              initialLocation.longitude,
            ),
            zoom: 10.0,
          ));
      var temp =
          await context.read<MapProvider>().getGoogleMapController.future;
      temp.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              initialLocation.latitude,
              initialLocation.longitude,
            ),
            zoom: 10.0,
          ),
        ),
      );
    }
  }

  _addMarker(String data, dynamic locationData, BuildContext context) async {
    var mark = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 5), 'assets/images/pin.png');
    final Marker marker = Marker(
        markerId: MarkerId(_user.uid),
        position: LatLng(
          locationData.latitude,
          locationData.longitude,
        ),
        icon: mark,
        consumeTapEvents: false,
        onTap: () {
          setState(() {
            _dataModel = PinDataModel(
              foodCount:
                  context.read<MapProvider>().getFoodCountController.text,
              data: context.read<MapProvider>().getFoodDetailsController.text,
              isAvailable: false,
              userId: _user.uid,
              contactNumber: _user.phoneNumber,
              userName: context.read<MapProvider>().getUserNameController.text,
              addressDetails:
                  context.read<MapProvider>().getAddressDetailsController.text,
              uploadTime: DateTime.now().millisecondsSinceEpoch.toString(),
            );
          });
          if (!context.read<MapProvider>().getShowWindow)
            context.read<MapProvider>().setShowWindow(true);
        });

    context.read<MapProvider>().setAddMarkers(_user.uid, marker);
  }

  Future<void> _addMarkersAndData() async {
    if (context.read<MapProvider>().getShowWindow)
      context.read<MapProvider>().setShowWindow(false);
    var mark = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/images/pin.png');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _buildShowDialog(context);
    // clear markers and userData
    context.read<MapProvider>().clearMarkers();
    context.read<MapProvider>().clearUserData();
    // set controller values
    context.read<MapProvider>().setFoodDetailController(
        TextEditingController(text: prefs.getString("data")));
    context.read<MapProvider>().setFoodCountController(
        TextEditingController(text: prefs.getString("foodCount")));
    context.read<MapProvider>().setUserNameController(
        TextEditingController(text: prefs.getString("userName")));
    context.read<MapProvider>().setAddressDetailsController(
        TextEditingController(text: prefs.getString("addressDetails")));

    // get data from database and set in variable
    context.read<MapProvider>().setUserData(await getData());
    // add markers with values
    context.read<MapProvider>().getUserData.forEach((uData) {
      final Marker marker = Marker(
          markerId: MarkerId(uData.data['userId']),
          position: LatLng(
            uData.data['latitude'],
            uData.data['longitude'],
          ),
          icon: mark,
          consumeTapEvents: false,
          onTap: () {
            setState(() {
              _dataModel = PinDataModel(
                foodCount: uData.data['foodCount'],
                data: uData.data['data'],
                isAvailable: uData.data['isAvailable'],
                userId: uData.data['userId'],
                contactNumber: uData.data['contactNumber'],
                userName: uData.data['userName'],
                addressDetails: uData.data['addressDetails'],
                uploadTime: uData.data['uploadTime'],
              );
            });
            if (!context.read<MapProvider>().getShowWindow)
              context.read<MapProvider>().setShowWindow(true);
          });

      // markers add in a list
      context.read<MapProvider>().setAddMarkers(uData.data['userId'], marker);
    });
    // animation of camera to current position
    if (await Permission.location.isGranted) {
      _getUserLocation();
    }
    _buildHideDialog(context);
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
            borderRadius: const BorderRadius.only(
              topLeft: const Radius.circular(25.0),
              topRight: const Radius.circular(25.0),
            ),
            image: DecorationImage(
                image: const AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
                colorFilter:
                    ColorFilter.mode(Colors.black26, BlendMode.softLight)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                child: _foodForm(),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30.0),
                    child: Image.asset(
                      'assets/images/logo_text.png',
                      height: 100.0,
                      fit: BoxFit.scaleDown,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _foodForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              padding: const EdgeInsets.only(top: 10, right: 20),
              icon: const Icon(
                FlutterIcons.close_ant,
                size: 35,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        Expanded(
          child: Scrollbar(
            child: ListView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10.0, top: 10),
                    child: const Text(
                      "Add Food Details",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
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
                            controller: context
                                .read<MapProvider>()
                                .getFoodDetailsController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                                hintText: "Food Details",
                                errorStyle: const TextStyle(
                                    color: Colors.yellow,
                                    decorationColor: Colors.yellow),
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
                            focusNode: _countFocusNode,
                            onFieldSubmitted: (_) {
                              _countFocusNode.unfocus();
                              _userNameFocusNode.requestFocus();
                            },
                            controller: context
                                .read<MapProvider>()
                                .getFoodCountController,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                            ],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                hintText: "How many can eat this food?",
                                errorStyle: const TextStyle(
                                    color: Colors.yellow,
                                    decorationColor: Colors.yellow),
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
                            focusNode: _userNameFocusNode,
                            onFieldSubmitted: (_) {
                              _userNameFocusNode.unfocus();
                              _addressFocusNode.requestFocus();
                            },
                            controller: context
                                .read<MapProvider>()
                                .getUserNameController,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(25),
                            ],
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                                hintText: "Your Name",
                                errorStyle: const TextStyle(
                                    color: Colors.yellow,
                                    decorationColor: Colors.yellow),
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
                            focusNode: _addressFocusNode,
                            controller: context
                                .read<MapProvider>()
                                .getAddressDetailsController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                                hintText: "Address Details",
                                errorStyle: const TextStyle(
                                    color: Colors.yellow,
                                    decorationColor: Colors.yellow),
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
                              _result = await showLocationPicker(context,
                                  "AIzaSyDV2_xy58r15K6TskZy4KWMuhUDVq67jqM",
                                  initialCenter: context
                                      .read<MapProvider>()
                                      .getCameraPosition
                                      .target,
                                  myLocationButtonEnabled: true,
                                  hintText: "Choose Location",
                                  resultCardConfirmIcon: const Icon(Icons.done),
                                  automaticallyAnimateToCurrentLocation: true,
                                  appBarColor: Theme.of(context).primaryColor,
                                  mapStylePath: "assets/map_style.json");
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Tooltip(
                                message: "Add Food",
                                preferBelow: false,
                                child: DialogButton(
                                    gradient: const LinearGradient(
                                      colors: [
                                        const Color.fromRGBO(52, 138, 199, 1.0),
                                        const Color.fromRGBO(
                                            116, 116, 191, 1.0),
                                      ],
                                    ),
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    child: const Text(
                                      "Add Food",
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState.validate() &&
                                          _result == null) {
                                        _showToast("Set Location!", Colors.red);
                                      }
                                      if (_formKey.currentState.validate() &&
                                          _result != null) {
                                        insertData(
                                          user: _user,
                                          data: context
                                              .read<MapProvider>()
                                              .getFoodDetailsController
                                              .text,
                                          foodCount: context
                                              .read<MapProvider>()
                                              .getFoodCountController
                                              .text,
                                          addressDetails: context
                                              .read<MapProvider>()
                                              .getAddressDetailsController
                                              .text,
                                          userName: context
                                              .read<MapProvider>()
                                              .getUserNameController
                                              .text,
                                          isAvailable: true,
                                          locationData: _result.latLng,
                                        );
                                        _addMarker(
                                            context
                                                .read<MapProvider>()
                                                .getFoodDetailsController
                                                .text,
                                            _result.latLng,
                                            context);
                                        _showToast("Data Updated Successfully",
                                            Colors.green);
                                      }
                                    }),
                              ),
                              Tooltip(
                                message: "Delete Details",
                                preferBelow: false,
                                child: DialogButton(
                                    width:
                                        MediaQuery.of(context).size.width * 0.3,
                                    gradient: const LinearGradient(
                                      colors: [
                                        const Color.fromRGBO(
                                            116, 116, 191, 1.0),
                                        const Color.fromRGBO(52, 138, 199, 1.0),
                                      ],
                                    ),
                                    child: const Text(
                                      "Delete Details",
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                    onPressed: () {
                                      deleteData(user: _user);
                                      context
                                          .read<MapProvider>()
                                          .setRemoveMarkers(_user.uid);
                                      _showToast(
                                          _result != null
                                              ? "Data Deleted!"
                                              : "No Data Available",
                                          Colors.red);
                                      _result = null;
                                    }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildShowDialog(BuildContext context) {
    return showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Image.asset(
                "assets/images/globe.gif",
                height: 50,
                width: 50,
              ),
            ),
          );
        });
  }

  _buildHideDialog(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    return Consumer<MapProvider>(
      builder: (context, myModel, child) => SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          key: _scaffoldKey,
          floatingActionButton: FloatingActionButton.extended(
              label: const Text(
                "Add Food",
                style: const TextStyle(color: Colors.white),
              ),
              icon: const Icon(
                Icons.fastfood,
                color: Colors.white,
              ),
              backgroundColor: Theme.of(context).primaryColor,
              heroTag: "add",
              tooltip: "Add Food",
              onPressed: () {
                if (myModel.getShowWindow) myModel.setShowWindow(false);
                _showSheet();
              }),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          appBar: AppBar(
            flexibleSpace: Image.asset(
              "assets/images/background.jpg",
              fit: BoxFit.cover,
            ),
            title: const Text("Home"),
            centerTitle: true,
            actions: <Widget>[
              PopupMenuButton<String>(
                tooltip: "Menu",
                onSelected: _choiceAction,
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
                  if (myModel.getShowWindow) myModel.setShowWindow(false);
                },
                markers: myModel.getAddMarkers.values.toSet(),
                initialCameraPosition: const CameraPosition(
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
                  myModel.setGoogleMapController(controller);
                  _setStyle(controller);
                },
              ),
              AnimatedPositioned(
                top: myModel.getShowWindow ? 0 : -1000,
                right: 0,
                left: 0,
                duration: Duration(milliseconds: 2),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 10, bottom: 10),
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image:
                              const AssetImage("assets/images/background.jpg"),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black26, BlendMode.softLight)),
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          blurRadius: 1,
                          offset: Offset.zero,
                          color: Colors.white.withOpacity(1.0),
                        )
                      ]),
                  child: Wrap(children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Icon(MaterialCommunityIcons.face),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _dataModel.userName.toString() ?? "---",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                                MaterialCommunityIcons.information_outline),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _dataModel.data.toString() ?? "---",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 5,
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Icon(MaterialCommunityIcons.human_male_male),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _dataModel.foodCount.toString() ?? "---",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(MaterialCommunityIcons.crosshairs_gps),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  _dataModel.addressDetails.toString() ?? "---",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 5,
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            InkWell(
                              child: const Icon(
                                  MaterialCommunityIcons.phone_outgoing),
                              onTap: () => setState(() {
                                _launched = _makePhoneCall(
                                    'tel:${_dataModel.contactNumber.toString()}');
                              }),
                            ),
                            FutureBuilder<void>(
                                future: _launched, builder: _launchStatus),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _launched = _makePhoneCall(
                                        'tel:${_dataModel.contactNumber.toString()}');
                                  }),
                                  child: Text(
                                    _dataModel.contactNumber.toString() ??
                                        "---",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Icon(MaterialCommunityIcons.clock_outline),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  DateFormat('dd-MMM-yyyy h:mma').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              (int.parse(
                                                  _dataModel.uploadTime ??
                                                      1589645349389)))) ??
                                      "---",
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _choiceAction(String choice) {
    if (choice == Constants.Refresh) {
      _addMarkersAndData();
    } else if (choice == Constants.SignOut) {
      _logoutDialog(context);
    }
  }

  Widget _launchStatus(BuildContext context, AsyncSnapshot<void> snapshot) {
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const Text('');
    }
  }

  Future<Null> _logoutDialog(BuildContext context) async {
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
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => _handleSignOut(),
          color: const Color.fromRGBO(0, 179, 134, 1.0),
        ),
        DialogButton(
          child: Text(
            "No",
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          gradient: const LinearGradient(
            colors: [
              const Color.fromRGBO(116, 116, 191, 1.0),
              const Color.fromRGBO(52, 138, 199, 1.0),
            ],
          ),
        )
      ],
    ).show();
  }

  void _handleSignOut() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => PhoneAuthScreen()),
        (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<MapProvider>().disposeTextController();
    context.read<MapProvider>().dispose();
    super.dispose();
  }

  void _showToast(String message, Color color) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: color,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}

class Constants {
  static const String Refresh = 'Refresh';
  static const String SignOut = 'SignOut';
  static const List<String> choices = <String>[Refresh, SignOut];
}
