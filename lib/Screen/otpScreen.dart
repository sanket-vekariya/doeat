import 'package:doeat/Provider/mapProvider.dart';
import 'package:doeat/Screen/homeScreen.dart';
import 'package:doeat/Utils/AlertDialog/dialog_button.dart';
import 'package:doeat/Utils/fadePageRoute.dart';
import 'package:doeat/Utils/otpInputField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class OTPScreen extends StatefulWidget {
  final String mobileNumber;

  OTPScreen({
    Key key,
    @required this.mobileNumber,
  })  : assert(mobileNumber != null),
        super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  TextEditingController _pinEditingController = TextEditingController();
  PinDecoration _pinDecoration =
      UnderlineDecoration(enteredColor: Colors.green, hintText: '******');

  bool isCodeSent = false;
  String _verificationId;

  @override
  void initState() {
    super.initState();
    _onVerifyCode();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: const BoxDecoration(
          image: const DecorationImage(
              image: const AssetImage("assets/images/background.jpg"),
              fit: BoxFit.cover,
              colorFilter:
                  const ColorFilter.mode(Colors.black26, BlendMode.softLight))),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "OTP Sent To: ${widget.mobileNumber}",
                  style: const TextStyle(
                      fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PinInputTextField(
                pinLength: 6,
                decoration: _pinDecoration,
                controller: _pinEditingController,
                autoFocus: true,
                textInputAction: TextInputAction.done,
                onSubmit: (pin) {
                  if (pin.length == 6) {
                    _onFormSubmitted(pin);
                  } else {
                    showToast("ENTER OTP PROPERLY", Colors.red);
                  }
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  child: DialogButton(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Text(
                      "LOGIN",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      if (_pinEditingController.text.length == 6) {
                        FocusScope.of(context).requestFocus(FocusNode());
                        _onFormSubmitted(_pinEditingController.text.trim());
                      } else {
                        showToast("ENTER OTP PROPERLY", Colors.red);
                      }
                    },
                    gradient: const LinearGradient(
                      colors: [
                        const Color.fromRGBO(116, 116, 191, 1.0),
                        const Color.fromRGBO(52, 138, 199, 1.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showToast(message, Color color) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 2,
        backgroundColor: color,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void _onVerifyCode() async {
    setState(() {
      isCodeSent = true;
      showToast("OTP Sent To: ${widget.mobileNumber}", Colors.green);
    });
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _firebaseAuth
          .signInWithCredential(phoneAuthCredential)
          .then((AuthResult value) {
        if (value.user != null) {
          context.read<MapProvider>().setFireBaseUser(value.user);
          Navigator.pushAndRemoveUntil(
              context,
              FadePageRoute(
                page: HomeScreen(
                  user: value.user,
                ),
              ),
              (Route<dynamic> route) => false);
        } else {
          showToast("Error validating OTP, try again", Colors.red);
        }
      }).catchError((error) {
        showToast("Try again in sometime", Colors.red);
      });
    };
    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      showToast("Invalid Contact number", Colors.red);
      Navigator.pop(context);
      setState(() {
        isCodeSent = false;
      });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
      setState(() {
        _verificationId = verificationId;
      });
    };
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      setState(() {
        _verificationId = verificationId;
      });
    };

    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: "+91${widget.mobileNumber}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  void _onFormSubmitted(String pin) async {
    AuthCredential _authCredential = PhoneAuthProvider.getCredential(
        verificationId: _verificationId, smsCode: pin.trim());

    _firebaseAuth
        .signInWithCredential(_authCredential)
        .then((AuthResult value) {
      if (value.user != null) {
        Navigator.pushAndRemoveUntil(
            context,
            FadePageRoute(
              page: HomeScreen(
                user: value.user,
              ),
            ),
            (Route<dynamic> route) => false);
      } else {
        showToast("Error validating OTP, try again", Colors.red);
      }
    }).catchError((error) {
      showToast("OTP IS WRONG. TRY LATER.", Colors.red);
    });
  }
}
