import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class RideOverlayHelper {
  static bool _isShowingWindow = false;

  /// Overlay show function
  static Future<void> showOverlay(
    BuildContext? context, {
    double? posX,
    double? posY,
  }) async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Bneeds Taxi Driver",
      overlayContent: 'Overlay Enabled',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: 180,
      width: 180,
      startPosition: OverlayPosition(posX ?? 100, posY ?? 200),
    );
  }

  /// Show Full Screen Overlay for Ride Requests
  static Future<void> showFullScreenOverlay() async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: false, // Don't allow dragging full screen
      overlayTitle: "Bneeds Taxi Driver",
      overlayContent: 'New Ride Request',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
      startPosition: const OverlayPosition(0, 0),
    );
  }

  /// Update overlay size
  static Future<void> resizeOverlay(int width, int height) async {
    try {
      await FlutterOverlayWindow.resizeOverlay(width, height, true);
    } catch (e) {
      print("❌ Error resizing overlay in Helper: $e");
    }
  }

  /// Overlay close function
  static Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
