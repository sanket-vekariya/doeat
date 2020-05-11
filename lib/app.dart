import 'dart:async';

import 'package:doeat/faderoure.dart';
import 'package:doeat/home.dart';
import 'package:doeat/phone_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  var _visible = true;
  final int splashDuration = 2;

  AnimationController animationController;
  Animation<double> animation;

  bool isLoading = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    animationController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 2),
    );
    animation =
        new CurvedAnimation(parent: animationController, curve: Curves.easeOut);

    animation.addListener(() {
      if (mounted) {
        this.setState(() {});
      }
    });
    animationController.forward();
    if (mounted) {
      setState(() {
        _visible = !_visible;
      });
    }
    countDownTime();
  }

  @override
  dispose() {
    animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  countDownTime() async {
    FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    return Timer(
      Duration(seconds: 3),
      () async {
        if (currentUser != null) {
          Navigator.pushReplacement(
            context,
            FadeRoute(
              page: HomePage(
                user: currentUser,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            FadeRoute(page: PhoneLogin()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            new Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 30.0),
                  child: Image.asset(
                    'assets/images/glogo.png',
                    height: 25.0,
                    fit: BoxFit.scaleDown,
                  ),
                )
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/glogo.png',
                  width: animation.value * 250,
                  height: animation.value * 250,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
