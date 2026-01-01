import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';

class RemoteConfigHelper {
  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults({
        "latest_version": "1.0.0",
        "force_update": false,
      });

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint("❌ Remote Config Init Error: $e");
    }
  }

  static String get latestVersion => _remoteConfig.getString("latest_version");
  static bool get isForceUpdate => _remoteConfig.getBool("force_update");

  static Future<bool> shouldUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    return _isNewerVersion(latestVersion, currentVersion);
  }

  static bool _isNewerVersion(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > currentPart) return true;
      if (latestParts[i] < currentPart) return false;
    }
    return false;
  }
}
