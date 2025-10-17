import 'package:bneeds_taxi_driver/utils/storage.dart';

import '../models/rideRequest.dart';


class SharedPrefsKeys {
  static const String driverStatus = "driverStatus";
  static const String riderId = "riderId";
  static const String userId = "userId";
  static const String bookingId = "bookingId";
  static const String ongoingTrip = "ongoingTrip";
  static const String driverMobile = "driverMobile";
  static const String driverName = "driverName";
  static const String driverCity = "driverCity";
  static const String isDriverProfileCompleted = "isDriverProfileCompleted";
  static const String driverFcmToken = "driverFcmToken";
  static const String driverUsername = "driverUsername";

}

class SharedPrefsHelper {
  static SharedPreferences? _prefs;

  /// Initialize (call once in main.dart before runApp)
  static Future init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// ---------- SET METHODS ----------
  static Future setDriverStatus(String status) async {
    await _prefs?.setString(SharedPrefsKeys.driverStatus, status);
  }

  static Future setRiderId(String riderId) async {
    await _prefs?.setString(SharedPrefsKeys.riderId, riderId);
  }

  static Future setBookingId(String bookingId) async {
    await _prefs?.setString(SharedPrefsKeys.bookingId, bookingId);
  }

  static Future setUserId(String userId) async {
    await _prefs?.setString(SharedPrefsKeys.userId, userId);
  }

  static Future setOngoingTrip(String tripJson) async {
    await _prefs?.setString(SharedPrefsKeys.ongoingTrip, tripJson);
  }

  static Future setDriverMobile(String mobile) async {
    await _prefs?.setString(SharedPrefsKeys.driverMobile, mobile);
  }

  static Future setDriverName(String name) async {
    await _prefs?.setString(SharedPrefsKeys.driverName, name);
  }

  static Future setDriverCity(String city) async {
    await _prefs?.setString(SharedPrefsKeys.driverCity, city);
  }

  static Future setIsDriverProfileCompleted(bool completed) async {
    await _prefs?.setBool(SharedPrefsKeys.isDriverProfileCompleted, completed);
  }

  static Future setDriverFcmToken(String token) async {
    await _prefs?.setString(SharedPrefsKeys.driverFcmToken, token);
  }

  /// ---------- GET METHODS ----------
  static String getDriverStatus() => _prefs?.getString(SharedPrefsKeys.driverStatus) ?? "OF";

  static String getRiderId() => _prefs?.getString(SharedPrefsKeys.riderId) ?? "";

  static String getBookingId() => _prefs?.getString(SharedPrefsKeys.bookingId) ?? "";

  static String getUserId() => _prefs?.getString(SharedPrefsKeys.userId) ?? "";

  static String? getOngoingTrip() => _prefs?.getString(SharedPrefsKeys.ongoingTrip);

  static String getDriverMobile() => _prefs?.getString(SharedPrefsKeys.driverMobile) ?? "";

  static String getDriverName() => _prefs?.getString(SharedPrefsKeys.driverName) ?? "";

  static String getDriverCity() => _prefs?.getString(SharedPrefsKeys.driverCity) ?? "";

  static bool getIsDriverProfileCompleted() => _prefs?.getBool(SharedPrefsKeys.isDriverProfileCompleted) ?? false;

  static String getDriverFcmToken() => _prefs?.getString(SharedPrefsKeys.driverFcmToken) ?? "";

  /// ---------- CLEAR METHODS ----------
  static Future clearDriverStatus() async {
    await _prefs?.remove(SharedPrefsKeys.driverStatus);
  }

  static Future clearOngoingTrip() async {
    await _prefs?.remove(SharedPrefsKeys.ongoingTrip);
  }

  static Future clearAll() async {
    await _prefs?.clear();
  }

  static bool getDriverProfileCompleted() {
    return _prefs?.getBool("isDriverProfileCompleted") ?? false;
  }
  static Future setDriverUsername(String username) async {
    await _prefs?.setString(SharedPrefsKeys.driverUsername, username);
  }

  static Future setDriverProfileCompleted(bool value) async {
    await _prefs?.setBool(SharedPrefsKeys.isDriverProfileCompleted, value);
  }

