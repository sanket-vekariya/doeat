import 'package:doeat/faderoure.dart';
import 'package:doeat/otp_screen.dart';
import 'package:flutter/material.dart';

class PhoneLogin extends StatefulWidget {
  PhoneLogin({Key key}) : super(key: key);

  @override
  _PhoneLoginState createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin> {
  final TextEditingController _phoneNumberController = TextEditingController();

  bool isValid = false;

  Future<Null> validate(StateSetter updateState) async {
    print("in validate : ${_phoneNumberController.text.length}");
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
    return Scaffold(
      body: StatefulBuilder(builder: (BuildContext context, StateSetter state) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(40),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _phoneNumberController,
                  autofocus: true,
                  onChanged: (text) {
                    validate(state);
                  },
                  decoration: InputDecoration(
                    hintText: "Contact Number",
                    errorStyle: TextStyle(
                        color: Colors.yellow, decorationColor: Colors.yellow),
                    prefix: Container(
                      padding: EdgeInsets.all(4.0),
                      child: Text(
                        "+91",
                        style: TextStyle(
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
                    child: RaisedButton(
                      color: !isValid
                          ? Theme.of(context).primaryColor.withOpacity(0)
                          : Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50.0)),
                      child: Text(
                        !isValid ? "ENTER PHONE NUMBER" : "SEND OTP",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        if (isValid) {
                          Navigator.push(
                              context,
                              FadeRoute(
                                page: OTPScreen(
                                  mobileNumber:
                                      _phoneNumberController.text.trim(),
                                ),
                              ));
                        } else {
                          validate(state);
                        }
                      },
                      padding: EdgeInsets.all(16.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
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
