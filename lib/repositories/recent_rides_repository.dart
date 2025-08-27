import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recent_ride_model.dart';

class RecentRidesRepository {
  final String apiUrl = 'https://example.com/api/recentRides';

  Future<List<RecentRide>> fetchRecentRides(String userId) async {
    final url = Uri.parse('$apiUrl?userId=$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => RecentRide.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recent rides');
    }
  }
}
