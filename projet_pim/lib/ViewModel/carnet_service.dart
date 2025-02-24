import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/carnet.dart';

class CarnetService {
  final String baseUrl = 'http://localhost:3000/carnets';

  Future<List<dynamic>> getAllCarnets() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/carnets'));

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

  /* Future<void> unlockPlace(
      String carnetId, int placeIndex, String userId) async {
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
  }*/

  Future<List<Carnet>> getUserCarnet(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // Vérifier si la réponse contient des carnets
        if (data == null || (data is List && data.isEmpty)) {
          // Si la liste est vide ou si les carnets n'existent pas, retourner une liste vide
          return [];
        }

        // Sinon, créer et retourner les carnets
        return [Carnet.fromJson(data)];
      } else {
        // Afficher un message dans la console mais ne pas lancer une exception
        print('Failed to load carnet: ${response.body}');
        return [];
      }
    } catch (e) {
      // Afficher l'erreur dans la console mais ne pas lancer d'exception
      print("Error in getUserCarnet: $e");
      return [];
    }
  }

  Future<void> unlockPlace(String userId, String placeId) async {
    try {
      final url =
          Uri.parse('http://localhost:3000/users/$userId/unlock/$placeId');

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
        Uri.parse('http://localhost:3000/users/$userId/unlocked-places'),
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

  Future<List<Map<String, dynamic>>> getAllPlacesFromCarnets() async {
    try {
      List<dynamic> carnets = await getAllCarnets();

      // Extraire toutes les places des carnets
      List<Map<String, dynamic>> allPlaces = [];
      for (var carnet in carnets) {
        if (carnet['places'] != null) {
          allPlaces.addAll(List<Map<String, dynamic>>.from(carnet['places']));
        }
      }
      return allPlaces;
    } catch (e) {
      print("Error in getAllPlacesFromCarnets: $e");
      throw Exception('Network error: Unable to fetch all places.');
    }
  }
}