  static Future<void> setDriverVehicleTypeId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverVehicleTypeId', value);
  }

  static Future<String?> getDriverVehicleTypeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driverVehicleTypeId');
  }

  static Future<void> setDriverVehicleSubTypeId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverVehicleSubTypeId', value);
  }

  static Future<String?> getDriverVehicleSubTypeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driverVehicleSubTypeId');
  }
// Save trip data
  static Future<void> setTripData(Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tripData', jsonEncode(tripData));
  }

  static Future<void> setPickupTripData(Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tripPickupData', jsonEncode(tripData));
  }

  static Future<Map<String, dynamic>?> getPickupTripData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tripPickupData');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

// Get trip data
  static Future<Map<String, dynamic>?> getTripData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tripData');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

// Clear trip data
  static Future<void> clearTripData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tripData');
  }

  static Future clearUserId() async {
    await _prefs?.remove(SharedPrefsKeys.userId);
  }

  static Future clearBookingId() async {
    await _prefs?.remove(SharedPrefsKeys.bookingId);
  }

  static Future clearRiderId() async {
    await _prefs?.remove(SharedPrefsKeys.riderId);
  }

  /// ---------- NEW DRIVER PROFILE FIELDS ----------

  static Future setDriverAddress1(String value) async =>
      await _prefs?.setString('driverAddress1', value);

  static String getDriverAddress1() =>
      _prefs?.getString('driverAddress1') ?? "";

  static Future setDriverAddress2(String value) async =>
      await _prefs?.setString('driverAddress2', value);

  static String getDriverAddress2() =>
      _prefs?.getString('driverAddress2') ?? "";

  static Future setDriverAddress3(String value) async =>
      await _prefs?.setString('driverAddress3', value);

  static String getDriverAddress3() =>
      _prefs?.getString('driverAddress3') ?? "";

  static Future setDriverGender(String value) async =>
      await _prefs?.setString('driverGender', value);

  static String getDriverGender() =>
      _prefs?.getString('driverGender') ?? "";

  static Future setDriverDob(String value) async =>
      await _prefs?.setString('driverDob', value);

  static String getDriverDob() =>
      _prefs?.getString('driverDob') ?? "";

  static Future setDriverVehicleTypeName(String value) async =>
      await _prefs?.setString('driverVehicleTypeName', value);

  static Future<String?> getDriverVehicleTypeName() async =>
      _prefs?.getString('driverVehicleTypeName');

  static Future setDriverVehicleSubTypeName(String value) async =>
      await _prefs?.setString('driverVehicleSubTypeName', value);

  static Future<String?> getDriverVehicleSubTypeName() async =>
      _prefs?.getString('driverVehicleSubTypeName');

  static Future setDriverVehicleNumber(String value) async =>
      await _prefs?.setString('driverVehicleNumber', value);

  static Future<String?> getDriverVehicleNumber() async =>
      _prefs?.getString('driverVehicleNumber');

  static Future setDriverFcDate(String value) async =>
      await _prefs?.setString('driverFcDate', value);

  static Future<String?> getDriverFcDate() async =>
      _prefs?.getString('driverFcDate');

  static Future setDriverInsDate(String value) async =>
      await _prefs?.setString('driverInsDate', value);

  static Future<String?> getDriverInsDate() async =>
      _prefs?.getString('driverInsDate');

  static Future setDriverLicenseNo(String value) async =>
      await _prefs?.setString('driverLicenseNo', value);

  static Future<String?> getDriverLicenseNo() async =>
      _prefs?.getString('driverLicenseNo');

  static Future setDriverAdhaarNo(String value) async =>
      await _prefs?.setString('driverAdhaarNo', value);

  static Future<String?> getDriverAdhaarNo() async =>
      _prefs?.getString('driverAdhaarNo');
  /// ---------- DRIVER ID ----------
  static Future setDriverId(String value) async =>
      await _prefs?.setString('driverId', value);

  static String getDriverId() =>
      _prefs?.getString('driverId') ?? "";

  static Future<void> setOverlayPosition(int x, int y) async {
    await _prefs?.setInt("overlay_pos_x", x);
    await _prefs?.setInt("overlay_pos_y", y);
  }

  /// Get saved overlay position
  static Map<String, int> getOverlayPosition() {
    final x = _prefs?.getInt("overlay_pos_x") ?? 0;
    final y = _prefs?.getInt("overlay_pos_y") ?? 0;
    return {"x": x, "y": y};
  }

}
