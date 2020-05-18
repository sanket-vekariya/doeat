import 'package:flutter/material.dart';

class PinDataModel {
  String userId;
  String data;
  String foodCount;
  String addressDetails;
  String uploadTime;
  String contactNumber;
  String userName;
  bool isAvailable;

  PinDataModel({
    @required this.userId,
    @required this.data,
    @required this.foodCount,
    @required this.addressDetails,
    @required this.uploadTime,
    @required this.contactNumber,
    @required this.userName,
    @required this.isAvailable,
  });
}
