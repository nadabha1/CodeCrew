import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';
import '../Model/trip.dart';

class TripService {
  Future<List<Trip>> getAcceptedTrips(String userId) async {
    final response = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/trip/accepted/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Trip.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch accepted trips');
    }
  }
}
