import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/carnet.dart';

class CarnetService {
  //final String baseUrl = 'http://localhost:3000/carnets';
final String baseUrl =
      "http://10.0.2.2:3000/carnets"; 
  Future<List<dynamic>> getAllCarnets() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/carnets'));

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

  Future<void> createCarnet(
      String title, String description, List places) async {
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

Future<dynamic> getUserCarnet(String userId) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/user/$userId"),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      var data = json.decode(response.body);

      // 🔥 Fix: Ensure always returning a List
      if (data is List) {
        return data; // Return as a list
      } else if (data is Map<String, dynamic>) {
        return [data]; // Convert single object to a list
      } else {
        throw Exception("Unexpected API response format: $data");
      }
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  } catch (e) {
    return {'error': 'Failed to fetch user carnet: $e'};
  }
}


  Future<void> unlockPlace(String userId, String placeId) async {
    try {
      final url =
          Uri.parse('http://10.0.2.2:3000/users/$userId/unlock/$placeId');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unlock place: ${response.body}');
      }
    } catch (e) {
      print("Error in unlockPlace: $e");
      throw Exception('Error unlocking place');
    }
  }

  Future<List<String>> getUnlockedPlaces(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/users/$userId/unlocked-places'),
        headers: {'Content-Type': 'application/json'},
      );
      print("Réponse brute : ${response.body}");

      if (response.statusCode == 200) {
        final places = List<String>.from(jsonDecode(response.body));
        print("Places décodées : $places");
        return places;
      } else {
        throw Exception('Échec de la récupération : ${response.body}');
      }
    } catch (e) {
      print("Erreur dans getUnlockedPlaces: $e");
      throw Exception('Erreur réseau : impossible de récupérer les places.');
    }
  }
}
