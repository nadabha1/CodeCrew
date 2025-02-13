import 'dart:convert';
import 'package:http/http.dart' as http;

class CarnetService {
  final String baseUrl = 'http://10.0.2.2:3000/carnets';

  Future<List<dynamic>> getAllCarnets() async {
  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/carnets'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load carnets: ${response.body}');
    }
  } catch (e) {
    print("Error in getAllCarnets: $e"); // ✅ Debugging
    throw Exception('Network error: Unable to fetch carnets.');
  }
}


  Future<void> createCarnet(String title, String description, List places) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'places': places,
        'owner': 'user_id'
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create carnet');
    }
  }
    Future<void> unlockPlace(String carnetId, int placeIndex, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$carnetId/unlock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'placeIndex': placeIndex,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unlock place');
    }
  }
}
