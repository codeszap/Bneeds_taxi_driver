import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../utils/sharedPrefrencesHelper.dart';

class RiderOverlayScreen extends StatefulWidget {
  const RiderOverlayScreen({super.key});

  @override
  State<RiderOverlayScreen> createState() => _RiderOverlayScreenState();
}

class _RiderOverlayScreenState extends State<RiderOverlayScreen> {
  static const String _mainAppPort = 'MainApp';
  SendPort? mainAppPort;

  @override
  void initState() {
    super.initState();

    /// Overlay events listener (if you send back messages)
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map && event.containsKey("x") && event.containsKey("y")) {
        // save to shared prefs
        SharedPrefsHelper.setOverlayPosition(event["x"], event["y"]);
      }
      log("Overlay event: $event");
      if (event is String) {
        if (event == "OpenApp") {
          _openApp();
        }
      }
    });
  }

  /// Sends message back to main app
  void callBackFunction(String tag) {
    mainAppPort ??= IsolateNameServer.lookupPortByName(_mainAppPort);
    mainAppPort?.send(tag);
    log("Sent overlay tag: $tag");
  }

  /// Open main app when logo tapped
  void _openApp() {
    callBackFunction("OpenApp");
   // FlutterOverlayWindow.closeOverlay(); // overlay close
  }

  /// Overlay widget: just a circular logo
  Widget overlay() {
    return GestureDetector(
      onTap: _openApp,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber,
          image: const DecorationImage(
            image: AssetImage("assets/images/logo.png"), // replace with your logo
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // transparent overlay
      body: overlay(),
    );
  }
}
