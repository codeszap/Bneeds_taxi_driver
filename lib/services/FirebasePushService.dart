import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:bneeds_taxi_driver/utils/storage.dart';

class FirebasePushService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static const _projectId = 'bneeds-taxi-customer-b14a9';

  static Future<String> _getAccessToken() async {
    // Load your service account JSON
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(
      jsonDecode(await rootBundle.loadString(Strings.serviceAccount)),
    );

    final client = await auth.clientViaServiceAccount(accountCredentials, _scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();
    return accessToken;
  }

  static Future<bool> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final token = await _getAccessToken(); 

    final payload = {
      "message": {
        "token": fcmToken,
        "notification": {"title": title, "body": body},
        "data": data ?? {},
      }
    };

    final response = await http.post(
      Uri.parse("https://fcm.googleapis.com/v1/projects/$_projectId/messages:send"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent successfully to $fcmToken");
      return true;
    } else {
      print("❌ Failed: ${response.statusCode} ${response.body}");
      return false;
    }
  }
}
