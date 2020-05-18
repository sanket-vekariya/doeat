import 'dart:async';

import 'package:doeat/Screen/homeScreen.dart';
import 'package:doeat/Screen/phoneAuthScreen.dart';
import 'package:doeat/Utils/fadePageRoute.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
            FadePageRoute(
              page: HomeScreen(
                user: currentUser,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            FadePageRoute(page: PhoneAuthScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            image: const DecorationImage(
                image: const AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                    Colors.black26, BlendMode.softLight))),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            new Column(
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  color: Colors.white,
                  width: animation.value * 100,
                  height: animation.value * 100,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
