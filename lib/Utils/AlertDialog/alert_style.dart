import 'package:doeat/Utils/AlertDialog/constants.dart';
import 'package:flutter/material.dart';

class AlertStyle {
  final AnimationType animationType;
  final Duration animationDuration;
  final ShapeBorder alertBorder;
  final bool isCloseButton;
  final bool isOverlayTapDismiss;
  final Color backgroundColor;
  final Color overlayColor;
  final TextStyle titleStyle;
  final TextStyle descStyle;
  final EdgeInsets buttonAreaPadding;
  final BoxConstraints constraints;

  const AlertStyle(
      {this.animationType = AnimationType.fromBottom,
      this.animationDuration = const Duration(milliseconds: 200),
      this.alertBorder,
      this.isCloseButton = true,
      this.isOverlayTapDismiss = true,
      this.backgroundColor,
      this.overlayColor = Colors.black87,
      this.titleStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.normal,
          fontSize: 22.0),
      this.descStyle = const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
          fontSize: 18.0),
      this.buttonAreaPadding = const EdgeInsets.all(20.0),
      this.constraints});
}
