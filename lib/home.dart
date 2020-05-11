import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doeat/firestore_repo.dart';
import 'package:doeat/phone_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  final FirebaseUser user;

  HomePage({Key key, @required this.user})
      : assert(user != null),
        super(key: key);

  @override
  _HomePageState createState() => _HomePageState(user);
}

class _HomePageState extends State<HomePage> {
  _HomePageState(this.user);

  Completer<GoogleMapController> _controller = Completer();
  LatLng currentLocation;
  LocationData locationData;
  Location location = Location();
  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(0, 0), zoom: 10.0);
  FirebaseUser user;
  List<DocumentSnapshot> userData;
  Map<String, Marker> _markers = {};

  Future<void> _getUserLocation() async {
    user = await FirebaseAuth.instance.currentUser();
    var controller = await _controller.future;
    location.onLocationChanged().listen((currentLocation) {
      if (mounted) {
        setState(() {
          locationData = currentLocation;
          _cameraPosition = CameraPosition(
            target: LatLng(
              currentLocation.latitude,
              currentLocation.longitude,
            ),
            zoom: 8.0,
          );
        });
      }
    });
  }

  removeMarker() {
    setState(() {
      _markers.remove(user.uid);
    });
  }

  addMarker(String data, LocationData locationData) {
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
    );

    setState(() {
      _markers[user.uid] = marker;
    });
  }

  _add() async {
    var controller = await _controller.future;
    buildShowDialog(context);
    setState(() {
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
      );

      setState(() {
        _markers[uData.data['userId']] = marker;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            _cameraPosition,
          ),
        );
      });
    });
    buildHideDialog(context);
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _add();
  }

  @override
  void dispose() {
    super.dispose();
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: const Radius.circular(25.0),
              topRight: const Radius.circular(25.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("text"),
                RaisedButton(
                    child: const Text("add"),
                    onPressed: () {
                      insertData(
                          user: user,
                          data: "this is food available",
                          isAvailable: true,
                          locationData: locationData,
                          userId: user.uid);
                      addMarker("available", locationData);
                    }),
                RaisedButton(
                    child: const Text("delete"),
                    onPressed: () {
                      deleteData(user: user);
                      removeMarker();
                    }),
              ],
            ),
          ),
        );
      },
    );
  }

  buildShowDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  buildHideDialog(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            label: const Text("Add Food"),
            icon: const Icon(Icons.add),
            heroTag: "add",
            onPressed: () {
              _showSheet();
            }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        body: GoogleMap(
          markers: _markers.values.toSet(),
          initialCameraPosition: CameraPosition(
            target: const LatLng(0, 0),
          ),
          mapType: MapType.normal,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
      ),
    );
  }

  void choiceAction(String choice) {
    if (choice == Constants.Refresh) {
      _add();
    } else if (choice == Constants.Subscribe) {
      print('Subscribe');
    } else if (choice == Constants.SignOut) {
      FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => PhoneLogin()),
          (Route<dynamic> route) => false);
    }
  }
}

class Constants {
  static const String Refresh = 'Refresh';
  static const String Subscribe = 'Subscribe';
  static const String SignOut = 'Sign out';

  static const List<String> choices = <String>[Subscribe, Refresh, SignOut];
}
