import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';


class RideOverlayHelper {
  static bool _isShowingWindow = false;

  /// Overlay show function
  static Future<void> showOverlay(BuildContext context, {double? posX, double? posY}) async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Ram Meter Driver",
      overlayContent: 'Overlay Enabled',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none, // auto அல்ல
      height: (MediaQuery.of(context).size.height * 0.6).toInt(),
      width: 200,
      startPosition: OverlayPosition(posX ?? 0, posY ?? 0),
    );
  }


  /// Overlay close function
  static Future<void> closeOverlay() async {
//    if (!_isShowingWindow) return;
    await FlutterOverlayWindow.closeOverlay();
  //  _isShowingWindow = false;
  }
}
