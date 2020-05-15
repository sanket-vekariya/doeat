import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future insertData(
    {bool isAvailable,
    FirebaseUser user,
    String userName,
    dynamic locationData,
    String data,
    String addressDetails,
    String foodCount}) async {
  var documentReference =
      Firestore.instance.collection('data').document(user.uid);
  Firestore.instance.runTransaction((transaction) async {
    await transaction.set(
      documentReference,
      {
        'userId': user.uid,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'data': data,
        'addressDetails': addressDetails,
        'foodCount': foodCount,
        'uploadTime': DateTime.now().millisecondsSinceEpoch.toString(),
        'contactNumber': user.phoneNumber,
        'userName': userName,
        'isAvailable': isAvailable
      },
    );
  });
  addInSharedPreference(
      isAvailable: isAvailable,
      user: user,
      userName: userName,
      locationData: locationData,
      data: data,
      addressDetails: addressDetails,
      foodCount: foodCount);
}

addInSharedPreference(
    {bool isAvailable,
    FirebaseUser user,
    String userName,
    dynamic locationData,
    String data,
    String addressDetails,
    String foodCount}) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.setString('userId', user.uid);
  preferences.setDouble('latitude', locationData.latitude);
  preferences.setDouble('longitude', locationData.longitude);
  preferences.setString('data', data);
  preferences.setString('addressDetails', addressDetails);
  preferences.setString('foodCount', foodCount);
  preferences.setString(
      'uploadTime', DateTime.now().millisecondsSinceEpoch.toString());
  preferences.setString('contactNumber', user.phoneNumber);
  preferences.setString('userName', userName);
  preferences.setBool('isAvailable', isAvailable);
}

Future<List<DocumentSnapshot>> getData() async {
  final QuerySnapshot result =
      await Firestore.instance.collection('data').getDocuments();
  final List<DocumentSnapshot> documents = result.documents;
  return documents ?? [];
}

Future deleteData({FirebaseUser user}) async {
  var documentReference =
      Firestore.instance.collection('data').document(user.uid);
  Firestore.instance.runTransaction((transaction) async {
    await transaction.delete(documentReference);
  });
  // delete data, food count from shared preference
  SharedPreferences preferences = await SharedPreferences.getInstance();
  preferences.setString('data', '');
  preferences.setString('foodCount', '');
}
