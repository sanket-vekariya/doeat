import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';

Future insertData(
    {bool isAvailable,
    String userId,
    FirebaseUser user,
    LocationData locationData,
    String data}) async {
  var documentReference =
      Firestore.instance.collection('data').document(userId);
  Firestore.instance.runTransaction((transaction) async {
    await transaction.set(
      documentReference,
      {
        'userId': userId,
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'data': data,
        'uploadTime': DateTime.now().millisecondsSinceEpoch.toString(),
        'contactNumber': user.phoneNumber,
        'userName': user.displayName,
        'isAvailable': isAvailable
      },
    );
  });
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
}
