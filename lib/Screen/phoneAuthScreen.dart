import 'package:doeat/Screen/otpScreen.dart';
import 'package:doeat/Utils/AlertDialog/dialog_button.dart';
import 'package:doeat/Utils/fadePageRoute.dart';
import 'package:flutter/material.dart';

class PhoneAuthScreen extends StatefulWidget {
  PhoneAuthScreen({Key key}) : super(key: key);

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneNumberController = TextEditingController();

  bool isValid = false;

  Future<Null> validate(StateSetter updateState) async {
    if (validateMobile(_phoneNumberController.text.trim())) {
      updateState(() {
        isValid = true;
      });
    } else {
      updateState(() {
        isValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: const DecorationImage(
              image: const AssetImage("assets/images/background.jpg"),
              fit: BoxFit.cover,
              colorFilter:
                  const ColorFilter.mode(Colors.black26, BlendMode.softLight))),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body:
            StatefulBuilder(builder: (BuildContext context, StateSetter state) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    controller: _phoneNumberController,
                    autofocus: true,
                    onChanged: (text) {
                      validate(state);
                    },
                    decoration: InputDecoration(
                      hintText: "Contact Number",
                      errorStyle: const TextStyle(
                          color: Colors.yellow, decorationColor: Colors.yellow),
                      prefix: Container(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          "+91",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    autovalidate: true,
                    autocorrect: false,
                    maxLengthEnforced: true,
                    cursorColor: Colors.green,
                    validator: (value) {
                      return !isValid
                          ? 'Please provide valid phone number'
                          : null;
                    },
                  ),
                ),
                Container(
                  child: Center(
                    child: SizedBox(
                      child: DialogButton(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Text(
                          !isValid ? "ENTER PHONE NUMBER" : "SEND OTP",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          if (isValid) {
                            Navigator.push(
                                context,
                                FadePageRoute(
                                  page: OTPScreen(
                                    mobileNumber:
                                        _phoneNumberController.text.trim(),
                                  ),
                                ));
                          } else {
                            validate(state);
                          }
                        },
                        color: !isValid
                            ? Theme.of(context).primaryColor.withOpacity(0)
                            : Theme.of(context).primaryColor,
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
          );
        }),
      ),
    );
  }
}

bool validateMobile(String value) {
  String pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
  RegExp regExp = new RegExp(pattern);
  if (value.length != 10) {
    return false;
  } else if (!regExp.hasMatch(value)) {
    return false;
  }
  return true;
}
